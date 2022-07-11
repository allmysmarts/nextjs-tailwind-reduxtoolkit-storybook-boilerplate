pragma solidity ^0.8.0;


import "./autonomy/contracts/AUTO.sol";


contract MockERC777 is AUTO {

    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators,
        address receiver,
        uint256 mintAmount
    ) AUTO(name, symbol, defaultOperators, receiver, mintAmount) { }

}