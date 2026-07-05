// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./interfaces/IMailbox.sol";
import "./interfaces/IMessageRecipient.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/IMessageRelayer.sol";

// Hyperlane GMP
contract MessengeRelayer is IMessageRelayer {

    constructor(address _inbox, address _outbox) {
      inbox = IMailbox(_inbox);
      outbox = IMailbox(_outbox);
    }

    mapping(address => address) public receivers;

    function registerReceiver(address _receiver) external {
			receivers[_receiver] = _receiver;
		}

    function unregisterReceiver(address _receiver) external {
			delete receivers[_receiver];
		}

    IMailbox outbox;

    function sendCrosschainMessage(uint256 destChain, address destAddress, uint256 _message) external {
      //outbox.dispatch(destChain, destAddress, bytes(_message));
      //emit SentMessage(destChain, destAddress, _message);
    }
    event SentMessage(uint32 destinationDomain, bytes32 recipient, string message);

    IMailbox inbox;

    function onCrosschainMessage(uint256 destChain, address destAddress, uint256 amount) external {


      //emit ReceivedMessage(_origin, _sender, _message);
    }
    event ReceivedMessage(uint32 origin, bytes32 sender, bytes message);

}