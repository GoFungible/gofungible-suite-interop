// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/IMessageRelayer.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/token/IMultichainToken.sol";

import "./erc-7786/IERC7786GatewaySource.sol";
import "./erc-7786/IERC7786Recipient.sol";

// https://docs.sodax.com/developers/technical-overview/asset-manager
contract MessengeRelayer is IMessageRelayer, IERC7786GatewaySource {
	

	constructor(address _gateway, address _gasService) {

	}

	function sendMessage(bytes calldata recipient, bytes calldata payload, bytes[] calldata attributes) external payable returns (bytes32 sendId) [

	]

	function sendCrosschainMessage(uint32 toChain, address toAddress, string calldata message) external override {


	}

}