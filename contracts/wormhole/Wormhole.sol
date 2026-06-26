// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "https://github.com/wormhole-foundation/wormhole/blob/main/relayer/ethereum/contracts/interfaces/relayer/IWormholeRelayer.sol";
import "https://github.com/wormhole-foundation/wormhole/blob/main/relayer/ethereum/contracts/interfaces/relayer/IWormholeReceiver.sol";

// https://github.com/wormhole-foundation/demo-wormhole-messaging/tree/main/src
contract Wormhole is IWormholeReceiver {
    IWormholeRelayer public wormholeRelayer;
    address public registrationOwner;

    // Mapping to store registered senders for each chain
    mapping(uint16 => bytes32) public registeredSenders;

    event MessageReceived(string message);
    event SourceChainLogged(uint16 sourceChain);

    constructor(address _wormholeRelayer) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
        registrationOwner = msg.sender; // Set contract deployer as the owner
    }

    // Modifier to check if the sender is registered for the source chain
    modifier isRegisteredSender(uint16 sourceChain, bytes32 sourceAddress) {
        require(registeredSenders[sourceChain] == sourceAddress, "Not registered sender");
        _;
    }

    // Function to register the valid sender address for a specific chain
    function setRegisteredSender(uint16 sourceChain, bytes32 sourceAddress) public {
        require(msg.sender == registrationOwner, "Not allowed to set registered sender");
        registeredSenders[sourceChain] = sourceAddress;
    }

    // Update receiveWormholeMessages to include the source address check
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory, // additional VAAs (optional, not needed here)
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 // delivery hash
    ) public payable override isRegisteredSender(sourceChain, sourceAddress) {
        require(msg.sender == address(wormholeRelayer), "Only the Wormhole relayer can call this function");

        // Decode the payload to extract the message
        (string memory message) = abi.decode(payload, (string));

        // Example use of sourceChain for logging
        if (sourceChain != 0) {
            emit SourceChainLogged(sourceChain);
        }

        // Emit an event with the received message
        emit MessageReceived(message);
    }

    uint256 constant GAS_LIMIT = 50000; // Adjust the gas limit as needed

		function quoteCrossChainCost(uint16 targetChain) public view returns (uint256 cost) {
        (cost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, 0, GAS_LIMIT);
    }

    function sendMessage(uint16 targetChain, address targetAddress, string memory message) external payable {
        uint256 cost = quoteCrossChainCost(targetChain); // Dynamically calculate the cross-chain cost
        require(msg.value >= cost, "Insufficient funds for cross-chain delivery");

        wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChain,
            targetAddress,
            abi.encode(message, msg.sender), // Payload contains the message and sender address
            0, // No receiver value needed
            GAS_LIMIT // Gas limit for the transaction
        );
    }
}
