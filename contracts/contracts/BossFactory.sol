
pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./TProxy.sol";
import "./Boss.sol";
import "../interfaces/ICommonStructs.sol";
import "../interfaces/IBossFactory.sol";


contract BossFactory is ICommonStructs, IBossFactory, Initializable {

	function initialize(address impl_) public virtual initializer {
		impl = impl_;
	}

	// event Test(bytes indexed a);

	address public impl;

	function newBoss(uint id, address brain, BossConfig calldata config, address admin, address owner) external override returns (address payable proxyAddr) {
		proxyAddr = payable(address(new TProxy(impl, admin, abi.encodeWithSelector(Boss.initialize.selector, id, brain, config))));
		Boss(proxyAddr).transferOwnership(owner);
	}

	function newBossView(uint id, address brain, BossConfig calldata config, address admin) external view returns (bytes memory) {
		// Boss boss = new Boss(id, brain, config);
		// boss.transferOwnership(owner);

		// TODO: need to change address(0) to the admin of the calling contract, need to find out how MetaBrain can know its own admin inside the contract

		// emit Test(abi.encodeWithSelector(Boss.initialize.selector, id, brain, config));
		return abi.encodeWithSelector(Boss.initialize.selector, id, brain, config);
	}
}