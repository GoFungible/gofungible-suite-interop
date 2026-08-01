// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../erc-7786/IERC7786GatewaySource.sol";
import "../erc-7786/IERC7786Recipient.sol";

import "./interfaces/IGmpTransferAdapter.sol";

contract MessengeRelayer is IERC7786GatewaySource, IGmpTransferAdapter {
	
	address public bridgeAddress;

	constructor(address _bridge) {
		bridgeAddress = _bridge;
	}

	function sendMessage(bytes calldata recipient, bytes calldata payload, bytes[] calldata attributes) external payable returns (bytes32 sendId) {

		/*

		bytes memory executionData = abi.encode(textPayload, targetRecipient);
		bytes memory depositData = abi.encode(executionData.length, executionData);

		// Interact directly with the real Sygma router instance
		IBridge(bridgeAddress).deposit{value: msg.value}(
			toChain,
			bytes32(toAddress),
			depositData
		);

		emit CrosschainMessageSent(toChain, bytes32(toAddress), depositData);
		*/

	}

	function deposit(
			uint8 destinationDomainID,
			address recipientAddress,
			address XERC20Address,
			uint256 tokenAmount
	) external payable {

	}

	function executeProposal(
			address gmpAdapter,
			address recipient,
			address XERC20Address,
			uint256 amount
	) external {

	}

	/**
	 * @notice Native callback entrypoint mandated by Sygma's bridge architecture.
	 */
	function executeProposal(bytes calldata data) external returns (bytes memory) {
		// Enforce that only the authorized Sygma Bridge Relayer Relayer can call this
		/*require(msg.sender == bridgeAddress, "Unauthorized: Not Sygma Handler");

		// Unpack the byte payload sent from the source contract
		(string memory text, address userAddress) = abi.decode(data, (string, address));

					IERC7786Recipient(fromAddress).receiveMessage(messageId, fromAddress, _message);


		return "";*/
	}

}