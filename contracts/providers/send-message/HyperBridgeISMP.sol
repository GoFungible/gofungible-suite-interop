// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Import ISMP interfaces
interface IIsmp {
    struct PostRequest {
        bytes source;
        bytes dest;
        uint64 nonce;
        uint64 timeoutTimestamp;
        bytes data;
        bytes from;
    }
    
    struct PostResponse {
        bytes source;
        bytes dest;
        uint64 nonce;
        uint64 timeoutTimestamp;
        bytes data;
        bytes from;
        bytes request;
    }
    
    function post(PostRequest memory request) external payable;
    function postResponse(PostResponse memory response) external payable;
}

interface IIsmpHost {
    function dispatchPost(
        bytes memory dest,
        bytes memory body,
        uint64 timeout
    ) external payable returns (bytes32);
    
    function dispatchGet(
        bytes memory dest,
        bytes memory keys,
        uint64 timeout
    ) external payable returns (bytes32);
}

// ISMP Events
interface IIsmpEvents {
    event PostRequestEvent(
        bytes32 indexed request,
        bytes source,
        bytes dest,
        uint64 nonce,
        uint64 timeoutTimestamp,
        bytes data,
        bytes from
    );
    
    event PostResponseEvent(
        bytes32 indexed response,
        bytes source,
        bytes dest,
        uint64 nonce,
        uint64 timeoutTimestamp,
        bytes data,
        bytes from,
        bytes request
    );
}

/**
 * @title CrossChainMessenger
 * @dev A contract for sending and receiving cross-chain messages via Hyperbridge ISMP
 */
contract CrossChainMessenger is IIsmpEvents {
    // ISMP host contract address
    address public immutable ismpHost;
    
    // Message nonce counter
    uint64 private _nonce;
    
    // Mapping to track pending requests
    mapping(bytes32 => bool) public pendingRequests;
    mapping(bytes32 => bool) public pendingResponses;
    
    // Message structures
    struct CrossChainMessage {
        bytes32 messageId;
        address sender;
        bytes destination;
        bytes payload;
        uint64 timestamp;
        bool responded;
    }
    
    // Storage for sent messages
    mapping(bytes32 => CrossChainMessage) public sentMessages;
    mapping(bytes32 => bytes) public receivedMessages;
    
    // Events
    event MessageSent(
        bytes32 indexed messageId,
        address indexed sender,
        bytes destination,
        bytes payload,
        uint64 nonce
    );
    
    event MessageReceived(
        bytes32 indexed messageId,
        bytes source,
        bytes payload,
        address receiver
    );
    
    event ResponseReceived(
        bytes32 indexed requestId,
        bytes32 indexed responseId,
        bytes payload
    );
    
    // Errors
    error OnlyIsmpHost();
    error InvalidDestination();
    error MessageAlreadyProcessed();
    error InsufficientFee();
    
    /**
     * @dev Constructor
     * @param _ismpHost The address of the ISMP host contract
     */
    constructor(address _ismpHost) {
        ismpHost = _ismpHost;
        _nonce = 0;
    }
    
    /**
     * @dev Modifier to restrict access to only the ISMP host
     */
    modifier onlyIsmpHost() {
        if (msg.sender != ismpHost) {
            revert OnlyIsmpHost();
        }
        _;
    }
    
    /**
     * @dev Send a cross-chain message
     * @param destination The destination chain identifier
     * @param payload The message payload
     * @param timeout Timeout in seconds for the message
     */
    function sendMessage(
        bytes memory destination,
        bytes memory payload,
        uint64 timeout
    ) external payable returns (bytes32) {
        if (destination.length == 0) {
            revert InvalidDestination();
        }
        
        // Dispatch post request through ISMP host
        bytes32 messageId = IIsmpHost(ismpHost).dispatchPost{value: msg.value}(
            destination,
            abi.encode(msg.sender, payload),
            timeout
        );
        
        // Store sent message
        sentMessages[messageId] = CrossChainMessage({
            messageId: messageId,
            sender: msg.sender,
            destination: destination,
            payload: payload,
            timestamp: uint64(block.timestamp),
            responded: false
        });
        
        pendingRequests[messageId] = true;
        
        emit MessageSent(
            messageId,
            msg.sender,
            destination,
            payload,
            _nonce++
        );
        
        return messageId;
    }
    
    /**
     * @dev Handle incoming POST requests from other chains
     * @param request The ISMP post request
     */
    function onPostRequest(IIsmp.PostRequest memory request) 
        external 
        onlyIsmpHost 
        returns (bytes memory) 
    {
        bytes32 requestId = keccak256(abi.encode(request));
        
        if (pendingRequests[requestId]) {
            revert MessageAlreadyProcessed();
        }
        
        // Decode the payload (assuming it contains sender and actual payload)
        (address sender, bytes memory payload) = abi.decode(request.data, (address, bytes));
        
        // Store received message
        receivedMessages[requestId] = payload;
        pendingRequests[requestId] = true;
        
        emit MessageReceived(
            requestId,
            request.source,
            payload,
            address(this)
        );
        
        // You can add custom logic here to process the incoming message
        _processIncomingMessage(requestId, sender, payload);
        
        // Return empty response or custom response data
        return "";
    }
    
    /**
     * @dev Handle incoming POST responses
     * @param response The ISMP post response
     */
    function onPostResponse(IIsmp.PostResponse memory response) 
        external 
        onlyIsmpHost 
    {
        bytes32 responseId = keccak256(abi.encode(response));
        bytes32 requestId = keccak256(response.request);
        
        if (pendingResponses[responseId]) {
            revert MessageAlreadyProcessed();
        }
        
        // Mark the original request as responded
        if (sentMessages[requestId].messageId != bytes32(0)) {
            sentMessages[requestId].responded = true;
        }
        
        pendingResponses[responseId] = true;
        
        emit ResponseReceived(
            requestId,
            responseId,
            response.data
        );
        
        // Process the response
        _processResponse(requestId, responseId, response.data);
    }
    
    /**
     * @dev Handle incoming GET requests (if needed)
     */
    function onGetRequest(bytes memory source, bytes memory keys) 
        external 
        onlyIsmpHost 
        returns (bytes memory) 
    {
        // Implement GET request handling if needed
        // This would typically return state data
        
        return abi.encode(block.timestamp, block.number);
    }
    
    /**
     * @dev Send a response to a received message
     * @param requestId The original request ID
     * @param responsePayload The response payload
     * @param timeout Timeout for the response
     */
    function sendResponse(
        bytes32 requestId,
        bytes memory responsePayload,
        uint64 timeout
    ) external payable returns (bytes32) {
        // In a real implementation, you would need to store the original request
        // to be able to send a response back to the source chain
        
        // This is a simplified implementation
        bytes32 responseId = keccak256(abi.encode(requestId, responsePayload, block.timestamp));
        
        emit ResponseReceived(
            requestId,
            responseId,
            responsePayload
        );
        
        return responseId;
    }
    
    /**
     * @dev Process incoming message (override for custom logic)
     */
    function _processIncomingMessage(
        bytes32 messageId,
        address sender,
        bytes memory payload
    ) internal virtual {
        // Override this function to implement custom message processing logic
        // Example: update state, mint tokens, execute functions, etc.
        
        // Example implementation:
        // if (bytes4(payload) == this.someFunction.selector) {
        //     (uint256 param1, address param2) = abi.decode(payload[4:], (uint256, address));
        //     someFunction(param1, param2);
        // }
    }
    
    /**
     * @dev Process response (override for custom logic)
     */
    function _processResponse(
        bytes32 requestId,
        bytes32 responseId,
        bytes memory responseData
    ) internal virtual {
        // Override this function to implement custom response processing logic
    }
    
    /**
     * @dev Get message status
     */
    function getMessageStatus(bytes32 messageId) 
        external 
        view 
        returns (bool exists, bool responded, address sender) 
    {
        CrossChainMessage memory message = sentMessages[messageId];
        return (
            message.messageId != bytes32(0),
            message.responded,
            message.sender
        );
    }
    
    /**
     * @dev Get received message
     */
    function getReceivedMessage(bytes32 messageId) 
        external 
        view 
        returns (bytes memory payload) 
    {
        return receivedMessages[messageId];
    }
    
    /**
     * @dev Get current nonce
     */
    function getCurrentNonce() external view returns (uint64) {
        return _nonce;
    }
    
    /**
     * @dev Receive function to accept native tokens for fees
     */
    receive() external payable {}
}

/**
 * @title ExampleUsage
 * @dev Example contract demonstrating how to use the CrossChainMessenger
 */
contract ExampleUsage is CrossChainMessenger {
    // Custom events
    event TokenBridged(address indexed user, uint256 amount, bytes destination);
    event DataReceived(bytes32 indexed messageId, bytes data);
    
    constructor(address ismpHost) CrossChainMessenger(ismpHost) {}
    
    /**
     * @dev Example function to bridge tokens
     */
    function bridgeTokens(
        bytes memory destination,
        uint256 amount,
        uint64 timeout
    ) external payable returns (bytes32) {
        // Encode the bridge data
        bytes memory payload = abi.encodeWithSignature(
            "receiveTokens(address,uint256)",
            msg.sender,
            amount
        );
        
        // Send cross-chain message
        bytes32 messageId = sendMessage{value: msg.value}(
            destination,
            payload,
            timeout
        );
        
        emit TokenBridged(msg.sender, amount, destination);
        
        return messageId;
    }
    
    /**
     * @dev Override to process incoming messages
     */
    function _processIncomingMessage(
        bytes32 messageId,
        address sender,
        bytes memory payload
    ) internal override {
        // Decode and process the function call
        (bool success, ) = address(this).call(payload);
        require(success, "Message processing failed");
        
        emit DataReceived(messageId, payload);
    }
    
    /**
     * @dev Function that can be called from other chains
     */
    function receiveTokens(address user, uint256 amount) external {
        // This function would typically mint tokens or update balances
        // Example: IERC20(token).mint(user, amount);
        
        // For demonstration, we just emit an event
        emit TokenBridged(user, amount, abi.encodePacked(block.chainid));
    }
}