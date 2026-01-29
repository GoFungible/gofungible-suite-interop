// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.m.sol"; // Use .m.sol for mainnet, or .t.sol for testnet

contract DestinationContract {
    IAxelarGateway public gateway;

    IAxelarGasService public gasService;

    constructor(address _gateway, address _gasService) {
        gateway = IAxelarGateway(_gateway);
        gasService = IAxelarGasService(_gasService);
    }

    function sendMessage(
        string memory _destinationChain,
        string memory _destinationAddress,
        string memory _message
    ) external payable {
        bytes memory payload = abi.encode(_message);

        // This is the core GMP call
        gateway.callContract{value: msg.value}(
            _destinationChain,
            _destinationAddress,
            payload
        );
    }

    string public lastReceivedMessage;
    address public lastSender;
    string public lastSourceChain;

    event MessageReceived(string message, address sender, string sourceChain);

    // Axelar's `callContract` expects an `_execute` method that can be called by the gateway.
    // For more complex interactions, you might define your own public functions
    // and have `_execute` parse the payload to call those functions.
    // This function is called by the Axelar Gateway on the destination chain
    function _execute(
        bytes32 commandId,
        string memory sourceChain,
        string memory sourceAddress,
        bytes memory payload
    ) external {
        // Ensure this call comes from the Axelar Gateway
        require(msg.sender == address(gateway), "Not from Axelar Gateway");

        lastReceivedMessage = abi.decode(payload, (string));
        lastSender = address(bytes20(bytes32(bytes.concat(new bytes(12), hex"000000000000000000000000", bytes(sourceAddress))))); // Truncate sourceAddress
        lastSourceChain = sourceChain;

        emit MessageReceived(lastReceivedMessage, lastSender, lastSourceChain);
    }


}