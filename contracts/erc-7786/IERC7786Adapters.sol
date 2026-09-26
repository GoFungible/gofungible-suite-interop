// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IERC7786Adapters {
	
	// === Errors ===
	error InvalidRecipient();
	error InvalidDestinationChain();
	error NotMailbox();
	error InvalidOrigin();
	error InvalidMessage();
	error InvalidProcessing();
	
	event MessageDelivered(
		bytes32 indexed messageId,
		uint32 originDomain,
		bytes32 sender,
		bytes payload
	);
}
