// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../erc-7786/IERC7786GatewaySource.sol";
import "../erc-7786/IERC7786Recipient.sol";

import "./interfaces/IDeBridgeGate.sol";

contract MessengeRelayer is IERC7786GatewaySource {
	
	IDeBridgeGate public immutable deBridgeGate;

	constructor(address _deBridgeGate) {
		deBridgeGate = IDeBridgeGate(_deBridgeGate);
	}

	function sendMessage(bytes calldata recipient, bytes calldata payload, bytes[] calldata attributes) external payable returns (bytes32 sendId) {

		/*deBridgeGate.sendMessage{value: msg.value}(
			toChain,
			abi.encodePacked(toAddress),
			bytes(message)
    );

		emit CrosschainMessageSent(toChain, bytes32(toAddress), depositData);*/

	}

	// The function to be called by the deBridge protocol.
	// 1. It MUST be restricted to only the deBridge CallProxy contract.
	// 2. It should receive the standard deBridge `SubmissionAutoParams` structure.
	function receiveCrossChainMessage(
			bytes calldata /* args */,
			bytes calldata /* txnHash */,
			uint256 /* srcChainIdFrom */,
			address /* sender */,
			IDeBridgeGate.SubmissionAutoParamsTo memory /* autoParams */
	) external {
			
			/*
		IERC7786Recipient(fromAddress).receiveMessage(messageId, fromAddress, _message);

			*/
			

	}

}