// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../erc-7786/IERC7786GatewaySource.sol";
import "../erc-7786/IERC7786Recipient.sol";

import "./interfaces/IAnyCallProxyV7.sol";

contract MessengeRelayer is IERC7786GatewaySource {

	// Anycall proxy contract
	IAnyCallProxyV7 public anycallProxy;

	/**
	 * @dev Constructor
	 * @param _anycallProxy The Anycall V6 proxy contract address
	 */
	constructor(address _anycallProxy) {
    anycallProxy = IAnyCallProxyV7(_anycallProxy);
	}

	function sendMessage(bytes calldata recipient, bytes calldata payload, bytes[] calldata attributes) external payable returns (bytes32 sendId) {

		/*

		anycallProxy.anyCall{value: msg.value}(
			toAddress, 														//Destination Contract Address
			
			abi.encode(message), 									//encoded string as bytes
			toChain, 															//destination chain id
			
			0, 																		// Using 0 flag to pay fee on the source chain
			"" 																		//extra data used for advanced use cases
			);
		}

		*/

	}

	/**
	 * @notice The core v7 receiving function executed by the anyCall relayers.
	 * @param data The ABI-encoded payload sent from the source chain.
	 */
	function anyExecute(bytes calldata data) external returns (bool success, bytes memory result) {

		/*
		// Security Check 1: Ensure ONLY the official anyCall executor is calling this function
		require(msg.sender == anycallExecutor, "Client: Only Executor allowed");

		// Fetch the cross-chain execution context from the executor
		(address from, uint256 fromChainId, ) = IAnycallExecutorV7(anycallExecutor).context();

		// Security Check 2: Verify the message comes from your trusted source contract and chain
		require(from == trustedSourceContract, "Client: Untrusted source contract");
		require(fromChainId == trustedSourceChainId, "Client: Untrusted source chain");

		// Decode the payload parameters (must match the layout packed on the source chain)
		(string memory _msg, uint256 _val) = abi.decode(data, (string, uint256));

		IERC7786Recipient(fromAddress).receiveMessage(messageId, fromAddress, _message);

		emit CrosschainMessageReceived(fromChain, from, _msg);

		// Return success status and optional return data
		return (true, "");

		*/
	}

}