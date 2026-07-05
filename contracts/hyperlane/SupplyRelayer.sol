// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./interfaces/IMailbox.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/ISupplyRelayer.sol";

// Hyperlane Warp Routes
contract SupplyRelayer is ISupplyRelayer {

	constructor(address _inbox, address _outbox) {
		inbox = IMailbox(_inbox);
		outbox = IMailbox(_outbox);
	}

	IMailbox outbox;

	function onCrosschainSupply(uint256 destChain, address destAddress, uint256 amount)  external {

		//emit ReceivedMessage(_origin, _sender, _message);
	}
	event ReceivedMessage(uint32 origin, bytes32 sender, bytes message);

	IMailbox inbox;

	function sendCrosschainSupply(uint256 destChain, address destAddress, uint256 amount) external {
		//outbox.dispatch(_destinationDomain, _recipient, bytes(_message));
		//emit SentMessage(_destinationDomain, _recipient, _message);
	}
	//event SentMessage(uint32 destinationDomain, bytes32 recipient, string message);

	function registerReceiver(address _receiver) external {

	}

	function unregisterReceiver(address _receiver) external {

	}

}