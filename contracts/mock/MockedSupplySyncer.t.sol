// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../relayers/ISupplySyncer.sol";

import "../token/IMultichainToken.sol";

contract MockedSupplySyncer is ISupplySyncer {

	function syncSupplies(uint256 onChain, address onAddress, uint256 fromChain, uint256 toChain, uint256 amount, bytes32 checksum) external override {

			emit CrosschainSyncSupplySent(onChain, onAddress, fromChain, toChain, amount);

			IMultichainToken(onAddress).onSyncSupplies(onChain, onAddress, fromChain, toChain, amount, checksum);

			emit CrosschainSyncSupplyReceived(onChain, onAddress, fromChain, toChain, amount);

	}

}