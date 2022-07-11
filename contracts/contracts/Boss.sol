
pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "../interfaces/IBoss.sol";


contract Boss is IBoss, IERC721ReceiverUpgradeable, Initializable, OwnableUpgradeable {
    function initialize(uint id_, address brain_, BossConfig memory config_) public virtual initializer {
        __Boss_init(id_, brain_, config_);
    }


	using SafeERC20Upgradeable for IERC20Upgradeable;

	event SummonSetsSet(uint indexed anftId, SummonSet[] newSummonSets);
	event PowerupSetsSet(uint indexed anftId, PowerupSet[] newPowerupSets);

	address public override brain;
	uint public override id;
    /// @dev    Annoyingly, can't have this be public because it's of type storage,
    ///         which can't be used in IBoss
	BossConfig private _config;
    SummonSet[] private _summonSets;
    PowerupSet[] private _powerupSets;
	

    function __Boss_init(uint id_, address brain_, BossConfig memory config_) internal onlyInitializing {
        __Ownable_init_unchained();
        __Boss_init_unchained(id_, brain_, config_);
    }

    function __Boss_init_unchained(uint id_, address brain_, BossConfig memory config_) internal onlyInitializing {
		id = id_;
		brain = brain_;
		_config = config_;
    }


	//////////////////////////////////////////////////////////////
    //                                                          //
    //                   Getters and Setters                    //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function getConfig() external override returns (BossConfig memory) {
        return _config;
    }

    function setConfig(BossConfig memory newConfig) external onlyOwner {
        _config = newConfig;
    }

    function getSummonSet(uint i) external override returns (SummonSet memory) {
        return _summonSets[i];
    }

    function getPowerupSet(uint i) external override returns (PowerupSet memory) {
        return _powerupSets[i];
    }


	//////////////////////////////////////////////////////////////
    //                                                          //
    //                       Withdrawals                        //
    //                                                          //
    //////////////////////////////////////////////////////////////

	function withdrawERC20s(ERC20Deposit[] calldata deps, address receiver) public override onlyBrain {
		for (uint i; i < deps.length; i++) {
			deps[i].token.safeTransfer(receiver, deps[i].amount);
		}
	}

	function withdrawNFT(NFTDeposit calldata dep, address receiver) public override onlyBrain {
        dep.nft.safeTransferFrom(address(this), receiver, dep.id);
	}

	function withdrawETH(uint amount, address payable receiver) public override onlyBrain {
		receiver.transfer(amount);
	}


	//////////////////////////////////////////////////////////////
    //                                                          //
    //                       Summon Sets                        //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function setSummonSets(
        SummonSet[] memory newSummonSets
    ) external onlyOwner {
        uint initialLength = _summonSets.length;

        for (uint i; i < newSummonSets.length; i++) {
            if (i < initialLength) {
                _summonSets[i] = newSummonSets[i];
            } else {
                _summonSets.push(newSummonSets[i]);
            }
        }

        if (newSummonSets.length < initialLength) {
            for (uint i = newSummonSets.length; i < initialLength; i++) {
                _summonSets.pop();
            }
        }

        emit SummonSetsSet(id, newSummonSets);
    }

    function getSummonItems() public view returns (SummonSet[] memory) {
        return _summonSets;
    }

    function getSummonItem(uint i) public view returns (SummonSet memory) {
        return _summonSets[i];
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                       Powerup Sets                       //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function setPowerupSets(
        PowerupSet[] memory newPowerupSets
    ) external onlyOwner {
        uint initialLength = _powerupSets.length;

        for (uint i; i < newPowerupSets.length; i++) {
            if (i < initialLength) {
                _powerupSets[i] = newPowerupSets[i];
            } else {
                _powerupSets.push(newPowerupSets[i]);
            }
        }

        if (newPowerupSets.length < initialLength) {
            for (uint i = newPowerupSets.length; i < initialLength; i++) {
                _powerupSets.pop();
            }
        }

        emit PowerupSetsSet(id, newPowerupSets);
    }

    function getPowerupItems() public view returns (PowerupSet[] memory) {
        return _powerupSets;
    }

    function getPowerupItem(uint i) public view returns (PowerupSet memory) {
        return _powerupSets[i];
    }


	//////////////////////////////////////////////////////////////
    //                                                          //
    //                       Miscellaneous                      //
    //                                                          //
    //////////////////////////////////////////////////////////////

	function onERC721Received(
		address operator,
		address from,
		uint tokenId,
		bytes calldata data
	) external override returns (bytes4) {
		return this.onERC721Received.selector;
	}

	modifier onlyBrain() {
		require(msg.sender == brain, "Boss: you are not the MetaBrain");
		_;
	}

	receive() external payable {}

}