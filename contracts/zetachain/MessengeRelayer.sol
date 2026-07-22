// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/IMessageRelayer.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/token/IMultichainToken.sol";

import "./interfaces/ZetaMPI.sol";

contract MessengeRelayer is IMessageRelayer {
	
	ZetaMPI public zeta;

	constructor(address _zeta) {
		zeta = ZetaMPI(_zeta);
	}

	function sendCrosschainMessage(uint32 toChain, address toAddress, string calldata message) external override {

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

	}

	function onZetaMessage(ZetaInterfaces.ZetaMessage calldata _zetaMessage) external { 



		// 3. Decode the message payload
		string memory message = string(_message);
		IMultichainToken(fromAddress).onCrosschainMessage(_origin, fromAddress, message);

		// 4. Emit event
		emit CrosschainMessageReceived(_origin, fromAddress, message);
	}

}