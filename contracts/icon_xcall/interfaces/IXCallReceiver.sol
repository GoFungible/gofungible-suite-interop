// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IXCallReceiver {
	/**
	 * Handles the call message received from the source chain.
	 * Only called from the Call Message Service.
	 *
	 * @param _from The network address of the caller on the source chain
	 * @param _data The calldata delivered from the caller
	 * @param _protocols The contract addresses that delivered the data, if omitted the default protocol was used
	 */
	external handleCallMessage(String _from, byte[] _data);
	external handleCallMessage(String _from, byte[] _data, @Optional String[] _protocols);
}