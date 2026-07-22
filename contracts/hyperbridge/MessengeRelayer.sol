// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/IMessageRelayer.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/token/IMultichainToken.sol";

import "./interfaces/IDispatcher.sol";
import "./interfaces/IApp.sol";

contract MessengeRelayer is IMessageRelayer, IApp {
	
	// The Hyperbridge Host (or Dispatcher) contract on the local chain
	IDispatcher public immutable dispatcher;

	constructor(address _dispatcher) {
		dispatcher = IDispatcher(_dispatcher);
	}

	function sendCrosschainMessage(uint32 toChain, address toAddress, string calldata message) external override {

		// 1. Encode the string message into a raw byte payload
		bytes memory payload = abi.encode(message);

		// 2. Format the dispatch structural parameters
		DispatchPost memory request = DispatchPost({
			dest: toChain,
			to: abi.encodePacked(toAddress),
			body: payload,
			timeout: 3600, // Timeout window in seconds (e.g., 1 hour)
			fee: 0         // Fee tiering depends on your relay parameters / paying in gas
		});

		// 3. Dispatch the message via Hyperbridge's IDispatcher
		// If your configuration requires native token fees, pass them via "value: msg.value"
		dispatcher.dispatch{value: msg.value}(request);

		emit CrosschainMessageSent(toChain, toAddress, message);

	}

	/**
	 * @notice The callback hook invoked by Hyperbridge when a cross-chain request arrives
	 * @dev Protected by the BaseIsmpModule which handles initial verification checks
	 * @param request Struct containing metadata and the execution payload from the source chain
	 */
	function onAccept(IncomingPostRequest calldata request) public override {
		// SECURITY: Always verify that the caller is the trusted local Hyperbridge host
		// Note: The parent module or your local architecture typically validates the msg.sender
		
		// Decode the data exactly how it was packaged on the source chain
		string memory decodedMessage = abi.decode(request.body, (string));

		emit MessageReceived(decodedMessage);
	}

}
