
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract XTokenSale is Pausable, AccessControl, Ownable {

    using SafeERC20 for IERC20;
    using SafeCast for int256;

    bytes32 public constant PRIVATE_SALE = keccak256("PRIVATE");
    bytes32 public constant PRE_SALE = keccak256("PRESALE");
    bytes32 public constant CROWD_SALE = keccak256("CROWDSALE");

    enum XTokenSaleRound { PrivateSale, PreSale, CrowdSale }
    
    uint256 public bonus;
    uint256 public ethToUsd;
    uint256 private _rate;
    address payable private _wallet;
    uint256 private _weiRaised;
    uint256 private _openingTime;
    uint256 private _closingTime;
    uint256 private _cap;

    IERC20 private _token;
    AggregatorV3Interface internal pricefeed;
    XTokenSaleRound round = XTokenSaleRound.PrivateSale;

    event BuyTokens(address recipient, uint256 tokens, XTokenSaleRound round);
    event UpdateRoundAndBonus(XTokenSaleRound round, uint256 bonus);

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

    modifier onlyWhileOpen {
        require(isOpen(), "XTokenSale: not open");
        _;
    }

    function isOpen() public view returns (bool) {
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    // Whitelist investors using AccessControl
    function buyTokensRestricted(address recipient) 
        external 
        payable 
        onlyWhileOpen 
        whenNotPaused 
    {

        validate(recipient, msg.value);

        uint usd = (msg.value / 1e18) * ethToUsd;

        require(usd > 500, "buyTokens: Minimum value must be 500");

        uint256 tokens = usd * _rate;
        tokens += tokens * bonus;

        if(round == XTokenSaleRound.PrivateSale) {

            require(hasRole(PRIVATE_SALE, recipient), "buyTokensRestricted: User is not on PrivateSale Whitelist");
            _token.safeTransfer(recipient, tokens);
        } else if(round == XTokenSaleRound.PreSale) {

            require(hasRole(PRE_SALE, recipient), "buyTokensRestricted: User is not on PreSale Whitelist");
            _token.safeTransfer(recipient, tokens);
        } else {

            require(hasRole(CROWD_SALE, recipient), "buyTokensRestricted: User is not on CrowdSales Whitelist");
            _token.safeTransfer(recipient, tokens);
        }

        _weiRaised += msg.value;

        // Forward collected wei
        _forwardFunds();

        emit BuyTokens(recipient, tokens, round);
    }

    // Round changing and bonus
    function  updateRoundAndBonus() external onlyOwner {
        
        uint256 temp = 100;

        if(block.timestamp <= _openingTime + 15 days) {
            bonus = _rate * (25 / temp);
            round = XTokenSaleRound.PrivateSale;

        } else if(block.timestamp <= _openingTime + 30 days) {
            bonus = _rate * (20 / temp);
            round = XTokenSaleRound.PreSale;

        } else if(block.timestamp <= _openingTime + 37 days) {
            bonus = _rate * (15 / temp); 
            round = XTokenSaleRound.CrowdSale;
        
        } else if(block.timestamp <= _openingTime + 44 days) {
            bonus = _rate * (10 / temp); 
        
        } else if (block.timestamp <= _openingTime + 53 days) {
            bonus = _rate * (5 / temp); 
        
        }

        emit UpdateRoundAndBonus(round, bonus);
    }

    // Chainlink called once a week
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

    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }

    function validate(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "XTokenSale: beneficiary is zero address");
        require(weiAmount != 0, "XTokenSale: weiAmount is 0");
        require(_weiRaised + weiAmount <= _cap, "XTokenSale: cap exceeded");
    }
}