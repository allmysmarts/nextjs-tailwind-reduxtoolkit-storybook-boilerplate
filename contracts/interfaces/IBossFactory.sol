
pragma solidity ^0.8.0;


import "./ICommonStructs.sol";


interface IBossFactory is ICommonStructs {
	function newBoss(uint id, address brain, BossConfig calldata config, address admin, address owner) external returns (address payable);
}