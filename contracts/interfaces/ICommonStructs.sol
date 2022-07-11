pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";


interface ICommonStructs {

    struct SummonSet {
        IERC721Upgradeable nft;
        bool spend;
        uint[] tokenIds;
    }

    struct PowerupSet {
        IERC721Upgradeable nft;
        bool spend;
        uint64 effect;
        uint[] tokenIds;
    }

    struct BossConfig {
        uint difficulty;
        uint maxPowerups;
        address[] ownerPools;
    }

    struct ERC20Deposit {
        IERC20Upgradeable token;
        uint amount;
    }

    struct NFTDeposit {
        IERC721Upgradeable nft;
        uint id;
    }
}
