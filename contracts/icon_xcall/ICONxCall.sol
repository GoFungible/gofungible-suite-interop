pragma solidity ^0.8.0;

// Sender Contract - Sends messages to Receiver contract
contract MessageSender {
    address public receiverContract;
    address public admin;
    
    event MessageSent(string message, address indexed targetContract);
    event CallResult(bool success, bytes data);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    
    constructor(address _receiverContract) {
        admin = msg.sender;
        receiverContract = _receiverContract;
    }
    
    function setReceiverContract(address _receiverContract) external onlyAdmin {
        receiverContract = _receiverContract;
    }
    
    // Send a simple message to the receiver contract
    function sendMessage(string memory _message) external returns (bool) {
        require(receiverContract != address(0), "Receiver contract not set");
        
        // Encode the function call and data
        bytes memory data = abi.encodeWithSignature(
            "receiveMessage(string,address)", 
            _message, 
            msg.sender
        );
        
        // Execute the call
        (bool success, bytes memory result) = receiverContract.call(data);
        
        emit MessageSent(_message, receiverContract);
        emit CallResult(success, result);
        
        return success;
    }
    
    // Send a message with value transfer
    function sendMessageWithValue(string memory _message) external payable returns (bool) {
        require(receiverContract != address(0), "Receiver contract not set");
        require(msg.value > 0, "Must send some ICX");
        
        bytes memory data = abi.encodeWithSignature(
            "receiveMessageWithValue(string,address)", 
            _message, 
            msg.sender
        );
        
        (bool success, bytes memory result) = receiverContract.call{value: msg.value}(data);
        
        emit MessageSent(_message, receiverContract);
        emit CallResult(success, result);
        
        return success;
    }
    
    // Batch send messages to multiple contracts
    function batchSendMessages(
        string memory _message, 
        address[] memory _targetContracts
    ) external returns (bool[] memory) {
        require(_targetContracts.length > 0, "No target contracts provided");
        
        bool[] memory results = new bool[](_targetContracts.length);
        bytes memory data = abi.encodeWithSignature(
            "receiveMessage(string,address)", 
            _message, 
            msg.sender
        );
        
        for (uint i = 0; i < _targetContracts.length; i++) {
            (bool success, ) = _targetContracts[i].call(data);
            results[i] = success;
            emit MessageSent(_message, _targetContracts[i]);
        }
        
        return results;
    }
    
    // Check contract balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // Withdraw funds (admin only)
    function withdrawFunds(address payable _to, uint256 _amount) external onlyAdmin {
        require(_amount <= address(this).balance, "Insufficient balance");
        _to.transfer(_amount);
    }
}

pragma solidity ^0.8.0;

// Receiver Contract - Receives and processes messages
contract MessageReceiver {
    address public admin;
    
    struct ReceivedMessage {
        string message;
        address sender;
        address origin;
        uint256 timestamp;
        uint256 value;
        uint256 messageId;
    }
    
    mapping(uint256 => ReceivedMessage) public messages;
    mapping(address => uint256[]) public senderMessages;
    uint256 public messageCount;
    
    event MessageReceived(
        uint256 indexed messageId,
        string message,
        address indexed sender,
        address indexed origin,
        uint256 value,
        uint256 timestamp
    );
    
    event ResponseSent(string response, address target);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }
    
    // Primary message receiving function
    function receiveMessage(string memory _message, address _sender) external returns (string memory) {
        messageCount++;
        
        messages[messageCount] = ReceivedMessage({
            message: _message,
            sender: msg.sender,    // The calling contract
            origin: _sender,       // Original message sender
            timestamp: block.timestamp,
            value: 0,
            messageId: messageCount
        });
        
        senderMessages[_sender].push(messageCount);
        
        emit MessageReceived(
            messageCount,
            _message,
            msg.sender,
            _sender,
            0,
            block.timestamp
        );
        
        // Send a response back to the original sender
        string memory response = string(abi.encodePacked(
            "Received your message: '", 
            _message, 
            "' at timestamp: ", 
            uint2str(block.timestamp)
        ));
        
        // Send response back to origin
        bytes memory data = abi.encodeWithSignature(
            "handleResponse(string,address)", 
            response, 
            address(this)
        );
        
        (bool success, ) = _sender.call(data);
        
        if (success) {
            emit ResponseSent(response, _sender);
        }
        
        return response;
    }
    
    // Receive message with value transfer
    function receiveMessageWithValue(string memory _message, address _sender) external payable returns (string memory) {
        messageCount++;
        
        messages[messageCount] = ReceivedMessage({
            message: _message,
            sender: msg.sender,
            origin: _sender,
            timestamp: block.timestamp,
            value: msg.value,
            messageId: messageCount
        });
        
        senderMessages[_sender].push(messageCount);
        
        emit MessageReceived(
            messageCount,
            _message,
            msg.sender,
            _sender,
            msg.value,
            block.timestamp
        );
        
        return "Message with value received successfully";
    }
    
    // Handle responses from other contracts
    function handleResponse(string memory _response, address _responder) external returns (bool) {
        // Process the response here
        emit ResponseSent(_response, _responder);
        return true;
    }
    
    // Get message by ID
    function getMessage(uint256 _messageId) external view returns (ReceivedMessage memory) {
        require(_messageId > 0 && _messageId <= messageCount, "Invalid message ID");
        return messages[_messageId];
    }
    
    // Get all messages from a specific sender
    function getMessagesFromSender(address _sender) external view returns (ReceivedMessage[] memory) {
        uint256[] memory messageIds = senderMessages[_sender];
        ReceivedMessage[] memory senderMessagesArray = new ReceivedMessage[](messageIds.length);
        
        for (uint256 i = 0; i < messageIds.length; i++) {
            senderMessagesArray[i] = messages[messageIds[i]];
        }
        
        return senderMessagesArray;
    }
    
    // Get total message count
    function getTotalMessageCount() external view returns (uint256) {
        return messageCount;
    }
    
    // Utility function to convert uint to string
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
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
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    // Check contract balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // Withdraw funds (admin only)
    function withdrawFunds(address payable _to, uint256 _amount) external onlyAdmin {
        require(_amount <= address(this).balance, "Insufficient balance");
        _to.transfer(_amount);
    }
}