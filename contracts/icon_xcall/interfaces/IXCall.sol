// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IXCall {
	/**
	 * Sends a call message to the contract on the destination chain.
	 *
	 * @param _to The network address of the callee on the destination chain
	 * @param _data The calldata specific to the target contract. Max 2048KB
	 * @param _rollback (Optional) Data used to specify error handling of a two-way messages. Max 1024KB
	 * @param _sources  (Optional) The contracts that will be used to send the message
	 * @param _destinations (Optional) The addresses of the contracts that xcall will expect the message from.
	 *
	 * @return The serial number of the request
	 */
	payable external sendCallMessage(String _to,
																	byte[] _data,
																	@Optional bytes _rollback,
																	@Optional String[] _sources
																	@Optional String[] _destinations) return Integer;
}