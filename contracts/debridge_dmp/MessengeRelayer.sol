// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/IMessageRelayer.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/token/IMultichainToken.sol";

import "./interfaces/IDeBridgeGate.sol";

contract MessengeRelayer is IMessageRelayer, IGmpTransferAdapter {
	
	IDeBridgeGate public immutable deBridgeGate;

	constructor(address _deBridgeGate) {
		deBridgeGate = IDeBridgeGate(_deBridgeGate);
	}

	function sendCrosschainMessage(uint32 toChain, address toAddress, string calldata message) external override {

		deBridgeGate.sendMessage{value: msg.value}(
			toChain,
			abi.encodePacked(toAddress),
			bytes(message)
    );

		emit CrosschainMessageSent(toChain, bytes32(toAddress), depositData);

	}

	// The function to be called by the deBridge protocol.
	// 1. It MUST be restricted to only the deBridge CallProxy contract.
	// 2. It should receive the standard deBridge `SubmissionAutoParams` structure.
	function receiveCrossChainMessage(
			bytes calldata /* args */,
			bytes calldata /* txnHash */,
			uint256 /* srcChainIdFrom */,
			address /* sender */,
			IDeBridgeGate.SubmissionAutoParams memory /* autoParams */
	) external onlyDebridgeCallProxy {
			// +++ THIS IS WHERE YOUR CUSTOM LOGIC GOES +++
			

	}

}