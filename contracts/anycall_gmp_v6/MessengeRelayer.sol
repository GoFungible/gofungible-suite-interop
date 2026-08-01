// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../erc-7786/IERC7786GatewaySource.sol";
import "../erc-7786/IERC7786Recipient.sol";

import "./interfaces/IAnycallV6Proxy.sol";

contract MessengeRelayer is IERC7786GatewaySource {

	// Anycall proxy contract
	IAnycallV6Proxy public anycallProxy;

	/**
	 * @dev Constructor
	 * @param _anycallProxy The Anycall V6 proxy contract address
	 */
	constructor(address _anycallProxy) {
    anycallProxy = IAnycallV6Proxy(_anycallProxy);
	}

	function sendMessage(bytes calldata recipient, bytes calldata payload, bytes[] calldata attributes) external payable returns (bytes32 sendId) {

		/*

		// Encode the function call for destination
		bytes memory callData = abi.encodeWithSignature(
			"receiveAnyMessage(uint256,address,string)",
			block.chainid, // fromChainId
			msg.sender,    // original sender
			message        // the message
		);
		
		// Estimate and pay fee
		uint256 fee = estimateFee(toChainId, destinationContract, callData);
		require(msg.value >= fee, "Insufficient fee");
        
		// Execute cross-chain call
		anycallProxy.anyCall{value: fee}(
			destinationContract,  // destination contract
			callData,            // calldata
			toChainId,           // destination chain ID
			2,                   // flags: 0 - pay on dest, 2 - pay on source
			""                   // extra data (for fallback)
		);

		*/
        
	}

	/**
	 * @dev Receive cross-chain messages (called by Anycall proxy)
	 * @param data Encoded message data
	 */
	function anyExecute(bytes calldata data) external returns (bool success, bytes memory result) {

		/*

    require(msg.sender == address(anycallProxy), "Only Anycall proxy can call");

		// Decode the incoming data
		(uint256 fromChainId, address sender, string memory message) = 
				abi.decode(data, (uint256, address, string));

		IERC7786Recipient(fromAddress).receiveMessage(messageId, fromAddress, _message);

		emit CrosschainMessageReceived(fromChain, fromAddress, message);

		// Return success status and optional return data
    return (true, "");

		*/
	}

}