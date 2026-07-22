// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/IMessageRelayer.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/token/IMultichainToken.sol";

import "./interfaces/IWormholeReceiver.sol";

contract MessengeRelayer is IMessageRelayer, IWormholeReceiver {
	
	IWormholeRelayer public wormholeRelayer;
	uint256 constant GAS_LIMIT = 50000;

	constructor(address _wormholeRelayer) {
		wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
	}

	function quoteCrossChainCost(
			uint16 targetChain
	) public view returns (uint256 cost) {
			(cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
					targetChain,
					0,
					GAS_LIMIT
			);
	}


	function sendCrosschainMessage(uint32 toChain, address toAddress, string calldata message) external override {

		uint256 cost = quoteCrossChainCost(targetChain);

		require(msg.value >= cost, "Insufficient funds for cross-chain delivery");

		wormholeRelayer.sendPayloadToEvm{value: cost}(
				uint16(toChain),
				toAddress,
				abi.encode(message, msg.sender),
				0,
				GAS_LIMIT
		);

		emit CrosschainMessageSent(toChain, toAddress, message);

	}

	// Update receiveWormholeMessages to include the source address check
	function receiveWormholeMessages(
			bytes memory payload,
			bytes[] memory,
			bytes32 sourceAddress,
			uint16 sourceChain,
			bytes32
	) public payable override {
			require(
					msg.sender == address(wormholeRelayer),
					"Only the Wormhole relayer can call this function"
			);

			// Decode the payload to extract the message
			string memory message = abi.decode(payload, (string));

			// 3. Decode the message payload
			IMultichainToken(fromAddress).onCrosschainMessage(sourceChain, sourceAddress, message);

			// 4. Emit event
			emit CrosschainMessageReceived(sourceChain, sourceAddress, message);
	}

}