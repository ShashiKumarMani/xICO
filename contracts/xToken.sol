
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract XToken is ERC20, Ownable {

    uint256 private immutable _cap;

    constructor(string memory name_, string memory symbol_, uint256 cap_) 
        ERC20(name_, symbol_)
    {
        require(cap_ > 0, "ERC20: cap is 0");
        _cap = cap_;
    }
 
    function cap() public view returns (uint256) {
        return _cap;
    }

    function _mint(address account, uint256 amount) internal override onlyOwner {
        require(ERC20.totalSupply() <= cap(), "ERC20Capped: cap exceeded");
        ERC20._mint(account, amount);
    }
}
