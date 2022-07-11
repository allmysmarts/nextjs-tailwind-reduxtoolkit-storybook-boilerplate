pragma solidity ^0.8.0;


import "../../interfaces/IMetaBrain.sol";


contract MockMetaBrainWrapper {

    IMetaBrain public immutable metaBrain;
    
    constructor(IMetaBrain metaBrain_) {
        metaBrain = metaBrain_;
    }

    function fightBoss(
        uint playerId,
        uint anftTokenId,
        IMetaBrain.SetPath[] calldata powerupPaths,
        IMetaBrain.ERC20Deposit[] calldata erc20Deps,
        IMetaBrain.NFTDeposit[] calldata nftDeps
    ) external returns (bool) {
        metaBrain.fightBoss(playerId, anftTokenId, powerupPaths, erc20Deps, nftDeps);
    }

    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC721Received.selector;
    }
}