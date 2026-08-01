// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../erc-7786/IERC7786GatewaySource.sol";
import "../erc-7786/IERC7786Recipient.sol";

import "./interfaces/IXCallReceiver.sol";

contract MessengeRelayer is IERC7786GatewaySource, IXCallReceiver {
	
	address public xCallAddress;

	constructor(address _xCallAddress) {
		xCallAddress = _xCallAddress;
	}

	function sendMessage(bytes calldata recipient, bytes calldata payload, bytes[] calldata attributes) external payable returns (bytes32 sendId) {

		/*
		bytes memory data = abi.encode(message);
		bytes memory rollback = new bytes(0); // Empty if no rollback behavior is needed

		// Forward the contract's native fee payment to xCall
		IXCall(xCallAddress).sendCallMessage{value: msg.value}(_to, data, rollback);
		*/

	}

	/**
	 * @notice Handles messages delivered by the xCall execution relayer
	 * @param _from The source chain sender address string
	 * @param _data The encoded payload containing the message
	 */
	function handleCallMessage(
			string calldata _from,
			bytes calldata _data
	) external {
			// Enforce that only the authentic local xCall contract can trigger this method
			/*
			require(msg.sender == xCallAddress, "Only xCall contract can invoke");

			// Decode the data exactly how it was encoded on the source chain
			string memory message = abi.decode(_data, (string));
			IERC7786Recipient(fromAddress).receiveMessage(messageId, fromAddress, _message);


			emit MessageReceived(_from, message);
			*/
	}

	function handleCallMessage(string memory _from, bytes[]memory _data) external {
		
	}

	function handleCallMessage(string memory _from, bytes[] memory _data, string[] memory _protocols) external {

	}

}