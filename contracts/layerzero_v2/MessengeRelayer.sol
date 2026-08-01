// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../erc-7786/IERC7786GatewaySource.sol";
import "../erc-7786/IERC7786Recipient.sol";

import "./interfaces/ILayerZeroReceiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";

contract MessengeRelayer is IERC7786GatewaySource, ILayerZeroReceiver {
	
	ILayerZeroEndpoint public endpoint;

	constructor(address _endpoint) {
		endpoint = ILayerZeroEndpoint(_endpoint);
	}

	function sendMessage(bytes calldata recipient, bytes calldata payload, bytes[] calldata attributes) external payable returns (bytes32 sendId) {

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

		/*endpoint.send{value: msg.value}(
			toChain,
			toAddress,
			bytes(message),
			payable(msg.sender),
			address(this),
			bytes("")
		);

		emit CrosschainMessageSent(toChain, toAddress, message);*/
	}

	function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external override {
		/*require(msg.sender == address(endpoint));
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
			IERC7786Recipient(fromAddress).receiveMessage(messageId, fromAddress, _message);

		emit CrosschainMessageReceived(_srcChainId, fromAddress, string(_payload));*/

	}

}