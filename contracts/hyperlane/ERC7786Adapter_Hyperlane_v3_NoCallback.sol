// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../erc-7786/IERC7786GatewaySource.sol";
import "../erc-7786/IERC7786Recipient.sol";

import "./interfaces/IMailbox.sol";
import "./interfaces/IMessageRecipient.sol";

// Hyperlane GMP
contract ERC7786Adapter_Hyperlane_v3_NoCallback is IERC7786GatewaySource, IMessageRecipient {

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

		// 1. Convert the recipient address to bytes32
		/*bytes32 recipient = bytes32(uint256(uint160(toAddress)));

		bytes memory messageBytes = bytes(message);

		// 2. Get the fee required for the dispatch
		uint256 fee = outbox.quoteDispatch(
			toChain,
			recipient,
			messageBytes
		);

		// 3. Dispatch the message, sending the fee as value
		bytes32 messageId = outbox.dispatch{value: fee}(
			toChain,
			recipient,
			messageBytes
		);

		emit MessageSent(toChain, toAddress, message);*/

	}

	// *************************************************************************************************
	// ************************************* Receive Message *******************************************
	// *************************************************************************************************
	IMailbox inbox;

	function handle(uint32 _origin, bytes32 _sender, bytes calldata _message) external payable override {

		// 1. Prevent processing invalid messages
		/*require(_origin > 0, "Invalid origin");
		require(_sender != bytes32(0), "Invalid sender");
		require(_message.length > 0, "Empty message");

		address fromAddress = address(uint160(uint256(_sender)));
		require(fromAddress == address(inbox), "MailboxClient: sender not mailbox");
		
		// 2. Prevent replay attacks
		bytes32 messageId = keccak256(abi.encodePacked(_origin, _sender, _message));
		require(!processedMessages[messageId], "Message already processed");
		processedMessages[messageId] = true;
		
		// 3. Decode the message payload
		IERC7786Recipient(fromAddress).receiveMessage(messageId, fromAddress, _message);

		// 4. Emit event
		emit CrosschainMessageReceived(_origin, fromAddress, message);*/

	}

}