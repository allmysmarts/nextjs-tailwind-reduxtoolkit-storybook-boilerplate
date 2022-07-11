pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/ICommonStructs.sol";
import "../interfaces/IMetaBrain.sol";
import "../interfaces/IBrainOracle.sol";
import "../interfaces/IMetaDungeon.sol";
import "../interfaces/IBossFactory.sol";
import "../interfaces/IBoss.sol";
import "../interfaces/ITProxy.sol";

import "./mocks/autonomy/interfaces/IRegistry.sol";
import "./mocks/autonomy/interfaces/IOracle.sol";


contract MetaBrain is IMetaBrain, IERC721ReceiverUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    function initialize(
        IERC721Upgradeable players_,
        IMetaDungeon anft_,
        IBrainOracle brainOracle_,
        IRegistry registry_,
        IOracle oracle_,
        address userFeeVeriForwarder_,
        IBossFactory bossFactory_
    ) public virtual initializer {
        __MetaBrain_init(players_, anft_, brainOracle_, registry_, oracle_, userFeeVeriForwarder_, bossFactory_);
    }

    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint version = 0;

    // TODO: remove SentToPlayer
    event SentToPlayer(uint randNum, address ownerPool, address indexed newOwner);
    event Fought(uint indexed anft, uint indexed playerId, uint attack, bool won);
    event TeamSummoned(uint anftTokenId, uint teamSize, uint indexed playerId);

    // Consts
    uint public constant MAX_UINT = type(uint).max;
    uint public constant MAX_BPS = 1e18;
    uint public constant MIN_TEAM_SIZE = 2;

    IERC721Upgradeable public players;
    IMetaDungeon public anft;
    
    // MetaBrain
    IBrainOracle public brainOracle;
    IBossFactory public bossFactory;

    // mapping(uint => BossConfig) public bossConfigs;
    mapping(uint => IBoss) public bosses;
    // The last time an anft was executed by Autonomy
    mapping(uint => uint) public lastExecTimes;
    // The randomness seed to use for an epoch
    mapping(uint => uint) public epochRandNums;
	// The last time an NFT was used to summon if it doesn't require spending
    mapping(uint => mapping(IERC721Upgradeable => mapping(uint => uint))) public lastSummonNoSpendTime;
	// This is used to indicate when each player individually has summoned.
	// Called like [teamSize][playerId]
    mapping(uint => mapping(uint => mapping(uint => TeamSummon))) public teamPlayerSummons;
	// This is used to indicate when a team as a whole has summoned.
	// Called like [teamSize]
    mapping(uint => mapping(uint => uint)) public teamSummonTimes;


    // Autonomy
    IRegistry public registry;
    IOracle public oracle;
    address public userFeeVeriForwarder;


    function __MetaBrain_init(
        IERC721Upgradeable players_,
        IMetaDungeon anft_,
        IBrainOracle brainOracle_,
        IRegistry registry_,
        IOracle oracle_,
        address userFeeVeriForwarder_,
        IBossFactory bossFactory_
    ) internal onlyInitializing {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __MetaBrain_init_unchained(players_, anft_, brainOracle_, registry_, oracle_, userFeeVeriForwarder_, bossFactory_);
    }


    function __MetaBrain_init_unchained(
        IERC721Upgradeable players_,
        IMetaDungeon anft_,
        IBrainOracle brainOracle_,
        IRegistry registry_,
        IOracle oracle_,
        address userFeeVeriForwarder_,
        IBossFactory bossFactory_
    ) internal onlyInitializing {
        players = players_;
        anft = anft_;
        brainOracle = brainOracle_;
        registry = registry_;
        oracle = oracle_;
        userFeeVeriForwarder = userFeeVeriForwarder_;
        bossFactory = bossFactory_;
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  Team Summon and Fight                   //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function summonWithTeamAndFight(
        uint playerId,
        uint anftTokenId,
        uint teamSize,
        bytes memory password,
        uint[] calldata teamPoolPlayerIds,
        SetPath[] calldata powerupPaths,
        ERC20Deposit[] calldata erc20Deps,
        NFTDeposit[] calldata nftDeps
    ) external isPlayer(playerId) {
        (uint[] memory usedPlayerIds, uint summonCount) = _summonWithTeam(playerId, anftTokenId, teamSize, password, teamPoolPlayerIds);
        if (summonCount >= teamSize) {
            _fightBoss(playerId, anftTokenId, powerupPaths, erc20Deps, nftDeps, usedPlayerIds);
        }
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                        Team Summon                       //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function summonWithTeam(
        uint playerId,
        uint anftTokenId,
        uint teamSize,
        bytes memory password,
        uint[] calldata teamPoolPlayerIds,
        address newOwner
    ) external isPlayer(playerId) {
        (uint[] memory usedPlayerIds, uint summonCount) = _summonWithTeam(playerId, anftTokenId, teamSize, password, teamPoolPlayerIds);
        if (summonCount >= teamSize) {
            anft.safeTransferFrom(anft.ownerOf(anftTokenId), newOwner, anftTokenId);
        }
    }

    function _summonWithTeam(
        uint playerId,
        uint anftTokenId,
        uint teamSize,
        bytes memory password,
        uint[] calldata teamPoolPlayerIds
    ) private returns (uint[] memory usedPlayerIds, uint summonCount) {
        require(password.length > 1, "MB: small password");
        require(teamSize >= MIN_TEAM_SIZE, "MB: team too small");
        BossConfig memory config = bosses[anftTokenId].getConfig();
        uint lastExecTime = lastExecTimes[anftTokenId];
        uint epochRandNum = epochRandNums[anftTokenId];
        require(
            teamPlayerSummons[anftTokenId][teamSize][playerId].time < lastExecTime,
            "MB: team summon once per epoch"
        );
        require(teamSummonTimes[anftTokenId][teamSize] < lastExecTime, "MB: team already summoned");
        
        uint teamId = getTeamId(teamSize, epochRandNum, playerId);

        // Keep track of the player IDs that are used to win so any
        // winnings can be distributed between them
        usedPlayerIds = new uint[](teamSize);
        usedPlayerIds[0] = playerId;
        // Need to keep track of how many summons so we can use it to
        // populate usedPlayerIds as we go
        summonCount = 1;

        for (uint i; i < teamPoolPlayerIds.length; i++) {
            // Check that the player is actually on the same team as `teamPoolPlayerIds`
            require(getTeamId(teamSize, epochRandNum, teamPoolPlayerIds[i]) == teamId, "MB: team ids not the same");
            // Check that the passwords are the same for all, so they actually communicated
            TeamSummon memory teamSummon = teamPlayerSummons[anftTokenId][teamSize][teamPoolPlayerIds[i]];
            if (teamSummon.time >= lastExecTime && keccak256(teamSummon.password) == keccak256(password)) {
                // If the teammate's summon is in the present epoch, then count it
                usedPlayerIds[summonCount] = playerId;
                summonCount += 1;
                // If there are enough summons, then mark it as summoned and stop counting
                if (summonCount >= teamSize) {
                    teamSummonTimes[anftTokenId][teamSize] = block.timestamp;
                    break;
                }
            }
        }

        // Save the user's summon after checking the team summon count, so that
        // they can't double-count themselves, otherwise'd have to explicitly check for that too
        teamPlayerSummons[anftTokenId][teamSize][playerId] = TeamSummon(uint32(block.timestamp), password);

        emit TeamSummoned(anftTokenId, teamSize, playerId);
    }

    function getTeamId(uint teamSize, uint epochRandNum, uint playerId) public view returns (uint) {
        return uint(keccak256(abi.encodePacked(epochRandNum, playerId))) % (IERC721EnumerableUpgradeable(address(players)).totalSupply() / teamSize);
    }

    function getTeamIdByAnftId(uint teamSize, uint anftTokenId, uint playerId) external view returns (uint) {
        return uint(keccak256(abi.encodePacked(epochRandNums[anftTokenId], playerId))) % (IERC721EnumerableUpgradeable(address(players)).totalSupply() / teamSize);
    }

    function getTeamSummonTimes(uint anftTokenId, uint teamSize, uint playerId) external view returns (uint) {
        return teamPlayerSummons[anftTokenId][teamSize][playerId].time;
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                      Summon With NFT                     //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function summonWithItem(
        uint playerId,
        uint anftTokenId,
        SetPath calldata summonPath,
        address newOwner
    ) public nonReentrant isPlayer(playerId) {
        _summonWithItem(playerId, anftTokenId, summonPath);
        anft.safeTransferFrom(anft.ownerOf(anftTokenId), newOwner, anftTokenId);
    }

    function _summonWithItem(
        uint playerId,
        uint anftTokenId,
        SetPath calldata summonPath
    ) private {
        SummonSet memory summonSet = bosses[anftTokenId].getSummonSet(summonPath.setIdx);

        // If the length is 0, then accept any tokenId of this NFT
        if (summonSet.tokenIds.length != 0) {
            require(summonSet.tokenIds[summonPath.tokenIdIdx] == summonPath.tokenId, "MB: incorrect tokenId");
        }

        // If the NFT is required to be spent, then transfer it to this contract and
        // record that the specific anft owns that NFT. The transfer also implicitly
        // tests that msg.sender is the owner
        if (summonSet.spend) {
            summonSet.nft.safeTransferFrom(msg.sender, address(bosses[anftTokenId]), summonPath.tokenId);
        } else {
            require(
                lastSummonNoSpendTime[anftTokenId][summonSet.nft][summonPath.tokenId] < lastExecTimes[anftTokenId],
                "MB: spending item in same epoch"
            );
            lastSummonNoSpendTime[anftTokenId][summonSet.nft][summonPath.tokenId] = block.timestamp;
            require(summonSet.nft.ownerOf(summonPath.tokenId) == msg.sender, "MB: not the owner of tokenId");
        }
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                           Fight                          //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function fightBoss(
        uint playerId,
        uint anftTokenId,
        SetPath[] calldata powerupPaths,
        ERC20Deposit[] calldata erc20Deps,
        NFTDeposit[] calldata nftDeps
    ) external override isPlayer(playerId) returns (bool) {
        require(anft.ownerOf(anftTokenId) == msg.sender, "MB: not around the boss");
        uint[] memory team = new uint[](1);
        team[0] = playerId;
        return _fightBoss(playerId, anftTokenId, powerupPaths, erc20Deps, nftDeps, team);
    }

    function _fightBoss(
        uint playerId,
        uint anftTokenId,
        SetPath[] calldata powerupPaths,
        ERC20Deposit[] memory erc20Deps,
        NFTDeposit[] calldata nftDeps,
        uint[] memory team
    ) private returns (bool won) {
        // To prevent wrapping a call to this contract in a contract that reverts if it doesn't win
        require(msg.sender == tx.origin, "MB: nice try");

        BossConfig memory config = bosses[anftTokenId].getConfig();
        require(powerupPaths.length <= config.maxPowerups, "MB: you are too OP");

        uint randNum = brainOracle.getRandFightNum();
        uint attack = randNum / (MAX_UINT / MAX_BPS);

        NFTDeposit[] memory powerupDeps = new NFTDeposit[](powerupPaths.length);

        for (uint i; i < powerupPaths.length; i++) {
            PowerupSet memory powerupSet = bosses[anftTokenId].getPowerupSet(powerupPaths[i].setIdx);

            // If the length is 0, then accept any tokenId of this NFT
            if (powerupSet.tokenIds.length != 0) {
                require(powerupSet.tokenIds[powerupPaths[i].tokenIdIdx] == powerupPaths[i].tokenId, "MB: incorrect powerup tokenId");
            }

            if (powerupSet.spend) {
                // Cache the powerups that need to be deposited so that they can be deposited
                // after going through `nftDeps`, so that they can't be sent back
                powerupDeps[i] = NFTDeposit(powerupSet.nft, powerupPaths[i].tokenId);
            } else {
                require(powerupSet.nft.ownerOf(powerupPaths[i].tokenId) == msg.sender, "MB: not the owner of tokenId");
            }

            attack += powerupSet.effect;
        }
        
        uint anftTokenIdCopy = anftTokenId;
        won = attack >= config.difficulty;
        // Don't revert in the case of not beating the boss
        if (won) {
            address[] memory teamAddrs = new address[](team.length);
            // Get the player addresses sicne they need to be iterated over twice
            for (uint i; i < teamAddrs.length; i++) {
                teamAddrs[i] = players.ownerOf(team[i]);
            }

            // Split the tokens evenly between team members
            for (uint i; i < erc20Deps.length; i++) {
                erc20Deps[i].amount /= teamAddrs.length;
            }
            // Distribute the tokens
            for (uint i; i < teamAddrs.length; i++) {
                emit Test(i, teamAddrs.length);
                bosses[anftTokenIdCopy].withdrawERC20s(erc20Deps, teamAddrs[i]);
            }

            // There may be not enough NFTs for each team member, so distribute each
            // to a random team member by using a random offset to randomise the order.
            // I don't think it adds security to fully shuffle the array, simply adding
            // a random offset gives each player equal probability of being at a certain
            // index that an NFT is sent to. Doesn't seem exploitable? Famous last words
            uint offset = randNum % teamAddrs.length;
            for (uint i; i < nftDeps.length+1; i++) {
                if (i < nftDeps.length) {
                    bosses[anftTokenIdCopy].withdrawNFT(nftDeps[i], teamAddrs[(offset + i) % teamAddrs.length]);
                } else {
                    // Mint the Sword of a Thousand Truths
                }
            }
        }

        // Deposit the powerups that were spent fighting the boss, win or lose,
        // so they can't be withdrawn during the same fight
        for (uint i; i < powerupDeps.length; i++) {
            if (powerupDeps[i].nft != IERC721Upgradeable(address(0))) {
                powerupDeps[i].nft.safeTransferFrom(msg.sender, address(bosses[anftTokenIdCopy]), powerupDeps[i].id);
            }
        }

        emit Fought(anftTokenIdCopy, playerId, attack, won);

        _sendToRandomPlayer(anftTokenIdCopy, config.ownerPools, randNum);
    }
    event Test(uint a, uint b);


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                   Item Summon and Fight                  //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function summonWithItemAndFight(
        uint playerId,
        uint anftTokenId,
        SetPath calldata summonPath,
        SetPath[] calldata powerupPaths,
        ERC20Deposit[] calldata erc20Deps,
        NFTDeposit[] calldata nftDeps
    ) public nonReentrant isPlayer(playerId) returns (bool) {
        _summonWithItem(playerId, anftTokenId, summonPath);
        uint[] memory team = new uint[](1);
        team[0] = playerId;
        return _fightBoss(playerId, anftTokenId, powerupPaths, erc20Deps, nftDeps, team);
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                    Boss creation/config                  //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function newBoss(
        address to,
        address brain,
        string[] memory tokenURIs,
        BossConfig calldata config,
        uint lastExecTime,
        address payable referer,
        bytes calldata callData
    ) external onlyOwner returns (uint anftTokenId, IBoss boss) {
        anftTokenId = anft.mint(to, brain, tokenURIs);
        boss = IBoss(bossFactory.newBoss(anftTokenId, address(this), config, 0x602C71e4DAC47a042Ee7f46E0aee17F94A3bA0B6, owner()));
        bosses[anftTokenId] = boss;
        lastExecTimes[anftTokenId] = lastExecTime;
        epochRandNums[anftTokenId] = brainOracle.getRandFightNum();


        // _newReqSendToPlayer(referer, callData);
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Autonomy                        //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function sendToRandomPlayer(
        address user,
        uint feeAmount,
        uint anftTokenId,
        uint epoch0,
        uint epochLength,
        address[] memory ownerPools
    ) external userFeeVerified nonReentrant {
        require(user == address(this), "MB: not requested by self");

        uint lastExecTime = lastExecTimes[anftTokenId];
        uint startTime = epoch0 > lastExecTime ? epoch0 : lastExecTime;
        require(block.timestamp >= startTime + epochLength, "MB: patience, degen");
        lastExecTimes[anftTokenId] = startTime + epochLength;

        uint rand = brainOracle.getRandFightNum();
        _sendToRandomPlayer(anftTokenId, ownerPools, rand);
        epochRandNums[anftTokenId] = rand;

        payable(address(registry)).transfer(feeAmount);
    }

    function _sendToRandomPlayer(
        uint anftTokenId,
        address[] memory ownerPools,
        uint randNum
    ) private {
        // Using a recent blockhash is fine to start with, but a better solution is
        // needed. A 3rd party oracle is possible, but having it split over multiple
        // txs is not ideal, plus the cost. Another idea is to use things that frequently
        // change within a block as a seed, such as the balance of the most popular Uniswap
        // pools, or their TWAP - it would be too costly and alot of effort to simulate
        // the order of the txs in a block to see the outcome, while also mining. The miner
        // should only be able to change a single thing - having 2 changable things such as
        // the place of the tx in a block and something like the block timestamp would mean
        // that they could just change 1 of the 2 (the easier - the timestamp in that case)
        // and not need to bother with the other
        address ownerPool = ownerPools[randNum % ownerPools.length];
        address newOwner = IERC721Upgradeable(ownerPool).ownerOf(randNum % IERC721EnumerableUpgradeable(ownerPool).totalSupply());
        emit SentToPlayer(randNum, ownerPool, newOwner);

        anft.safeTransferFrom(anft.ownerOf(anftTokenId), newOwner, anftTokenId);
    }

    function newReqSendToPlayer(
        address payable referer,
        bytes calldata callData
    ) external onlyOwner returns (uint) {
        return _newReqSendToPlayer(referer, callData);
    }

    function _newReqSendToPlayer(
        address payable referer,
        bytes calldata callData
    ) private returns (uint) {
        return registry.newReqPaySpecific(
            address(this),
            referer,
            callData,
            0,
            true,
            true,
            false,
            true
        );
    }

    function cancelHashedReq(uint id, IRegistry.Request memory r) external onlyOwner {
        registry.cancelHashedReq(id, r);
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                       Miscellaneous                      //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function setVersion(uint newX) onlyOwner public {
        version = newX;
    }

    function getURIVersion(uint tokenId) public view override returns (uint) {
        return version;
    }

    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Modifiers                       //
    //                                                          //
    //////////////////////////////////////////////////////////////

    modifier userFeeVerified() {
        require(msg.sender == userFeeVeriForwarder, "MB: not userFeeForw");
        _;
    }

    modifier isPlayer(uint playerId) {
        require(msg.sender == players.ownerOf(playerId), "MB: you are not a player");
        _;
    }
    
    receive() external payable {}
}