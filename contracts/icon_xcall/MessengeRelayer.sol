// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/IMessageRelayer.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/token/IMultichainToken.sol";

import "./erc-7786/IERC7786GatewaySource.sol";
import "./erc-7786/IERC7786Recipient.sol";

contract MessengeRelayer is IMessageRelayer, IXCallReceiver, IERC7786GatewaySource {
	
	address public xCallAddress;

	constructor(address _xCallAddress) {
		xCallAddress = _xCallAddress;
	}

	function sendMessage(bytes calldata recipient, bytes calldata payload, bytes[] calldata attributes) external payable returns (bytes32 sendId) [

	]

	function sendCrosschainMessage(uint32 toChain, address toAddress, string calldata message) external override {

		bytes memory data = abi.encode(message);
		bytes memory rollback = new bytes(0); // Empty if no rollback behavior is needed

		// Forward the contract's native fee payment to xCall
		IXCall(xCallAddress).sendCallMessage{value: msg.value}(_to, data, rollback);

	}

	/**
	 * @notice Handles messages delivered by the xCall execution relayer
	 * @param _from The source chain sender address string
	 * @param _data The encoded payload containing the message
	 */
	function handleCallMessage(
			string calldata _from,
			bytes calldata _data
	) external override {
			// Enforce that only the authentic local xCall contract can trigger this method
			require(msg.sender == xCallAddress, "Only xCall contract can invoke");

			// Decode the data exactly how it was encoded on the source chain
			string memory message = abi.decode(_data, (string));


			emit MessageReceived(_from, message);
	}

}