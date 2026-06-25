// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title MockTargetContract
 * @dev A mock target contract for receiving relayed messages
 */
contract MockTargetContract {
    mapping(uint256 => bool) public processedMessages;
    mapping(address => uint256) public messageCount;
    
    event MessageReceived(
        uint256 indexed messageId,
        address indexed sender,
        bytes payload,
        address relayer
    );
    
    /**
     * @dev Handle a relayed message
     * @param messageId ID of message
     * @param sender Original sender
     * @param payload Message payload
     */
    function handleRelayedMessage(
        uint256 messageId,
        address sender,
        bytes calldata payload
    ) 
        external 
        returns (bool)
    {
        require(!processedMessages[messageId], "Message already processed");
        
        processedMessages[messageId] = true;
        messageCount[sender]++;
        
        emit MessageReceived(messageId, sender, payload, msg.sender);
        
        // Simulate some processing
        return true;
    }
}