// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./interfaces/IMailbox.sol";
import "./interfaces/IMessageRecipient.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/IMessageRelayer.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/token/IMultichainToken.sol";

// Hyperlane GMP
contract MessengeRelayer is IMessageRelayer, IMessageRecipient {

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

	function sendCrosschainMessage(uint32 toChain, address toAddress, string calldata message) external override {

		// 1. Convert the recipient address to bytes32
		bytes32 recipient = bytes32(uint256(uint160(toAddress)));

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

		//emit SentMessage(toChain, toAddress, message);
	}

	// *************************************************************************************************
	// ************************************* Receive Message *******************************************
	// *************************************************************************************************
	IMailbox inbox;

	function handle(uint32 _origin, bytes32 _sender, bytes calldata _message) external payable override {
		// 1. Prevent processing invalid messages
		require(_origin > 0, "Invalid origin");
		require(_sender != bytes32(0), "Invalid sender");
		require(_message.length > 0, "Empty message");

		address fromAddress = address(uint160(uint256(_sender)));
		require(fromAddress == address(inbox), "MailboxClient: sender not mailbox");
		
		// 2. Prevent replay attacks
		bytes32 messageId = keccak256(abi.encodePacked(_origin, _sender, _message));
		require(!processedMessages[messageId], "Message already processed");
		processedMessages[messageId] = true;
		
		// 3. Decode the message payload
		string memory message = string(_message);
		IMultichainToken(fromAddress).onCrosschainMessage(_origin, fromAddress, message);

		// 4. Emit event
		emit MessageRelayed(_origin, fromAddress, message);



		/*(address recipient, uint256 amount) = abi.decode(_body, (address, uint256));
		require(recipient != address(0), "Invalid recipient");
		require(amount > 0, "Amount must be > 0");
		
		// 4. Mint tokens to recipient on destination chain
		token.mint(recipient, amount);
		totalMinted += amount;
		
		emit TokensReceived(recipient, amount, messageId);*/




	}

}