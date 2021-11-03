# xToken ICO

A simple ICO smart contracts which allows investors to invest ETH and obtain xTokens.

## Contracts

- XToken.sol

    ERC20 token contract

- XTokenSale.sol

    The main ICO contract

## XToken

- Total number of tokens 
        
    50_000_000_000

The XToken contract is first deployed by passing in the name, symbol and cap value 50_000_000_000

### Token Division

    Reserve Wallet: 30% (15 billion)

    Interest Payout Wallet: 20% (10 billion)

    Team Members HR Wallet: 10% (5 billion)

    Company General Fund Wallet: 13% (6.5 billion)

    Bounties/Airdrops Wallet: 2% (1 billion)

    Token Sale Wallet: 25% (12.5 billion)

### Mint

The mint function can be called to mint tokens to various wallets specified above, till the max cap amount.

## XTokenSale

Deploy the XTokenSale contract by passing in initial values

    rate_ - Number of token to issue per wei( in this case dollars) : 1000
    wallet_ - Address of the wallet that recieves the invested eth
    token - The ERC20 token address
    cap_ - The target Eth to be collected
    openingTime - The opening time of the ICO
    closingTime - The closing time of the ICO
    pricefeed - The chainlink ETH/USD price oracle contract address

The token inherits AccessControl, Pauable and Ownable contracts

AccessControl is used to create a set of user role according to the stages of sale Private, Pre, and Crowd sale.

Create roles for users using the `grantRole()` function by passing in the `keccak256` hash of the string and the recipient account address.

Pausable is used to pause and unpause the contract

Ownable is used to set the owner of the contract, and provides a modifier onlyOwner that is applied to functions to prevent it from being used by others.


### getOracleData 
```
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = pricefeed.latestRoundData();
```
Function used to get the ETH/USD price from the chainlink AggregatorV3Interface contract.
This function has to called manually by the owner every week to set the new value.

### buyTokens 

Function is used to buy tokens by passing in the token recipient address.

Function has modifier `onlyWhileOpen` that allows execution between the opening and closing time, `whenNotPaused` allows execution when the contract is not paused.

```
 validate(recipient, msg.value);
```
The function calls validate function to validate the address and wei passed and checks if the maximum cap is reached or not

```
 uint usd = (msg.value / 1e18) * ethToUsd;
 require(usd >= 500, "XTokenSale: Minimum value must be 500 Dollars");
 uint256 tokens = usd * _rate;
 tokens += tokens * bonus;
```
The wei amount is converted to eth and multiplied with price oracle data to get the final USD value.
The USD value is checked to be greater or equal to 500 USD.
USD value is converted to number of tokens and the bonus is added to the total

```
XTokenSaleRound rnd = round;

if(rnd == XTokenSaleRound.PrivateSale) {

    require(hasRole(PRIVATE_SALE, recipient), "XTokenSale: User is not on PrivateSale Whitelist");
} else if(rnd == XTokenSaleRound.PreSale) {

    require(hasRole(PRE_SALE, recipient), "XTokenSale: User is not on PreSale Whitelist");
} else {

    require(hasRole(CROWD_SALE, recipient), "XTokenSale: User is not on CrowdSales Whitelist");
}
```
The recipient is checked in the whitelist of roles

```
_token.safeTransfer(recipient, tokens);
```
The tokens are immediately transffered to the investors.

```
_forwardFunds();
```

The eth recieved from the investor is transferred to owner specified wallet address at the end of call, eth is **not stored** in the contract.


### updateRoundAndBonus
```
Timeline : 

Private sale Duration : 15 days
PreSale Duration : 15 Days
CrowdSale : 30 Days

Bonus Structure : 

Private Sale 25%
Pre-Sale     20%
CrowdSale 
             15% 1st week 
             10% 2nd week 
             5%  3rd week 
             0%  4th week
```
Function used to update the round and calculate the bonus rate for the round
This function has to be called by the owner manually.

## Fallback and Receive

The fallback and receive functions reverts on execution.
This prevents eth being locked as there is no mechanism to transfer eth out of the contract except `buyTokens`.

## Deployment

Add .env file with environment variables of apikey and private key of the address
Update config file network parameters to point to the mainnet or testnet
Run the script file

```
npx hardhat run script/sample-script.js --network <network name>
```