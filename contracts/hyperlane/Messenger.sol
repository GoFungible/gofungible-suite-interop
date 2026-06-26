// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IMailbox.sol";

// Hyperlane GMP
contract Messenger is IMessageRecipient, IMessenger {

    constructor(address _inbox, address _outbox) {
      inbox = IMailbox(_inbox);
      outbox = IMailbox(_outbox);
    }

    mapping(address => uint256) public receivers;

    function registerReceiver(address _receiver) external {
			receiver[_receiver] = _receiver;
		}

    function unregisterReceiver(address _receiver) external {
			delete receiver[_receiver];
		}

    IMailbox outbox;

    function sendMessage(uint32 _destinationDomain, bytes32 _recipient, string calldata _message) external {
      outbox.dispatch(_destinationDomain, _recipient, bytes(_message));
      emit SentMessage(_destinationDomain, _recipient, _message);
    }
    event SentMessage(uint32 destinationDomain, bytes32 recipient, string message);

    IMailbox inbox;

    function handle(uint32 _origin, bytes32 _sender, bytes calldata _message) external {


      emit ReceivedMessage(_origin, _sender, _message);
    }
    event ReceivedMessage(uint32 origin, bytes32 sender, bytes message);

}