// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IXCallReceiver {


	function handleCallMessage(string memory _from, bytes[]memory _data) external;

	/**
	 * Handles the call message received from the source chain.
	 * Only called from the Call Message Service.
	 *
	 * @param _from The network address of the caller on the source chain
	 * @param _data The calldata delivered from the caller
	 * @param _protocols The contract addresses that delivered the data, if omitted the default protocol was used
	 */
	function handleCallMessage(string memory _from, bytes[] memory _data, string[] memory _protocols) external;
}