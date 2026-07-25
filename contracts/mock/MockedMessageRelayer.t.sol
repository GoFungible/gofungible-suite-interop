// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../interfaces/IMessageRelayer.sol";

import "../interfaces/IMultichainToken.sol";

contract MockedMessageRelayer is IMessageRelayer {

    function sendCrosschainMessage(uint32 toChain, address toAddress, string calldata message) external override {

			emit CrosschainMessageSent(toChain, toAddress, message);

			IMultichainToken(toAddress).onCrosschainMessage(toChain, toAddress, message);

			emit CrosschainMessageReceived(toChain, toAddress, message);

		}

}