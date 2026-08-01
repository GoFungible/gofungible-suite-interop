// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../erc-7786/IERC7786GatewaySource.sol";
import "../erc-7786/IERC7786Recipient.sol";

import {Client} from "./interfaces/Client.sol";
import "./interfaces/IAny2EVMMessageReceiver.sol";
import "./interfaces/IRouterClient.sol";
import "./interfaces/IERC20.sol";

contract MessengeRelayer is IERC7786GatewaySource, IAny2EVMMessageReceiver {

  IRouterClient private immutable i_router;
  IERC20 private immutable i_linkToken;

	constructor(address _router, address _link) {
		i_router = IRouterClient(_router);
		i_linkToken = IERC20(_link);
	}

	function sendMessage(bytes calldata recipient, bytes calldata payload, bytes[] calldata attributes) external payable returns (bytes32 sendId) {

		// Construct the CCIP message structure
		/*Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
			receiver: abi.encode(_receiver),
			data: abi.encode(_text),
			tokenAmounts: new Client.EVMTokenAmount[](0), // No tokens transferred
			extraArgs: Client._argsToBytes(
				Client.EVMExtraArgsV1({gasLimit: 200_000}) // Gas for destination execution
			),
			feeToken: address(i_linkToken) // Paying fees with LINK
		});

		// Get the calculated fee amount required by the router
		uint256 fee = i_router.getFee(_destinationChainSelector, evm2AnyMessage);

		// Ensure contract holds enough LINK to pay the fee
		uint256 balance = i_linkToken.balanceOf(address(this));
		require(balance >= fee, "Insufficient LINK balance for fees");

		// Allow router to spend LINK
		i_linkToken.forceApprove(address(i_router), fee);

		// Send the message
		i_router.ccipSend(_destinationChainSelector, evm2AnyMessage);

		emit MessageSent(_destinationChainSelector, _receiver, _text, fee);*/

	}

	// Internal function overridden to process the incoming payload
	function ccipReceive(
    Client.Any2EVMMessage calldata message
  ) external {
		/*uint64 s_lastReceivedSourceChainSelector = any2EvmMessage.sourceChainSelector;
		
		// Decode the sender address from EVM bytes format
		address s_lastReceivedSender = abi.decode(any2EvmMessage.sender, (address));
		
		// Decode the string text message payload
		string s_lastReceivedText = abi.decode(any2EvmMessage.data, (string));

		// 3. Decode the message payload
		IERC7786Recipient(fromAddress).receiveMessage(messageId, fromAddress, _message);

		// 4. Emit event
		emit CrosschainMessageReceived(s_lastReceivedSourceChainSelector, s_lastReceivedSender, s_lastReceivedText);*/
	}

}