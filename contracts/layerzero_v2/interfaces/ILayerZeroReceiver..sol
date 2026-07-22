// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface ILayerZeroReceiver {
	function lzReceive(
			Origin calldata _origin,     // Combines srcEid, sender bytes32, and nonce into one struct
			bytes32 _guid,               // New globally unique identifier for deterministic tracking
			bytes calldata _message,     // Message payload contents
			address _executor,           // Explicit tracking for the executing entity address
			bytes calldata _extraData    // Extensible parameter for custom protocol requirements
	) external payable;
}