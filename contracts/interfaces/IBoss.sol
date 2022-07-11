
pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./ICommonStructs.sol";


interface IBoss is ICommonStructs {

	function brain() external returns (address);

	function id() external returns (uint);

    function getConfig() external returns (BossConfig memory);
	
	function getSummonSet(uint i) external returns (SummonSet memory);

	function getPowerupSet(uint i) external returns (PowerupSet memory);

	function withdrawERC20s(ERC20Deposit[] calldata deps, address receiver) external;

	function withdrawNFT(NFTDeposit calldata deps, address receiver) external;

	function withdrawETH(uint amount, address payable receiver) external;

	// TODO: include the other fcns in Brain, also check is the size of MetaBrain changes after
}