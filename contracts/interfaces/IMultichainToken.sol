// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IMultichainToken {

	function onCrosschainMessage(uint256 fromChain, address fromAddress, string calldata message) external;

	function onCrosschainSupply(uint256 fromChain, address fromAddress, uint256 amount) external;

	function onSyncSupplies(uint256 onChain, address onAddress, uint256 fromChain, uint256 toChain, uint256 amount, bytes32 checksum) external;

}