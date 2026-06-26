// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@anycall/contracts/interfaces/IAnycallV6Proxy.sol";
import "@anycall/contracts/interfaces/IAnycallV6Executor.sol";

/**
 * @title AnycallMessenger
 * @dev A contract that can both send and receive cross-chain messages using Anycall V6
 * Supports: Multichain, Ethereum, BSC, Polygon, Avalanche, Fantom, etc.
 */
contract AnycallMessenger is IAnycallV6Executor {
    // Anycall proxy contract
    IAnycallV6Proxy public anycallProxy;
    
    // Contract owner
    address public owner;
    
    // Chain IDs mapping
    mapping(string => uint256) public chainIds;
    
    // Message structure
    struct CrossChainMessage {
        address sender;
        uint256 fromChain;
        uint256 toChain;
        string message;
        uint256 timestamp;
        bytes32 messageId;
        bool responded;
        string response;
    }
    
    // Message tracking
    mapping(bytes32 => CrossChainMessage) public sentMessages;
    mapping(bytes32 => CrossChainMessage) public receivedMessages;
    mapping(address => bytes32[]) public userSentMessages;
    mapping(address => bytes32[]) public userReceivedMessages;
    
    // Fallback mode for paying fees
    bool public useFallbackMode;
    
    // Events
    event MessageSent(
        bytes32 indexed messageId,
        address indexed sender,
        uint256 fromChain,
        uint256 toChain,
        string message,
        uint256 timestamp,
        uint256 fee
    );
    
    event MessageReceived(
        bytes32 indexed messageId,
        address indexed sender,
        uint256 fromChain,
        uint256 toChain,
        string message,
        uint256 timestamp
    );
    
    event ResponseSent(
        bytes32 indexed originalMessageId,
        bytes32 responseMessageId,
        string response,
        uint256 timestamp
    );
    
    event MessageResponse(
        bytes32 indexed originalMessageId,
        string response,
        uint256 timestamp
    );
    
    event FeePaid(
        bytes32 indexed messageId,
        uint256 feeAmount,
        address feePayer
    );
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }
    
    modifier onlyAnycallProxy() {
        require(msg.sender == address(anycallProxy), "Only Anycall proxy can call");
        _;
    }
    
    /**
     * @dev Constructor
     * @param _anycallProxy The Anycall V6 proxy contract address
     */
    constructor(address _anycallProxy) {
        owner = msg.sender;
        anycallProxy = IAnycallV6Proxy(_anycallProxy);
        useFallbackMode = true;
        
        // Initialize common chain IDs
        initializeChainIds();
    }
    
    /**
     * @dev Initialize common blockchain chain IDs
     */
    function initializeChainIds() internal {
        chainIds["ethereum"] = 1;
        chainIds["bsc"] = 56;
        chainIds["polygon"] = 137;
        chainIds["avalanche"] = 43114;
        chainIds["fantom"] = 250;
        chainIds["arbitrum"] = 42161;
        chainIds["optimism"] = 10;
        chainIds["base"] = 8453;
        // Add more chains as needed
    }
    
    /**
     * @dev Send a cross-chain message (caller pays fee)
     * @param toChainId Destination chain ID
     * @param destinationContract Destination contract address
     * @param message Message to send
     */
    function sendMessage(
        uint256 toChainId,
        address destinationContract,
        string calldata message
    ) external payable returns (bytes32) {
        require(bytes(message).length > 0, "Message cannot be empty");
        require(toChainId != block.chainid, "Cannot send to same chain");
        
        // Encode the function call for destination
        bytes memory callData = abi.encodeWithSignature(
            "receiveAnyMessage(uint256,address,string)",
            block.chainid, // fromChainId
            msg.sender,    // original sender
            message        // the message
        );
        
        // Generate message ID
        bytes32 messageId = generateMessageId(
            msg.sender,
            toChainId,
            message
        );
        
        // Estimate and pay fee
        uint256 fee = estimateFee(toChainId, destinationContract, callData);
        require(msg.value >= fee, "Insufficient fee");
        
        // Store sent message
        sentMessages[messageId] = CrossChainMessage({
            sender: msg.sender,
            fromChain: block.chainid,
            toChain: toChainId,
            message: message,
            timestamp: block.timestamp,
            messageId: messageId,
            responded: false,
            response: ""
        });
        
        userSentMessages[msg.sender].push(messageId);
        
        // Execute cross-chain call
        anycallProxy.anyCall{value: fee}(
            destinationContract,  // destination contract
            callData,            // calldata
            toChainId,           // destination chain ID
            2,                   // flags: 0 - pay on dest, 2 - pay on source
            ""                   // extra data (for fallback)
        );
        
        emit MessageSent(
            messageId,
            msg.sender,
            block.chainid,
            toChainId,
            message,
            block.timestamp,
            fee
        );
        
        emit FeePaid(messageId, fee, msg.sender);
        
        // Refund excess fee
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }
        
        return messageId;
    }
    
    /**
     * @dev Send message with fallback (destination pays fee)
     */
    function sendMessageWithFallback(
        uint256 toChainId,
        address destinationContract,
        string calldata message
    ) external returns (bytes32) {
        require(bytes(message).length > 0, "Message cannot be empty");
        
        bytes memory callData = abi.encodeWithSignature(
            "receiveAnyMessage(uint256,address,string)",
            block.chainid,
            msg.sender,
            message
        );
        
        bytes32 messageId = generateMessageId(
            msg.sender,
            toChainId,
            message
        );
        
        sentMessages[messageId] = CrossChainMessage({
            sender: msg.sender,
            fromChain: block.chainid,
            toChain: toChainId,
            message: message,
            timestamp: block.timestamp,
            messageId: messageId,
            responded: false,
            response: ""
        });
        
        userSentMessages[msg.sender].push(messageId);
        
        // Flags: 0 = pay on destination chain
        anycallProxy.anyCall(
            destinationContract,
            callData,
            toChainId,
            0,  // Pay on destination
            ""  // No fallback
        );
        
        emit MessageSent(
            messageId,
            msg.sender,
            block.chainid,
            toChainId,
            message,
            block.timestamp,
            0  // No fee paid on source
        );
        
        return messageId;
    }
    
    /**
     * @dev Receive cross-chain messages (called by Anycall proxy)
     * @param fromChainId Source chain ID
     * @param sender Sender address on source chain
     * @param data Encoded message data
     */
    function anyExecute(
        bytes calldata data
    ) external override onlyAnycallProxy returns (bool success, bytes memory result) {
        // Decode the incoming data
        (uint256 fromChainId, address sender, string memory message) = 
            abi.decode(data, (uint256, address, string));
        
        bytes32 messageId = generateMessageId(
            sender,
            fromChainId,
            message
        );
        
        // Store received message
        receivedMessages[messageId] = CrossChainMessage({
            sender: sender,
            fromChain: fromChainId,
            toChain: block.chainid,
            message: message,
            timestamp: block.timestamp,
            messageId: messageId,
            responded: false,
            response: ""
        });
        
        userReceivedMessages[msg.sender].push(messageId);
        
        emit MessageReceived(
            messageId,
            sender,
            fromChainId,
            block.chainid,
            message,
            block.timestamp
        );
        
        // Process the message and generate response
        string memory response = processIncomingMessage(message, sender, fromChainId);
        
        // Store response
        receivedMessages[messageId].response = response;
        
        return (true, "");
    }
    
    /**
     * @dev Process incoming message and optionally send response
     */
    function processIncomingMessage(
        string memory message,
        address sender,
        uint256 fromChainId
    ) internal returns (string memory) {
        // Example message processing logic
        if (bytes(message).length == 0) {
            return "Error: Empty message received";
        }
        
        if (keccak256(bytes(message)) == keccak256(bytes("GET_TIME"))) {
            return string(abi.encodePacked("Current timestamp: ", uint2str(block.timestamp)));
        }
        
        if (keccak256(bytes(message)) == keccak256(bytes("GET_BALANCE"))) {
            return string(abi.encodePacked("Contract balance: ", uint2str(address(this).balance)));
        }
        
        if (startsWith(message, "ECHO:")) {
            string memory echoMessage = substring(message, 5, bytes(message).length);
            return string(abi.encodePacked("Echo: ", echoMessage));
        }
        
        return string(abi.encodePacked("Processed: ", message));
    }
    
    /**
     * @dev Send response back to original chain
     */
    function sendResponse(
        bytes32 originalMessageId,
        uint256 toChainId,
        address destinationContract,
        string calldata response
    ) external payable returns (bytes32) {
        CrossChainMessage storage originalMessage = receivedMessages[originalMessageId];
        require(originalMessage.sender != address(0), "Original message not found");
        require(!originalMessage.responded, "Already responded");
        
        bytes memory callData = abi.encodeWithSignature(
            "receiveResponse(bytes32,string)",
            originalMessageId,
            response
        );
        
        bytes32 responseMessageId = generateMessageId(
            msg.sender,
            toChainId,
            response
        );
        
        uint256 fee = estimateFee(toChainId, destinationContract, callData);
        require(msg.value >= fee, "Insufficient fee");
        
        // Mark original message as responded
        originalMessage.responded = true;
        originalMessage.response = response;
        
        anycallProxy.anyCall{value: fee}(
            destinationContract,
            callData,
            toChainId,
            2,  // Pay on source
            ""
        );
        
        emit ResponseSent(
            originalMessageId,
            responseMessageId,
            response,
            block.timestamp
        );
        
        return responseMessageId;
    }
    
    /**
     * @dev Receive response from destination chain
     */
    function receiveResponse(
        bytes32 originalMessageId,
        string calldata response
    ) external onlyAnycallProxy {
        CrossChainMessage storage originalMessage = sentMessages[originalMessageId];
        require(originalMessage.sender != address(0), "Original message not found");
        
        originalMessage.responded = true;
        originalMessage.response = response;
        
        emit MessageResponse(
            originalMessageId,
            response,
            block.timestamp
        );
    }
    
    /**
     * @dev Estimate cross-chain fee
     */
    function estimateFee(
        uint256 toChainId,
        address destinationContract,
        bytes memory callData
    ) public view returns (uint256) {
        // This is a simplified estimation
        // In production, you might want to use Anycall's fee estimation
        uint256 baseFee = 0.001 ether; // Base fee
        uint256 dataFee = (callData.length * 10) * 1 gwei; // Data size fee
        
        return baseFee + dataFee;
    }
    
    /**
     * @dev Generate unique message ID
     */
    function generateMessageId(
        address sender,
        uint256 chainId,
        string memory message
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            sender,
            chainId,
            block.timestamp,
            message,
            block.prevrandao
        ));
    }
    
    /**
     * @dev Get sent message details
     */
    function getSentMessage(bytes32 messageId) external view returns (CrossChainMessage memory) {
        return sentMessages[messageId];
    }
    
    /**
     * @dev Get received message details
     */
    function getReceivedMessage(bytes32 messageId) external view returns (CrossChainMessage memory) {
        return receivedMessages[messageId];
    }
    
    /**
     * @dev Get user's sent messages
     */
    function getUserSentMessages(address user) external view returns (bytes32[] memory) {
        return userSentMessages[user];
    }
    
    /**
     * @dev Get user's received messages
     */
    function getUserReceivedMessages(address user) external view returns (bytes32[] memory) {
        return userReceivedMessages[user];
    }
    
    /**
     * @dev Set Anycall proxy address
     */
    function setAnycallProxy(address newProxy) external onlyOwner {
        anycallProxy = IAnycallV6Proxy(newProxy);
    }
    
    /**
     * @dev Set fallback mode
     */
    function setFallbackMode(bool useFallback) external onlyOwner {
        useFallbackMode = useFallback;
    }
    
    /**
     * @dev Withdraw contract funds
     */
    function withdrawFunds(address payable to, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        to.transfer(amount);
    }
    
    // Utility functions
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
    
    function startsWith(string memory str, string memory prefix) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory prefixBytes = bytes(prefix);
        if (strBytes.length < prefixBytes.length) return false;
        for (uint i = 0; i < prefixBytes.length; i++) {
            if (strBytes[i] != prefixBytes[i]) return false;
        }
        return true;
    }
    
    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
    
    // Receive ether
    receive() external payable {}
}