// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./IRelayer.sol";

interface IMessageRelayer is IRelayer{

	function sendCrosschainMessage(uint32 toChain, address toAddress, string calldata message) external;

	event CrosschainMessageSent(uint32 toChain, address toAddress, string message);

	event CrosschainMessageReceived(uint256 fromChain, address fromAddress, string message);

}