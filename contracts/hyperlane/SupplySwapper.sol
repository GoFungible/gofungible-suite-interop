// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./interfaces/IMailbox.sol";
import "./interfaces/IMessageRecipient.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/ISupplySwapper.sol";

// Hyperlane Warp Routes
contract SupplySwapper is ISupplySwapper, IMessageRecipient {

	constructor(address _outbox, address _inbox) {
		outbox = IMailbox(_outbox);
		inbox = IMailbox(_inbox);
	}

	// *************************************************************************************************
	// ******************************************** Swap ***********************************************
	// *************************************************************************************************
	IMailbox outbox;

	function swap(uint256 destChain, address destAddress, uint256 amount) external {
		//outbox.dispatch(_destinationDomain, _recipient, bytes(_message));
		//emit SentMessage(_destinationDomain, _recipient, _message);
	}

	// *************************************************************************************************
	// ************************************** Receive Swap *********************************************
	// *************************************************************************************************
	IMailbox inbox;

	function handle(uint32 _origin, bytes32 _sender, bytes calldata _message) external payable override {
		//emit ReceivedMessage(_origin, _sender, _message);
	}

}