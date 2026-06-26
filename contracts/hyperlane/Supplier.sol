// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./interfaces/IMailbox.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/ISupplyRelayer.sol";

// Hyperlane Warp Routes
contract Supplier {

	constructor(address _inbox, address _outbox) {
		inbox = IMailbox(_inbox);
		outbox = IMailbox(_outbox);
	}

	IMailbox outbox;

	function handle(uint32 _origin, bytes32 _sender, bytes calldata _message) external payable {

		emit ReceivedMessage(_origin, _sender, _message);
	}
	event ReceivedMessage(uint32 origin, bytes32 sender, bytes message);

	IMailbox inbox;

	function sendMoney(uint32 _destinationDomain, bytes32 _recipient) external {
		//outbox.dispatch(_destinationDomain, _recipient, bytes(_message));
		//emit SentMessage(_destinationDomain, _recipient, _message);
	}
	//event SentMessage(uint32 destinationDomain, bytes32 recipient, string message);

}