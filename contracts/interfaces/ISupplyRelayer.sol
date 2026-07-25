// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./IRelayer.sol";

interface ISupplyRelayer is IRelayer {

	function sendCrosschainSupply(uint256 toChain, address toAddress, uint256 amount) external;

	event CrosschainSupplySent(uint256 toChain, address toAddress, uint256 amount);

	event CrosschainSupplyReceived(uint256 fromChain, address fromAddress, uint256 amount);

}
