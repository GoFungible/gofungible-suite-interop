// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// We use bytes32 instead of address so that, in the future, messages will be compatible with other chain VMs like Cosmos and Polkadot. 
// In the EVM, addresses are 20 bytes long, but most other chains have 32 byte addresses. Worry not - we have a TypeCasts.sol library to help convert between these types easily.
interface IMessageRecipient {
	function handle(
			uint32 _origin,
			uint32 _nonce,
			bytes32 _sender,
			bytes memory _message
	) external;
}