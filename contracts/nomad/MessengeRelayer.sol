// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../erc-7786/IERC7786GatewaySource.sol";
import "../erc-7786/IERC7786Recipient.sol";

import "./interfaces/IMessageReceiver.sol";

contract MessengeRelayer is IERC7786GatewaySource {
	
	address public home;

	constructor(address _home) {
		home = _home;
	}

	function sendMessage(bytes calldata recipient, bytes calldata payload, bytes[] calldata attributes) external payable returns (bytes32 sendId) {

		/*

		// cast recipient to bytes32
		bytes32 _recip = TypeCasts.addressToBytes32(_recipient);

		// dispatch your message across chains!
		home.dispatch(toChain, _recip, message);

		emit CrosschainMessageSent(toChain, _recip, message);

		*/
	}

	/*
	* @notice Receive a Hello message from any sender :) 
	* @param _origin Domain of the origin chain
	* @param _sender Address of sender on origin chain as bytes32
	* @param _message Raw bytes content of message
	*/
	function handle(
			uint32 _origin,
			uint32 _nonce,
			bytes32 _sender,
			bytes memory _message
	) external {

			/*address _sendr = TypeCasts.bytes32ToAddress(_sender);

			// 3. Decode the message payload
			string memory message = string(_message);
			IERC7786Recipient(fromAddress).receiveMessage(messageId, fromAddress, _message);

			// 4. Emit event
			emit CrosschainMessageReceived(_origin, _sendr, message);*/

	}

}