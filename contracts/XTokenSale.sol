// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @dev XTokenSale is the contract used to manage the Initial Coin Offering of the xToken
 * Investors can make a investment and obtain xTokens using the buyTokens functions
 *
*/
contract XTokenSale is Pausable, AccessControl, Ownable {

    using SafeERC20 for IERC20;
    using SafeCast for int256;

    /**
     * @dev Keccak256 Hash of the variable names
     */
    bytes32 public constant PRIVATE_SALE = 0x3571fea4df417b4342013dd7494740b7b31b6312391409c91e671223e0d93261;
    bytes32 public constant PRE_SALE = 0x07963c72e9d9113b8188da2def2bf51c73a463aac395358e61b4ace0a9e24621;
    bytes32 public constant CROWD_SALE = 0xefdbaf9df092bcd35a7bf6113300a9cc5d21b347bdb6bd325fcf68d8b4138d76;

    /**
     * @dev enum used to denote current sale round of the ICO
     */
    enum XTokenSaleRound { PrivateSale, PreSale, CrowdSale }
    
    uint256 public bonus;
    uint256 public ethToUsd;
    uint256 private _rate;
    address payable private _wallet;
    uint256 private _weiRaised;
    uint256 private _openingTime;
    uint256 private _closingTime;
    uint256 private _cap;

    /**
     * @dev Tokens of the ICO
     */
    IERC20 private _token;

    /**
     * @dev Chainlink pricefeed contract
     */
    AggregatorV3Interface internal pricefeed;

    /**
     * @dev Sale round of the ICO
     */
    XTokenSaleRound round = XTokenSaleRound.PrivateSale;

    /**
     * @param recipient the recipient of the token being purchased
     * @param tokens number of tokens being purchased
     * @param round current round of ICO
     */
    event BuyTokens(address recipient, uint256 tokens, XTokenSaleRound round);

    /**
     * @param round current round of ICO
     * @param bonus bonus value based on the current round of the ICO
     */
    event UpdateRoundAndBonus(XTokenSaleRound round, uint256 bonus);

    /**
     * @param rate_ rate of token exchange Number of token per *dollars*
     * @param wallet_ address to send wei
     * @param token_ token of the ICO
     * @param cap_ Maximum tokens in the ICO
     * @param openingTime_ opening time of the ICO
     * @param closingTime_ ending time of the ICO
     * @param pricefeed_ address of the chainlink ETH/USD Aggregator contract
     */
    constructor (
        uint256 rate_, 
        address payable wallet_, 
        IERC20 token_, 
        uint256 cap_, 
        uint256 openingTime_, 
        uint256 closingTime_ ,
        address pricefeed_
    ) {
        _rate = rate_;
        _wallet = wallet_;
        _token = token_;

        pricefeed = AggregatorV3Interface(pricefeed_);
        
        require(cap_ > 0);
        _cap = cap_;

        require(openingTime_ >= block.timestamp, "XTokenSale: opening time is in the past");
        require(closingTime_ > openingTime_, "XTokenSale: closing time is lesser then opening time");
        _openingTime = openingTime_;
        _closingTime = closingTime_;
    }

    /**
     * @dev Allows execution only between opening and closing time
     */
    modifier onlyWhileOpen {
        require(isOpen(), "XTokenSale: not open");
        _;
    }

    /**
     * @return boolean value based on the open or close of the ICO
     */
    function isOpen() public view returns (bool) {
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @return the cap limit of the ICO
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev main function used by investors to buy tokens
     * @param recipient the recipient of the token being purchased
     */
    function buyTokens(address recipient) 
        external 
        payable 
        onlyWhileOpen 
        whenNotPaused 
    {

        validate(recipient, msg.value);

        uint usd = (msg.value / 1e18) * ethToUsd;

        require(usd >= 500, "XTokenSale: Minimum value must be 500 Dollars");

        uint256 tokens = usd * _rate;
        tokens += tokens * bonus;

        XTokenSaleRound rnd = round;

        if(rnd == XTokenSaleRound.PrivateSale) {

            require(hasRole(PRIVATE_SALE, recipient), "XTokenSale: User is not on PrivateSale Whitelist");
        } else if(rnd == XTokenSaleRound.PreSale) {

            require(hasRole(PRE_SALE, recipient), "XTokenSale: User is not on PreSale Whitelist");
        } else {

            require(hasRole(CROWD_SALE, recipient), "XTokenSale: User is not on CrowdSales Whitelist");
        }
        
        _token.safeTransfer(recipient, tokens);

        _weiRaised += msg.value;

        // Forward collected wei
        _forwardFunds();

        emit BuyTokens(recipient, tokens, rnd);
    }

    /**
     * @dev function to update round and bonus of the ICO
     * Is accessible only to the owner by onlyOwner modifier
     */
    function updateRoundAndBonus() external onlyOwner {
        
        uint256 temp = 100;
        uint256 openTime = _openingTime;

        if(block.timestamp <= openTime + 15 days) {
            bonus = _rate * (25 / temp);
            round = XTokenSaleRound.PrivateSale;

        } else if(block.timestamp <= openTime + 30 days) {
            bonus = _rate * (20 / temp);
            round = XTokenSaleRound.PreSale;

        } else if(block.timestamp <= openTime + 37 days) {
            bonus = _rate * (15 / temp); 
            round = XTokenSaleRound.CrowdSale;
        
        } else if(block.timestamp <= openTime + 44 days) {
            bonus = _rate * (10 / temp); 
        
        } else if (block.timestamp <= openTime + 53 days) {
            bonus = _rate * (5 / temp); 
        
        }

        emit UpdateRoundAndBonus(round, bonus);
    }

    /**
     * @dev function used to get the oracle price data 
     * Executed once a week
     */
    function getOracleData() external onlyOwner  {

        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = pricefeed.latestRoundData();

        ethToUsd = answer.toUint256() / 1e8;
    }

    /**
     * @dev function used to forward funds to the wallet 
     * Executes on every buyTokens function call by an investor
     */
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }

    /**
     * @dev function used to validate beneficiary, wei amount and cap amount
     */
    function validate(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "XTokenSale: beneficiary is zero address");
        require(weiAmount != 0, "XTokenSale: weiAmount is 0");
        require(_weiRaised + weiAmount <= _cap, "XTokenSale: cap exceeded");
    }
}