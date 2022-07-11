pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract MockERC20BurnOnTransfer is ERC20 {
    
    constructor(
        string memory name_,
        string memory symbol_,
        uint mintAmount_
    ) ERC20(name_, symbol_) {
        _mint(msg.sender, mintAmount_);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        bool result = super.transferFrom(sender, recipient, amount);
        _burn(recipient, 1);
        return result;
    }
}