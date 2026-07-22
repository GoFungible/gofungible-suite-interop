// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/IMessageRelayer.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/token/IMultichainToken.sol";

contract MessengeRelayer is IMessageRelayer {
	
	ILayerZeroEndpoint public endpoint;

	constructor(address _endpoint) {
		endpoint = ILayerZeroEndpoint(_endpoint);
	}

	function sendCrosschainMessage(uint32 toChain, address toAddress, string calldata message) external override {

		/*interface ILayerZeroEndpointV2 {
				function send(
						uint32 _dstEid,                // V2 replaces ChainId with global 32-bit Endpoint IDs (Eid)
						bytes32 _receiver,             // Fixed 32-byte field supporting non-EVM targets (e.g., Solana)
						bytes calldata _payload,       // Message data
						bytes calldata _options,       // Replaces _adapterParams with worker execution configs
						MessagingFee calldata _fee,    // Structured fee parameter (Native + ZRO)
						address _refundAddress         // Standard refund receiver
				) external payable returns (MessagingReceipt memory receipt); // Returns a tracking receipt struct
		}*/

		endpoint.send{value: msg.value}(
			toChain,
			toAddress,
			bytes(message),
			payable(msg.sender),
			address(this),
			bytes("")
		);

		emit CrosschainMessageSent(toChain, toAddress, message);
	}

	function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external override {
		require(msg.sender == address(endpoint));
		address fromAddress;
		assembly {
				fromAddress := mload(add(_srcAddress, 20))
		}

		if (keccak256(abi.encodePacked((_payload))) == keccak256(abi.encodePacked((bytes10("ff"))))) {
			endpoint.receivePayload(
					1,
					bytes(""),
					address(0x0),
					1,
					1,
					bytes("")
			);
		}

		emit CrosschainMessageReceived(_srcChainId, fromAddress, string(_payload));

	}

}