// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/IMessageRelayer.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/token/IMultichainToken.sol";

import "./interfaces/IMessageReceiver.sol";

contract MessengeRelayer is IMessageRelayer {
	
	immutable address public home;

	constructor(address _home) {
		home = _home;
	}

	function sendCrosschainMessage(uint32 toChain, address toAddress, string calldata message) external override {

		// cast recipient to bytes32
		bytes32 _recip = TypeCasts.addressToBytes32(_recipient);

		// dispatch your message across chains!
		home.dispatch(toChain, _recip, message);

		emit CrosschainMessageSent(toChain, _recip, message);
	}

	/*
	* @notice Receive a Hello message from any sender :) 
	* @param _origin Domain of the origin chain
	* @param _sender Address of sender on origin chain as bytes32
	* @param _message Raw bytes content of message
	*/
	function handle(
			uint32 _origin,
			uint32 _nonce,
			bytes32 _sender,
			bytes memory _message
	) onlyReplica {

			address _sendr = TypeCasts.bytes32ToAddress(_sender);

			// 3. Decode the message payload
			string memory message = string(_message);
			IMultichainToken(_sendr).onCrosschainMessage(_origin, _sendr, message);

			// 4. Emit event
			emit CrosschainMessageReceived(_origin, _sendr, message);

	}

}