pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "./ICommonStructs.sol";
import "./IBrain.sol";


interface IMetaBrain is ICommonStructs, IBrain {
    struct SetPath {
        uint setIdx;
        uint tokenIdIdx;
        uint tokenId;
    }

    struct TeamSummon {
        uint32 time;
        bytes password;
    }

    function fightBoss(
        uint playerId,
        uint anftTokenId,
        SetPath[] calldata powerupPaths,
        ERC20Deposit[] calldata erc20Deps,
        NFTDeposit[] calldata nftDeps
    ) external returns (bool);
}