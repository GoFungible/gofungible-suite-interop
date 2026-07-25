// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../token/IMultichainToken.sol";

contract MockedMultichainToken is IMultichainToken {

	function onCrosschainMessage(uint256 fromChain, address fromAddress, string calldata message) external override {

	}

	function onCrosschainSupply(uint256 destChain, address destAddress, uint256 amount) external override {

	}

	function onSyncSupplies(uint256 onChain, address onAddress, uint256 fromChain, uint256 toChain, uint256 amount, bytes32 checksum) external {

	}

}