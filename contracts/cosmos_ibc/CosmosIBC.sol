// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IBC Core Interfaces
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title IBCApp
 * @dev IBC-enabled contract that can send and receive packets across blockchains
 * Implements IBC handler interfaces for packet sending and receiving
 */
contract IBCApp {
    // IBC Handler contract address
    address public ibcHandler;
    
    // Contract owner
    address public owner;
    
    // Channel information
    struct Channel {
        bytes32 channelId;
        string portId;
        string counterpartyPortId;
        string counterpartyChannelId;
        bytes32 connectionId;
        bool active;
    }
    
    // Packet structure
    struct IBCPacket {
        bytes32 sourceChannel;
        bytes32 destinationChannel;
        bytes data;
        uint64 sequence;
        uint64 timeoutTimestamp;
        bytes memo;
    }
    
    // Acknowledgement structure
    struct AckPacket {
        bytes32 sourceChannel;
        uint64 sequence;
        bytes data;
        bool success;
    }
    
    // Message tracking
    mapping(bytes32 => SentPacket) public sentPackets;
    mapping(bytes32 => ReceivedPacket) public receivedPackets;
    mapping(bytes32 => Channel) public channels;
    mapping(bytes32 => uint64) public nextSequenceSend;
    mapping(bytes32 => uint64) public nextSequenceRecv;
    
    // Custom application data structures
    struct AppMessage {
        string message;
        address sender;
        uint256 timestamp;
        string action; // "TRANSFER", "CALL", "QUERY", "RESPONSE"
        bytes payload;
    }
    
    struct SentPacket {
        bytes32 packetId;
        bytes32 channelId;
        uint64 sequence;
        AppMessage message;
        uint256 sentTimestamp;
        bool acknowledged;
        bytes ackData;
    }
    
    struct ReceivedPacket {
        bytes32 packetId;
        bytes32 channelId;
        uint64 sequence;
        AppMessage message;
        uint256 receivedTimestamp;
        bool processed;
        bytes response;
    }
    
    // Events
    event PacketSent(
        bytes32 indexed packetId,
        bytes32 indexed channelId,
        uint64 sequence,
        address sender,
        string message,
        string action,
        uint256 timestamp
    );
    
    event PacketReceived(
        bytes32 indexed packetId,
        bytes32 indexed channelId,
        uint64 sequence,
        address sender,
        string message,
        string action,
        uint256 timestamp
    );
    
    event Acknowledgement(
        bytes32 indexed packetId,
        bytes32 indexed channelId,
        uint64 sequence,
        bool success,
        bytes ackData,
        uint256 timestamp
    );
    
    event Timeout(
        bytes32 indexed packetId,
        bytes32 indexed channelId,
        uint64 sequence,
        uint256 timestamp
    );
    
    event ChannelEstablished(
        bytes32 indexed channelId,
        string portId,
        string counterpartyPortId,
        string counterpartyChannelId,
        bytes32 connectionId,
        uint256 timestamp
    );
    
    // Modifiers
    modifier onlyIbcHandler() {
        require(msg.sender == ibcHandler, "Only IBC handler can call");
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }
    
    modifier onlyActiveChannel(bytes32 channelId) {
        require(channels[channelId].active, "Channel not active");
        _;
    }
    
    /**
     * @dev Constructor
     * @param _ibcHandler IBC handler contract address
     */
    constructor(address _ibcHandler) {
        owner = msg.sender;
        ibcHandler = _ibcHandler;
    }
    
    /**
     * @dev Send an IBC packet to another blockchain
     * @param channelId The channel ID to send through
     * @param message The application message
     * @param timeoutTimestamp Packet timeout timestamp
     */
    function sendIBCPacket(
        bytes32 channelId,
        string memory message,
        string memory action,
        bytes memory payload,
        uint64 timeoutTimestamp
    ) external onlyActiveChannel(channelId) returns (bytes32) {
        require(timeoutTimestamp > block.timestamp, "Timeout must be in future");
        
        // Get next sequence number
        uint64 sequence = nextSequenceSend[channelId];
        nextSequenceSend[channelId]++;
        
        // Create application message
        AppMessage memory appMessage = AppMessage({
            message: message,
            sender: msg.sender,
            timestamp: block.timestamp,
            action: action,
            payload: payload
        });
        
        // Encode packet data
        bytes memory packetData = abi.encode(appMessage);
        
        // Create packet
        IBCPacket memory packet = IBCPacket({
            sourceChannel: channelId,
            destinationChannel: bytes32(bytes(channels[channelId].counterpartyChannelId)),
            data: packetData,
            sequence: sequence,
            timeoutTimestamp: timeoutTimestamp,
            memo: ""
        });
        
        bytes32 packetId = keccak256(abi.encodePacked(
            channelId,
            sequence,
            packetData
        ));
        
        // Store sent packet
        sentPackets[packetId] = SentPacket({
            packetId: packetId,
            channelId: channelId,
            sequence: sequence,
            message: appMessage,
            sentTimestamp: block.timestamp,
            acknowledged: false,
            ackData: ""
        });
        
        // Call IBC handler to send packet
        (bool success, ) = ibcHandler.delegatecall(
            abi.encodeWithSignature(
                "sendPacket(bytes32,bytes,uint64)",
                channelId,
                packetData,
                timeoutTimestamp
            )
        );
        
        require(success, "Failed to send packet via IBC");
        
        emit PacketSent(
            packetId,
            channelId,
            sequence,
            msg.sender,
            message,
            action,
            block.timestamp
        );
        
        return packetId;
    }
    
    /**
     * @dev Receive an IBC packet (called by IBC handler)
     * @param channelId The channel ID
     * @param sequence The packet sequence
     * @param data The packet data
     */
    function onRecvPacket(
        bytes32 channelId,
        uint64 sequence,
        bytes calldata data
    ) external onlyIbcHandler onlyActiveChannel(channelId) returns (bytes memory) {
        // Verify sequence
        require(sequence == nextSequenceRecv[channelId], "Invalid sequence");
        nextSequenceRecv[channelId]++;
        
        // Decode application message
        AppMessage memory appMessage = abi.decode(data, (AppMessage));
        
        bytes32 packetId = keccak256(abi.encodePacked(
            channelId,
            sequence,
            data
        ));
        
        // Store received packet
        receivedPackets[packetId] = ReceivedPacket({
            packetId: packetId,
            channelId: channelId,
            sequence: sequence,
            message: appMessage,
            receivedTimestamp: block.timestamp,
            processed: false,
            response: ""
        });
        
        // Process the message based on action
        bytes memory ackData;
        bool success;
        
        if (keccak256(bytes(appMessage.action)) == keccak256(bytes("TRANSFER"))) {
            (success, ackData) = _handleTransfer(appMessage);
        } else if (keccak256(bytes(appMessage.action)) == keccak256(bytes("CALL"))) {
            (success, ackData) = _handleCall(appMessage);
        } else if (keccak256(bytes(appMessage.action)) == keccak256(bytes("QUERY"))) {
            (success, ackData) = _handleQuery(appMessage);
        } else {
            // Default message handling
            (success, ackData) = _handleMessage(appMessage);
        }
        
        receivedPackets[packetId].processed = true;
        receivedPackets[packetId].response = ackData;
        
        emit PacketReceived(
            packetId,
            channelId,
            sequence,
            appMessage.sender,
            appMessage.message,
            appMessage.action,
            block.timestamp
        );
        
        // Return acknowledgement
        return abi.encode(success, ackData);
    }
    
    /**
     * @dev Handle transfer action
     */
    function _handleTransfer(AppMessage memory appMessage) internal returns (bool, bytes memory) {
        // Decode transfer payload
        (address token, uint256 amount, address recipient) = abi.decode(
            appMessage.payload, 
            (address, uint256, address)
        );
        
        // Implement token transfer logic
        // This would interact with your token contract
        
        string memory response = string(abi.encodePacked(
            "Transfer processed: ",
            uint2str(amount),
            " tokens to ",
            addressToString(recipient)
        ));
        
        return (true, abi.encode(response));
    }
    
    /**
     * @dev Handle contract call action
     */
    function _handleCall(AppMessage memory appMessage) internal returns (bool, bytes memory) {
        // Decode call payload
        (address targetContract, bytes memory callData, uint256 value) = abi.decode(
            appMessage.payload,
            (address, bytes, uint256)
        );
        
        // Execute the call
        (bool success, bytes memory result) = targetContract.call{value: value}(callData);
        
        return (success, result);
    }
    
    /**
     * @dev Handle query action
     */
    function _handleQuery(AppMessage memory appMessage) internal view returns (bool, bytes memory) {
        string memory query = appMessage.message;
        bytes memory response;
        
        if (keccak256(bytes(query)) == keccak256(bytes("GET_BALANCE"))) {
            response = abi.encode(address(this).balance);
        } else if (keccak256(bytes(query)) == keccak256(bytes("GET_TIMESTAMP"))) {
            response = abi.encode(block.timestamp);
        } else if (keccak256(bytes(query)) == keccak256(bytes("GET_CHANNEL_COUNT"))) {
            uint256 count = 0;
            for (uint256 i = 0; i < type(uint256).max; i++) {
                // Count active channels (simplified)
                break;
            }
            response = abi.encode(count);
        } else {
            response = abi.encode("Unknown query");
        }
        
        return (true, response);
    }
    
    /**
     * @dev Handle generic message
     */
    function _handleMessage(AppMessage memory appMessage) internal returns (bool, bytes memory) {
        // Process generic message
        string memory response = string(abi.encodePacked(
            "Processed: ",
            appMessage.message,
            " from ",
            addressToString(appMessage.sender),
            " at ",
            uint2str(block.timestamp)
        ));
        
        return (true, abi.encode(response));
    }
    
    /**
     * @dev Acknowledge packet (called by IBC handler)
     * @param channelId The channel ID
     * @param sequence The packet sequence
     * @param ack The acknowledgement data
     */
    function onAcknowledgementPacket(
        bytes32 channelId,
        uint64 sequence,
        bytes calldata ack
    ) external onlyIbcHandler onlyActiveChannel(channelId) {
        bytes32 packetId = keccak256(abi.encodePacked(channelId, sequence));
        
        SentPacket storage packet = sentPackets[packetId];
        require(packet.packetId != bytes32(0), "Packet not found");
        
        // Decode acknowledgement
        (bool success, bytes memory ackData) = abi.decode(ack, (bool, bytes));
        
        packet.acknowledged = true;
        packet.ackData = ackData;
        
        emit Acknowledgement(
            packetId,
            channelId,
            sequence,
            success,
            ackData,
            block.timestamp
        );
    }
    
    /**
     * @dev Handle packet timeout (called by IBC handler)
     * @param channelId The channel ID
     * @param sequence The packet sequence
     */
    function onTimeoutPacket(
        bytes32 channelId,
        uint64 sequence
    ) external onlyIbcHandler onlyActiveChannel(channelId) {
        bytes32 packetId = keccak256(abi.encodePacked(channelId, sequence));
        
        SentPacket storage packet = sentPackets[packetId];
        require(packet.packetId != bytes32(0), "Packet not found");
        
        emit Timeout(
            packetId,
            channelId,
            sequence,
            block.timestamp
        );
        
        // Clean up or handle timeout logic
        // For example, refund tokens if transfer failed
    }
    
    /**
     * @dev Establish a new channel
     */
    function establishChannel(
        bytes32 channelId,
        string memory portId,
        string memory counterpartyPortId,
        string memory counterpartyChannelId,
        bytes32 connectionId
    ) external onlyOwner {
        require(!channels[channelId].active, "Channel already active");
        
        channels[channelId] = Channel({
            channelId: channelId,
            portId: portId,
            counterpartyPortId: counterpartyPortId,
            counterpartyChannelId: counterpartyChannelId,
            connectionId: connectionId,
            active: true
        });
        
        // Initialize sequence numbers
        nextSequenceSend[channelId] = 1;
        nextSequenceRecv[channelId] = 1;
        
        emit ChannelEstablished(
            channelId,
            portId,
            counterpartyPortId,
            counterpartyChannelId,
            connectionId,
            block.timestamp
        );
    }
    
    /**
     * @dev Close a channel
     */
    function closeChannel(bytes32 channelId) external onlyOwner onlyActiveChannel(channelId) {
        channels[channelId].active = false;
    }
    
    /**
     * @dev Send token transfer across IBC
     */
    function sendTokenTransfer(
        bytes32 channelId,
        address token,
        uint256 amount,
        address recipient,
        string memory message,
        uint64 timeoutTimestamp
    ) external returns (bytes32) {
        // Encode transfer payload
        bytes memory payload = abi.encode(token, amount, recipient);
        
        return sendIBCPacket(
            channelId,
            message,
            "TRANSFER",
            payload,
            timeoutTimestamp
        );
    }
    
    /**
     * @dev Send contract call across IBC
     */
    function sendContractCall(
        bytes32 channelId,
        address targetContract,
        bytes memory callData,
        uint256 value,
        string memory message,
        uint64 timeoutTimestamp
    ) external returns (bytes32) {
        bytes memory payload = abi.encode(targetContract, callData, value);
        
        return sendIBCPacket(
            channelId,
            message,
            "CALL",
            payload,
            timeoutTimestamp
        );
    }
    
    /**
     * @dev Send query across IBC
     */
    function sendQuery(
        bytes32 channelId,
        string memory query,
        uint64 timeoutTimestamp
    ) external returns (bytes32) {
        return sendIBCPacket(
            channelId,
            query,
            "QUERY",
            "",
            timeoutTimestamp
        );
    }
    
    /**
     * @dev Get packet status
     */
    function getPacketStatus(bytes32 packetId) external view returns (SentPacket memory, ReceivedPacket memory) {
        return (sentPackets[packetId], receivedPackets[packetId]);
    }
    
    /**
     * @dev Get channel information
     */
    function getChannel(bytes32 channelId) external view returns (Channel memory) {
        return channels[channelId];
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
    
    function addressToString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
        
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
    
    // Receive funds
    receive() external payable {}
}