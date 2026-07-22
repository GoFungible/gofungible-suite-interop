// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/IMessageRelayer.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/token/IMultichainToken.sol";

contract MessengeRelayer is IMessageRelayer, ILayerZeroReceiver {
	
	ILayerZeroEndpoint public endpoint;

	constructor(address _endpoint) {
		endpoint = ILayerZeroEndpoint(_endpoint);
	}

	function sendCrosschainMessage(uint32 toChain, address toAddress, string calldata message) external override {

		/* interface ILayerZeroEndpoint {
				function send(
						uint16 _dstChainId,           // V1 uses 16-bit EVM-specific IDs
						bytes calldata _destination,   // Raw bytes for pathway routing
						bytes calldata _payload,       // Message data
						address payable _refundAddress,// Loose native fee refund address
						address _zroPaymentAddress,   // Dedicated ZRO token payment address
						bytes calldata _adapterParams  // Monolithic configurations (Gas, etc.)
				) external payable;
		} */

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

	// Endpoint.sol estimateFees() returns the fees for the message
	function estimateFees(
			uint16 _dstChainId,
			address _userApplication,
			bytes calldata _payload,
			bool _payInZRO,
			bytes calldata _adapterParams
	) external view returns (uint256 nativeFee, uint256 zroFee) {
		return
			endpoint.estimateFees(
					_dstChainId,
					_userApplication,
					_payload,
					_payInZRO,
					_adapterParams
			);
	}

}