// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../erc-7786/IERC7786GatewaySource.sol";
import "../erc-7786/IERC7786Recipient.sol";
import "../erc-7786/IERC7786Adapters.sol";

import "./interfaces/IMailbox.sol";
import "./interfaces/IMessageRecipient.sol";

import {LibERC7786ToEthAdapter} from "../erc-7786/LibERC7786ToEthAdapter.sol";

// Hyperlane GMP
contract ERC7786Adapter_Hyperlane_v3_Callback is IERC7786Adapters, IERC7786GatewaySource, IMessageRecipient {

	mapping(bytes32 => bool) public processedMessages;
	
	mapping(uint32 => bytes32) public trustedSenders;

	constructor(address _outbox, address _inbox) {
		outbox = IMailbox(_outbox);
		inbox = IMailbox(_inbox);
	}

	// *************************************************************************************************
	// ************************************* Send Message **********************************************
	// *************************************************************************************************
	IMailbox outbox;

	function sendMessage(bytes calldata recipient, bytes calldata payload, bytes[] calldata attributes) external payable returns (bytes32 sendId) {

		// Parse recipient for Hyperlane destination
		(uint32 destinationDomain, bytes32 recipientAddress) = LibERC7786ToEthAdapter._parseInteroperableAddress(recipient);
		if (recipientAddress == bytes32(0)) revert InvalidRecipient();
		if (destinationDomain == 0) revert InvalidDestinationChain();

		// Build Hyperlane message payload
		// Format: adapter address (32 bytes) + original recipient (32 bytes) + original payload
		bytes memory hyperlanePayload = abi.encode(recipientAddress, payload);
		
		// Dispatch the message, sending the fee as value
		sendId = outbox.dispatch{value: msg.value}(
			destinationDomain,
			recipientAddress,
			hyperlanePayload
		);

		// Emit ERC-7786 MessageSent event
		emit MessageSent(
			sendId,
			abi.encodePacked(block.chainid, msg.sender), // sender interoperable address
			recipient,
			payload,
			msg.value,
			attributes
		);

	}

	// *************************************************************************************************
	// ************************************* Receive Message *******************************************
	// *************************************************************************************************
	IMailbox inbox;
  mapping(bytes32 => bool) public deliveredMessages;

	/**
	 * @notice Handles incoming Hyperlane messages
	 * @dev Called by Mailbox.process() after ISM verification
	 * 
	 * There is not parameter for target address. It can be found out by handle() in 3 ways:
	 * - Token-Specific Contracts (The Warp Route Model) - One gateway per target token
	 * - Internal Registry Mapping (The Router Pattern) - The target registerwith the gateway 
	 * - Explicit Payload Encoding (Dynamic Forwarding) - target address is included in the payload
	 */
  function handle(uint32 _origin, bytes32 _sender, bytes calldata _message) external payable override {

    // Prevent processing invalid messages
  	if (msg.sender != address(inbox)) revert NotMailbox();

		// Decode message
		(bytes32 recipient, bytes memory payload) = abi.decode(_message, (bytes32, bytes));
		address recipientAddress = address(uint160(uint256(recipient)));
		
		// Prevent replay attacks
		bytes32 messageId = keccak256(abi.encodePacked(_origin, _sender, _message));
		require(!processedMessages[messageId], "Message already processed");
		processedMessages[messageId] = true;
		
		// Send message to target token
		address senderAddress = address(uint160(uint256(_sender)));
		bytes memory senderBOA = LibERC7786ToEthAdapter.generateERC7930Record(_origin, senderAddress);
		bytes4 response = IERC7786Recipient(recipientAddress).receiveMessage(messageId, senderBOA, payload);
		if (response != IERC7786Recipient.receiveMessage.selector) revert InvalidProcessing();

		// Emit event
    emit MessageDelivered(messageId, _origin, _sender, _message);

	}

}