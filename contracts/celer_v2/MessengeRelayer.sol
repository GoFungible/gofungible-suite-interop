// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../erc-7786/IERC7786GatewaySource.sol";
import "../erc-7786/IERC7786Recipient.sol";

contract MessengeRelayer is IERC7786GatewaySource {

	// The official Celer MessageBus address on the source chain
	address public immutable messageBus;

	constructor(address _messageBus) {
		require(_messageBus != address(0), "Invalid MessageBus address");
		messageBus = _messageBus;
	}

	function sendMessage(bytes calldata recipient, bytes calldata payload, bytes[] calldata attributes) external payable returns (bytes32 sendId) {

		// High-utility safety check ensuring gas fee is attached
		/*require(msg.value > 0, "Celer requires native fee for cross-chain execution");

		// Execute directly on the native Celer MessageBus contract 
		IMessageBus(messageBus).sendMessage{value: msg.value}(
			_receiver,
			_dstChainId,
			_payload
		);

		emit CustomMessageSent(_receiver, _dstChainId, _payload);*/
	}

	/**
	 * @notice The core execution function called by Celer's MessageBus.
	 * @param _sender The contract address that sent the message on the source chain.
	 * @param _srcChainId The chain ID where the message originated.
	 * @param _message The arbitrary byte payload payload from the source chain.
	 * @param * (executor) The address of the executor executing this message (ignored here).
	 */
	function executeMessage(
			address _sender,
			uint256 _srcChainId,
			bytes calldata _message,
			address // executor
	) external payable returns (uint256) {
			// Security Check 1: Ensure ONLY the official Celer MessageBus is calling this function
			/*require(msg.sender == messageBus, "Execution restricted to Celer MessageBus");

			// Security Check 2: Verify the message comes from your trusted source contract
			//require(_sender == trustedSender, "Untrusted source sender");

			// Security Check 3: Verify the message comes from your trusted source blockchain
			//require(_srcChainId == trustedSourceChainId, "Untrusted source blockchain");

			// Decode the payload parameters (must exactly match the format packed on the source chain)
			(string memory _text, uint256 _num) = abi.decode(_message, (string, uint256));

			// 3. Decode the message payload
			string memory message = string(_message);
			IERC7786Recipient(fromAddress).receiveMessage(messageId, fromAddress, _message);

			// 4. Emit event
			emit CrosschainMessageReceived(_srcChainId, _sender, _text);

			// Celer execution status enum: 0 = Success, 1 = Fail, 2 = Retry
			return 0; */
	}

}