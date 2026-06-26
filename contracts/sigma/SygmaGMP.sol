// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@sygma/sygma-contracts/contracts/interfaces/IGenericHandler.sol";
import "@sygma/sygma-contracts/contracts/interfaces/IBridge.sol";

/**
 * @title SygmaMessageSender
 * @dev Sends cross-chain messages via Sygma GMP
 */
contract SygmaMessageSender {
    // Sygma Bridge contract address
    address public bridge;
    
    // Domain IDs for different chains
    uint8 public constant ETHEREUM_DOMAIN_ID = 1;
    uint8 public constant POLYGON_DOMAIN_ID = 2;
    uint8 public constant BSC_DOMAIN_ID = 3;
    uint8 public constant AVALANCHE_DOMAIN_ID = 4;
    
    // Message events
    event MessageSent(
        bytes32 indexed messageId,
        uint8 destinationDomain,
        address destinationContract,
        string message,
        address sender,
        uint256 timestamp
    );
    
    event MessageStatus(
        bytes32 indexed messageId,
        bool success,
        bytes result
    );
    
    modifier onlyBridge() {
        require(msg.sender == bridge, "Only bridge can call");
        _;
    }
    
    constructor(address _bridge) {
        bridge = _bridge;
    }
    
    /**
     * @dev Send a simple cross-chain message
     * @param destinationDomain The domain ID of destination chain
     * @param destinationContract The address of contract on destination chain
     * @param message The message to send
     * @param fee The cross-chain fee
     */
    function sendCrossChainMessage(
        uint8 destinationDomain,
        address destinationContract,
        string calldata message,
        uint256 fee
    ) external payable returns (bytes32) {
        require(msg.value >= fee, "Insufficient fee");
        
        // Encode the function call for destination
        bytes memory data = abi.encodeWithSignature(
            "receiveMessage(string,address,uint8)",
            message,
            msg.sender,
            destinationDomain
        );
        
        // Prepare call data for Sygma bridge
        bytes memory callData = abi.encode(
            destinationContract, // Target contract on destination
            data                // Function call data
        );
        
        // Generate unique message ID
        bytes32 messageId = keccak256(abi.encodePacked(
            block.timestamp,
            msg.sender,
            destinationDomain,
            message
        ));
        
        // Deposit to bridge
        IBridge(bridge).deposit{value: fee}(
            destinationDomain,          // Destination domain ID
            address(this),              // Resource ID (this contract as resource)
            callData,                   // Call data
            fee                         // Fee
        );
        
        emit MessageSent(
            messageId,
            destinationDomain,
            destinationContract,
            message,
            msg.sender,
            block.timestamp
        );
        
        return messageId;
    }
    
    /**
     * @dev Send message with token transfer
     */
    function sendMessageWithTransfer(
        uint8 destinationDomain,
        address destinationContract,
        string calldata message,
        address tokenAddress,
        uint256 amount,
        uint256 fee
    ) external payable returns (bytes32) {
        require(msg.value >= fee, "Insufficient fee");
        
        // Encode transfer data
        bytes memory data = abi.encodeWithSignature(
            "receiveMessageWithTransfer(string,address,uint8,address,uint256)",
            message,
            msg.sender,
            destinationDomain,
            tokenAddress,
            amount
        );
        
        bytes memory callData = abi.encode(
            destinationContract,
            data
        );
        
        bytes32 messageId = keccak256(abi.encodePacked(
            block.timestamp,
            msg.sender,
            destinationDomain,
            message,
            amount
        ));
        
        // Transfer tokens to this contract first
        // (Assuming ERC20 token with transferFrom)
        
        IBridge(bridge).deposit{value: fee}(
            destinationDomain,
            tokenAddress,  // Resource ID for token
            callData,
            fee
        );
        
        emit MessageSent(
            messageId,
            destinationDomain,
            destinationContract,
            string(abi.encodePacked(message, " with transfer: ", amount)),
            msg.sender,
            block.timestamp
        );
        
        return messageId;
    }
    
    /**
     * @dev Batch send messages to multiple chains
     */
    function batchSendMessages(
        uint8[] calldata destinationDomains,
        address[] calldata destinationContracts,
        string[] calldata messages,
        uint256 totalFee
    ) external payable returns (bytes32[] memory) {
        require(msg.value >= totalFee, "Insufficient fee");
        require(destinationDomains.length == destinationContracts.length, "Array length mismatch");
        require(destinationContracts.length == messages.length, "Array length mismatch");
        
        bytes32[] memory messageIds = new bytes32[](destinationDomains.length);
        uint256 individualFee = totalFee / destinationDomains.length;
        
        for (uint i = 0; i < destinationDomains.length; i++) {
            bytes memory data = abi.encodeWithSignature(
                "receiveMessage(string,address,uint8)",
                messages[i],
                msg.sender,
                destinationDomains[i]
            );
            
            bytes memory callData = abi.encode(
                destinationContracts[i],
                data
            );
            
            messageIds[i] = keccak256(abi.encodePacked(
                block.timestamp,
                msg.sender,
                destinationDomains[i],
                messages[i],
                i
            ));
            
            IBridge(bridge).deposit{value: individualFee}(
                destinationDomains[i],
                address(this),
                callData,
                individualFee
            );
            
            emit MessageSent(
                messageIds[i],
                destinationDomains[i],
                destinationContracts[i],
                messages[i],
                msg.sender,
                block.timestamp
            );
        }
        
        return messageIds;
    }
    
    /**
     * @dev Handle execution results from destination chain
     */
    function handleExecutionResult(
        bytes32 messageId,
        bool success,
        bytes memory result
    ) external onlyBridge {
        emit MessageStatus(messageId, success, result);
    }
    
    // Receive funds for fees
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@sygma/sygma-contracts/contracts/interfaces/IGenericHandler.sol";

/**
 * @title SygmaMessageReceiver
 * @dev Receives cross-chain messages via Sygma GMP
 */
contract SygmaMessageReceiver {
    // Sygma Bridge contract address
    address public bridge;
    address public admin;
    
    struct CrossChainMessage {
        string message;
        address sender;
        uint8 sourceDomain;
        uint256 timestamp;
        uint256 value;
        bytes32 messageId;
        bool processed;
    }
    
    // Message tracking
    mapping(bytes32 => CrossChainMessage) public messages;
    mapping(address => bytes32[]) public userMessages;
    mapping(uint8 => uint256) public messagesPerDomain;
    
    uint256 public totalMessages;
    
    event MessageReceived(
        bytes32 indexed messageId,
        uint8 sourceDomain,
        address sender,
        string message,
        uint256 timestamp
    );
    
    event MessageProcessed(
        bytes32 indexed messageId,
        bool success,
        bytes result
    );
    
    event ResponseSent(
        bytes32 indexed originalMessageId,
        uint8 destinationDomain,
        address destinationContract,
        string response
    );
    
    modifier onlyBridge() {
        require(msg.sender == bridge, "Only bridge can call");
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call");
        _;
    }
    
    constructor(address _bridge) {
        bridge = _bridge;
        admin = msg.sender;
    }
    
    /**
     * @dev Receive cross-chain message (called by Sygma bridge)
     */
    function receiveMessage(
        string calldata _message,
        address _sender,
        uint8 _sourceDomain
    ) external onlyBridge returns (bytes memory) {
        bytes32 messageId = keccak256(abi.encodePacked(
            block.timestamp,
            _sender,
            _sourceDomain,
            _message
        ));
        
        // Store the message
        messages[messageId] = CrossChainMessage({
            message: _message,
            sender: _sender,
            sourceDomain: _sourceDomain,
            timestamp: block.timestamp,
            value: 0,
            messageId: messageId,
            processed: false
        });
        
        userMessages[_sender].push(messageId);
        messagesPerDomain[_sourceDomain]++;
        totalMessages++;
        
        emit MessageReceived(
            messageId,
            _sourceDomain,
            _sender,
            _message,
            block.timestamp
        );
        
        // Process the message and return result
        return processMessage(messageId, _message, _sender, _sourceDomain);
    }
    
    /**
     * @dev Receive message with token transfer
     */
    function receiveMessageWithTransfer(
        string calldata _message,
        address _sender,
        uint8 _sourceDomain,
        address _tokenAddress,
        uint256 _amount
    ) external onlyBridge returns (bytes memory) {
        bytes32 messageId = keccak256(abi.encodePacked(
            block.timestamp,
            _sender,
            _sourceDomain,
            _message,
            _amount
        ));
        
        messages[messageId] = CrossChainMessage({
            message: _message,
            sender: _sender,
            sourceDomain: _sourceDomain,
            timestamp: block.timestamp,
            value: _amount,
            messageId: messageId,
            processed: false
        });
        
        userMessages[_sender].push(messageId);
        messagesPerDomain[_sourceDomain]++;
        totalMessages++;
        
        emit MessageReceived(
            messageId,
            _sourceDomain,
            _sender,
            string(abi.encodePacked(_message, " with transfer: ", _amount)),
            block.timestamp
        );
        
        // Handle token transfer logic here
        // ...
        
        return processMessageWithTransfer(messageId, _message, _sender, _sourceDomain, _amount);
    }
    
    /**
     * @dev Process incoming message and return response
     */
    function processMessage(
        bytes32 _messageId,
        string calldata _message,
        address _sender,
        uint8 _sourceDomain
    ) internal returns (bytes memory) {
        // Your message processing logic here
        string memory response;
        bool success;
        
        // Example processing based on message content
        if (bytes(_message).length == 0) {
            response = "Error: Empty message";
            success = false;
        } else if (keccak256(bytes(_message)) == keccak256(bytes("GET_BALANCE"))) {
            response = string(abi.encodePacked("Balance: ", uint2str(address(this).balance)));
            success = true;
        } else if (keccak256(bytes(_message)) == keccak256(bytes("GET_TIMESTAMP"))) {
            response = string(abi.encodePacked("Timestamp: ", uint2str(block.timestamp)));
            success = true;
        } else {
            response = string(abi.encodePacked("Processed: ", _message));
            success = true;
        }
        
        // Mark as processed
        messages[_messageId].processed = true;
        
        emit MessageProcessed(_messageId, success, bytes(response));
        
        return abi.encode(success, response);
    }
    
    /**
     * @dev Process message with transfer
     */
    function processMessageWithTransfer(
        bytes32 _messageId,
        string calldata _message,
        address _sender,
        uint8 _sourceDomain,
        uint256 _amount
    ) internal returns (bytes memory) {
        // Process transfer-based message
        string memory response = string(abi.encodePacked(
            "Transfer received: ",
            uint2str(_amount),
            " for message: ",
            _message
        ));
        
        messages[_messageId].processed = true;
        
        emit MessageProcessed(_messageId, true, bytes(response));
        
        return abi.encode(true, response);
    }
    
    /**
     * @dev Send response back to source chain
     */
    function sendResponse(
        bytes32 _originalMessageId,
        uint8 _destinationDomain,
        address _destinationContract,
        string calldata _response
    ) external onlyAdmin {
        // This would initiate a new cross-chain message back to source
        // Implementation depends on your setup
        
        emit ResponseSent(
            _originalMessageId,
            _destinationDomain,
            _destinationContract,
            _response
        );
    }
    
    /**
     * @dev Get message details
     */
    function getMessage(bytes32 _messageId) external view returns (CrossChainMessage memory) {
        return messages[_messageId];
    }
    
    /**
     * @dev Get user's messages
     */
    function getUserMessages(address _user) external view returns (bytes32[] memory) {
        return userMessages[_user];
    }
    
    /**
     * @dev Get statistics
     */
    function getStats() external view returns (uint256, uint256[] memory) {
        uint256[] memory domainStats = new uint256[](5); // Assuming max 5 domains
        for (uint8 i = 1; i <= 4; i++) {
            domainStats[i] = messagesPerDomain[i];
        }
        
        return (totalMessages, domainStats);
    }
    
    // Utility function to convert uint to string
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    // Receive funds
    receive() external payable {}
}