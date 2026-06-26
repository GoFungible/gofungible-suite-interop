// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title MockedRelayer
 * @dev A mock implementation of a cross-chain relayer for testing purposes
 * Simulates message passing between different chains with gas payment and confirmation
 */
contract MockedRelayer {
    // ---------- Errors ----------
    error Relayer__NotRelayer();
    error Relayer__NotOwner();
    error Relayer__MessageAlreadyDelivered();
    error Relayer__MessageNotFound();
    error Relayer__InsufficientFee();
    error Relayer__RelayFailed();
    error Relayer__InvalidChainId();
    error Relayer__ExpiredMessage();
    error Relayer__UnauthorizedSender();

    // ---------- State Variables ----------
    address private immutable i_owner;
    address public relayer;
    
    uint256 public constant MAX_RETRY = 3;
    uint256 public constant GAS_LIMIT = 1_000_000;
    uint256 public constant RELAYER_FEE = 0.01 ether;
    uint256 public constant MESSAGE_EXPIRY = 1 hours;
    
    uint256 public messageCounter;
    mapping(uint256 => Message) public messages;
    mapping(bytes32 => bool) public deliveredMessages;
    mapping(address => bool) public authorizedSenders;
    
    // Chain configuration
    uint256 public sourceChainId;
    uint256 public destinationChainId;
    
    // ---------- Events ----------
    event MessageSent(
        uint256 indexed messageId,
        address indexed sender,
        address indexed recipient,
        bytes payload,
        uint256 timestamp,
        uint256 fee
    );
    
    event MessageDelivered(
        uint256 indexed messageId,
        address indexed relayer,
        bytes32 txHash,
        uint256 gasUsed,
        uint256 timestamp
    );
    
    event MessageFailed(
        uint256 indexed messageId,
        string reason,
        uint256 retryCount
    );
    
    event MessageReverted(
        uint256 indexed messageId,
        bytes revertData
    );
    
    event RelayerUpdated(address indexed oldRelayer, address indexed newRelayer);
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event SenderAuthorized(address indexed sender, bool authorized);

    // ---------- Structures ----------
    struct Message {
        uint256 id;
        address sender;
        address recipient;
        bytes payload;
        uint256 timestamp;
        uint256 fee;
        uint8 retryCount;
        MessageStatus status;
        bytes32 txHash;
        uint256 gasUsed;
        bytes revertData;
    }
    
    enum MessageStatus {
        Pending,
        Relaying,
        Confirmed,
        Failed,
        Reverted
    }

    // ---------- Modifiers ----------
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert Relayer__NotOwner();
        _;
    }
    
    modifier onlyRelayer() {
        if (msg.sender != relayer) revert Relayer__NotRelayer();
        _;
    }
    
    modifier onlyAuthorizedSender() {
        if (!authorizedSenders[msg.sender]) revert Relayer__UnauthorizedSender();
        _;
    }

    // ---------- Constructor ----------
    constructor(
        uint256 _sourceChainId,
        uint256 _destinationChainId,
        address _relayer
    ) {
        i_owner = msg.sender;
        sourceChainId = _sourceChainId;
        destinationChainId = _destinationChainId;
        relayer = _relayer;
        authorizedSenders[msg.sender] = true;
    }

    // ---------- External Functions ----------
    
    /**
     * @dev Send a message to the destination chain
     * @param recipient Address on destination chain
     * @param payload Message payload
     */
    function sendMessage(address recipient, bytes calldata payload) 
        external 
        payable 
        onlyAuthorizedSender 
        returns (uint256 messageId)
    {
        if (msg.value < RELAYER_FEE) revert Relayer__InsufficientFee();
        if (recipient == address(0)) revert Relayer__InvalidChainId();
        
        messageId = ++messageCounter;
        
        Message storage newMessage = messages[messageId];
        newMessage.id = messageId;
        newMessage.sender = msg.sender;
        newMessage.recipient = recipient;
        newMessage.payload = payload;
        newMessage.timestamp = block.timestamp;
        newMessage.fee = msg.value;
        newMessage.status = MessageStatus.Pending;
        newMessage.retryCount = 0;
        
        emit MessageSent(
            messageId,
            msg.sender,
            recipient,
            payload,
            block.timestamp,
            msg.value
        );
        
        // Return excess ether if any
        if (msg.value > RELAYER_FEE) {
            uint256 refund = msg.value - RELAYER_FEE;
            payable(msg.sender).transfer(refund);
        }
    }

    /**
     * @dev Relay a message to the destination chain
     * @param messageId ID of message to relay
     */
    function relayMessage(uint256 messageId) 
        external 
        onlyRelayer 
        returns (bool success)
    {
        Message storage message = messages[messageId];
        
        // Validate message
        if (message.id == 0) revert Relayer__MessageNotFound();
        if (message.status != MessageStatus.Pending) revert Relayer__MessageAlreadyDelivered();
        if (block.timestamp > message.timestamp + MESSAGE_EXPIRY) revert Relayer__ExpiredMessage();
        
        bytes32 messageHash = keccak256(
            abi.encode(
                message.id,
                message.sender,
                message.recipient,
                message.payload,
                sourceChainId,
                destinationChainId
            )
        );
        
        // Check if already delivered
        if (deliveredMessages[messageHash]) revert Relayer__MessageAlreadyDelivered();
        
        // Update status to relaying
        message.status = MessageStatus.Relaying;
        
        // Simulate relay execution with random outcome
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, messageId))) % 100;
        
        // 80% success, 15% fail, 5% revert
        if (random < 80) {
            // Success
            success = true;
            message.status = MessageStatus.Confirmed;
            message.txHash = keccak256(
                abi.encodePacked(
                    block.timestamp,
                    messageId,
                    block.coinbase
                )
            );
            message.gasUsed = 50000 + (random % 50000);
            
            deliveredMessages[messageHash] = true;
            
            emit MessageDelivered(
                messageId,
                msg.sender,
                message.txHash,
                message.gasUsed,
                block.timestamp
            );
            
        } else if (random < 95) {
            // Failure - retryable
            success = false;
            message.retryCount++;
            
            if (message.retryCount >= MAX_RETRY) {
                message.status = MessageStatus.Failed;
            } else {
                message.status = MessageStatus.Pending; // Reset for retry
            }
            
            emit MessageFailed(
                messageId,
                "Relay execution failed",
                message.retryCount
            );
            
        } else {
            // Revert - permanent failure
            success = false;
            message.status = MessageStatus.Reverted;
            message.revertData = abi.encodeWithSignature(
                "CustomError(string)",
                "Reverted by destination chain"
            );
            
            emit MessageReverted(messageId, message.revertData);
        }
        
        return success;
    }

    /**
     * @dev Retry a failed message
     * @param messageId ID of message to retry
     */
    function retryMessage(uint256 messageId) 
        external 
        onlyRelayer 
    {
        Message storage message = messages[messageId];
        
        if (message.id == 0) revert Relayer__MessageNotFound();
        if (message.status != MessageStatus.Failed) revert Relayer__MessageAlreadyDelivered();
        if (message.retryCount >= MAX_RETRY) revert Relayer__RelayFailed();
        
        // Reset status for retry
        message.status = MessageStatus.Pending;
        
        // Retry the message
        this.relayMessage(messageId);
    }

    /**
     * @dev Simulate delivering a message from source chain
     * @param messageId ID of message to deliver
     * @param targetAddress Target contract on destination chain
     */
    function deliverMessageMock(
        uint256 messageId,
        address targetAddress
    ) 
        external 
        onlyRelayer 
        returns (bool)
    {
        Message storage message = messages[messageId];
        
        if (message.id == 0) revert Relayer__MessageNotFound();
        if (message.status != MessageStatus.Confirmed) revert Relayer__MessageNotFound();
        
        // Simulate delivering to target contract
        (bool success, bytes memory data) = targetAddress.call(
            abi.encodeWithSignature(
                "handleRelayedMessage(uint256,address,bytes)",
                messageId,
                message.sender,
                message.payload
            )
        );
        
        if (success) {
            emit MessageDelivered(
                messageId,
                msg.sender,
                keccak256(abi.encodePacked(block.timestamp, messageId)),
                gasleft(),
                block.timestamp
            );
        } else {
            // Handle failure
            message.status = MessageStatus.Reverted;
            message.revertData = data;
            emit MessageReverted(messageId, data);
        }
        
        return success;
    }

    /**
     * @dev Cancel a pending message
     * @param messageId ID of message to cancel
     */
    function cancelMessage(uint256 messageId) 
        external 
        onlyRelayer 
    {
        Message storage message = messages[messageId];
        
        if (message.id == 0) revert Relayer__MessageNotFound();
        if (message.status != MessageStatus.Pending) revert Relayer__MessageAlreadyDelivered();
        
        // Refund the fee
        payable(message.sender).transfer(message.fee);
        
        message.status = MessageStatus.Reverted;
        message.revertData = abi.encodeWithSignature(
            "Cancelled(address)",
            msg.sender
        );
        
        emit MessageReverted(messageId, message.revertData);
    }

    // ---------- Admin Functions ----------
    
    /**
     * @dev Update the relayer address
     * @param _newRelayer New relayer address
     */
    function updateRelayer(address _newRelayer) 
        external 
        onlyOwner 
    {
        address oldRelayer = relayer;
        relayer = _newRelayer;
        emit RelayerUpdated(oldRelayer, _newRelayer);
    }

    /**
     * @dev Update relayer fee
     * @param _newFee New fee in wei
     */
    function updateFee(uint256 _newFee) 
        external 
        onlyOwner 
    {
        uint256 oldFee = RELAYER_FEE;
        emit FeeUpdated(oldFee, _newFee);
    }

    /**
     * @dev Authorize a sender
     * @param _sender Address to authorize
     * @param _authorized Authorization status
     */
    function authorizeSender(address _sender, bool _authorized) 
        external 
        onlyOwner 
    {
        authorizedSenders[_sender] = _authorized;
        emit SenderAuthorized(_sender, _authorized);
    }

    /**
     * @dev Withdraw accumulated fees
     * @param _to Address to withdraw to
     */
    function withdrawFees(address payable _to) 
        external 
        onlyOwner 
    {
        uint256 balance = address(this).balance;
        _to.transfer(balance);
    }

    // ---------- View/Pure Functions ----------
    
    /**
     * @dev Get message details
     * @param messageId ID of message
     */
    function getMessage(uint256 messageId) 
        external 
        view 
        returns (
            uint256 id,
            address sender,
            address recipient,
            bytes memory payload,
            uint256 timestamp,
            uint256 fee,
            uint8 retryCount,
            MessageStatus status,
            bytes32 txHash,
            uint256 gasUsed
        )
    {
        Message storage message = messages[messageId];
        return (
            message.id,
            message.sender,
            message.recipient,
            message.payload,
            message.timestamp,
            message.fee,
            message.retryCount,
            message.status,
            message.txHash,
            message.gasUsed
        );
    }

    /**
     * @dev Check if message is deliverable
     * @param messageId ID of message
     */
    function isMessageDeliverable(uint256 messageId) 
        external 
        view 
        returns (bool)
    {
        Message storage message = messages[messageId];
        return message.status == MessageStatus.Confirmed;
    }

    /**
     * @dev Get chain configuration
     */
    function getChainConfig() 
        external 
        view 
        returns (uint256 sourceChain, uint256 destChain)
    {
        return (sourceChainId, destinationChainId);
    }

    /**
     * @dev Calculate message hash for verification
     * @param messageId ID of message
     */
    function getMessageHash(uint256 messageId) 
        external 
        view 
        returns (bytes32)
    {
        Message storage message = messages[messageId];
        return keccak256(
            abi.encode(
                message.id,
                message.sender,
                message.recipient,
                message.payload,
                sourceChainId,
                destinationChainId
            )
        );
    }

    // ---------- Receive Function ----------
    receive() external payable {}
}
