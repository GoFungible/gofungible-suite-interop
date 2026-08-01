// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/IMessageRelayer.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/token/IMultichainToken.sol";

import "./erc-7786/IERC7786GatewaySource.sol";
import "./erc-7786/IERC7786Recipient.sol";

import "./interfaces/IGmpReceiver.sol";
import "./interfaces/IGateway.sol";

// https://github.com/Analog-Labs/analog-gmp/blob/main/src/GmpProxy.sol
contract MessengeRelayer is IMessageRelayer, IGmpReceiver, IERC7786GatewaySource {
	
	IGateway public immutable GATEWAY;
	uint16 public immutable NETWORK_ID;

	constructor(address gateway) payable {
		GATEWAY = IGateway(gateway);
		NETWORK_ID = GATEWAY.networkId();
	}

	function sendCrosschainMessage(uint32 toChain, address toAddress, string calldata message) external override {
		return GATEWAY.submitMessage{value: msg.value}(toAddress, toChain, gasLimit, bytes(message));
	}

	function sendMessage(bytes calldata recipient, bytes calldata payload, bytes[] calldata attributes) external payable returns (bytes32 sendId) [

	]

	function onGmpReceived(bytes32 id, uint128 network, bytes32 source, uint64 nonce, bytes calldata payload) external payable returns (bytes32) {
		
		IMultichainToken(fromAddress).onCrosschainMessage(network, address(source), string(payload));

		emit CrosschainMessageReceived(network, address(source), string(payload));

    return id;
	}

}