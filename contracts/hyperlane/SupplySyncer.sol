// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./interfaces/IMailbox.sol";
import "./interfaces/IMessageRecipient.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/ISupplySyncer.sol";

// Hyperlane Warp Routes
contract SupplySyncer is ISupplySyncer, IMessageRecipient {

	constructor(address _outbox, address _inbox) {
		outbox = IMailbox(_outbox);
		inbox = IMailbox(_inbox);
	}

	// *************************************************************************************************
	// **************************************** Sync Supply ********************************************
	// *************************************************************************************************
	IMailbox outbox;

	function syncSupplies(uint256 onChain, address onAddress, uint256 fromChain, uint256 toChain, uint256 amount, bytes32 checksum) external {
		//outbox.dispatch(_destinationDomain, _recipient, bytes(_message));
		//emit SentMessage(_destinationDomain, _recipient, _message);
	}

	// *************************************************************************************************
	// *********************************** Receive Sync Supply *****************************************
	// *************************************************************************************************
	IMailbox inbox;

	function handle(uint32 _origin, bytes32 _sender, bytes calldata _message) external payable override {
		//emit ReceivedMessage(_origin, _sender, _message);
	}

}