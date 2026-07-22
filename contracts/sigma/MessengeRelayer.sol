// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/IMessageRelayer.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/token/IMultichainToken.sol";

import "./interfaces/IGmpTransferAdapter.sol";

contract MessengeRelayer is IMessageRelayer, IGmpTransferAdapter {
	
	address public bridgeAddress;

	constructor(address _bridge) {
		bridgeAddress = _bridge;
	}

	function sendCrosschainMessage(uint32 toChain, address toAddress, string calldata message) external override {

		bytes memory executionData = abi.encode(textPayload, targetRecipient);
		bytes memory depositData = abi.encode(executionData.length, executionData);

		// Interact directly with the real Sygma router instance
		IBridge(bridgeAddress).deposit{value: msg.value}(
			toChain,
			bytes32(toAddress),
			depositData
		);

		emit CrosschainMessageSent(toChain, bytes32(toAddress), depositData);

	}

	/**
	 * @notice Native callback entrypoint mandated by Sygma's bridge architecture.
	 */
	function executeProposal(bytes calldata data) external returns (bytes memory) {
		// Enforce that only the authorized Sygma Bridge Relayer Relayer can call this
		require(msg.sender == bridgeAddress, "Unauthorized: Not Sygma Handler");

		// Unpack the byte payload sent from the source contract
		(string memory text, address userAddress) = abi.decode(data, (string, address));

		

		return "";
	}

}