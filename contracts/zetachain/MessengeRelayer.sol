// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../erc-7786/IERC7786GatewaySource.sol";
import "../erc-7786/IERC7786Recipient.sol";

import "./interfaces/ZetaMPI.sol";
import "./interfaces/ZetaInterfaces.sol";

contract MessengeRelayer is IERC7786GatewaySource {
	
	ZetaMPI public zeta;

	constructor(address _zeta) {
		zeta = ZetaMPI(_zeta);
	}

	function sendMessage(bytes calldata recipient, bytes calldata payload, bytes[] calldata attributes) external payable returns (bytes32 sendId) {

/*

		zeta.send(
			ZetaInterfaces.SendInput({
					destinationChainId: _crossChainId,
					destinationAddress: _crossChainAddress,
					gasLimit: 2500000,
					message: abi.encode(CROSS_CHAIN_MESSAGE, msg.sender),
					zetaAmount: 0,
					zetaParams: abi.encode("")
			})
		);

		emit CrosschainMessageSent(toChain, toAddress, message);
		*/

	}

	function onZetaMessage(ZetaInterfaces.ZetaMessage calldata _zetaMessage) external { 

/*

		// 3. Decode the message payload
		string memory message = string(_message);
					IERC7786Recipient(fromAddress).receiveMessage(messageId, fromAddress, _message);

		// 4. Emit event
		emit CrosschainMessageReceived(_origin, fromAddress, message);
		*/
	}

}