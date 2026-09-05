// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";
import "@hyperlane-xyz/core/contracts/interfaces/IMessageRecipient.sol";
import "@hyperlane-xyz/core/contracts/interfaces/IInterchainSecurityModule.sol";

/**
 * @title HyperlaneERC7786Adapter
 * @notice ERC-7786 compliant Gateway adapter for Hyperlane GMP
 * @dev Implements source gateway send and destination recipient handle
 */
contract ERC7786Adapter_Hyperlane_v3_Callback is IMessageRecipient {
    // === Errors ===
    error UnsupportedAttribute(bytes4 selector);
    error InvalidRecipient();
    error InvalidDestinationChain();
    error NotMailbox();
    
    // === Events ===
    event MessageSent(
        bytes32 indexed sendId,
        bytes sender,
        bytes recipient,
        bytes payload,
        uint256 value,
        bytes[] attributes
    );
    
    event MessageDelivered(
        bytes32 indexed messageId,
        uint32 originDomain,
        bytes32 sender,
        bytes payload
    );
    
    // === State ===
    IMailbox public immutable mailbox;
    mapping(uint32 => bytes32) public remoteAdapters; // domain => adapter address (bytes32)
    mapping(bytes32 => bool) public deliveredMessages;
    
    // Supported attribute selectors
    mapping(bytes4 => bool) public supportedAttributes;
    
    // === Constants ===
    // Attribute selectors (function signatures)
    bytes4 public constant ATTR_MIN_GAS_LIMIT = bytes4(keccak256("minGasLimit(uint256)"));
    bytes4 public constant ATTR_CUSTOM_ISM = bytes4(keccak256("customIsm(address)"));
    bytes4 public constant ATTR_HOOK = bytes4(keccak256("hook(address)"));
    
    // === Constructor ===
    constructor(address _mailbox) {
        mailbox = IMailbox(_mailbox);
        
        // Register supported attributes
        supportedAttributes[ATTR_MIN_GAS_LIMIT] = true;
        supportedAttributes[ATTR_CUSTOM_ISM] = true;
        supportedAttributes[ATTR_HOOK] = true;
    }
    
    // === IERC7786GatewaySource Implementation ===
    
    /**
     * @notice Checks if an attribute is supported by this gateway
     * @param selector The 4-byte attribute selector
     * @return bool True if the attribute is supported
     */
    function supportsAttribute(bytes4 selector) external view returns (bool) {
        return supportedAttributes[selector];
    }
    
    /**
     * @notice Sends a message via Hyperlane Mailbox
     * @param recipient Binary Interoperable Address (ERC-7930 format)
     * @param payload Opaque bytes payload
     * @param attributes Array of key-value attributes
     * @return sendId The Hyperlane message ID
     */
    function sendMessage(
        bytes calldata recipient,
        bytes calldata payload,
        bytes[] calldata attributes
    ) external payable returns (bytes32 sendId) {
        // Parse attributes and extract Hyperlane-specific params
        uint256 gasLimit = 0;
        address customIsm = address(0);
        address customHook = address(0);
        
        for (uint256 i = 0; i < attributes.length; i++) {
            bytes4 selector = bytes4(attributes[i][0:4]);
            bytes memory value = attributes[i][4:];
            
            if (selector == ATTR_MIN_GAS_LIMIT) {
                gasLimit = abi.decode(value, (uint256));
            } else if (selector == ATTR_CUSTOM_ISM) {
                customIsm = abi.decode(value, (address));
            } else if (selector == ATTR_HOOK) {
                customHook = abi.decode(value, (address));
            } else {
                revert UnsupportedAttribute(selector);
            }
        }
        
        // Parse recipient for Hyperlane destination
        (uint32 destinationDomain, bytes32 recipientAddress) = _parseInteroperableAddress(recipient);
        if (recipientAddress == bytes32(0)) revert InvalidRecipient();
        if (destinationDomain == 0) revert InvalidDestinationChain();
        
        // Get remote adapter address on destination chain
        bytes32 remoteAdapter = remoteAdapters[destinationDomain];
        if (remoteAdapter == bytes32(0)) revert InvalidDestinationChain();
        
        // Build Hyperlane message payload
        // Format: adapter address (32 bytes) + original recipient (32 bytes) + original payload
        bytes memory hyperlanePayload = abi.encode(remoteAdapter, recipientAddress, payload);
        
        // Dispatch message via Mailbox
        // Note: Overpayment for gas may be required; this is handled post-process
        sendId = mailbox.dispatch{value: msg.value}(
            destinationDomain,
            remoteAdapter,      // recipient on destination chain
            hyperlanePayload
        );
        
        // Emit ERC-7786 MessageSent event
        emit MessageSent(
            sendId,
            abi.encodePacked(block.chainid, msg.sender), // sender interoperable address
            recipient,
            payload,
            msg.value,
            attributes
        );
    }
    
    // === IMessageRecipient Implementation ===
    
    /**
     * @notice Handles incoming Hyperlane messages
     * @dev Called by Mailbox.process() after ISM verification
     */
    function handle(
        uint32 origin,
        bytes32 sender,
        bytes calldata message
    ) external {
        // Only the Mailbox can call this
        if (msg.sender != address(mailbox)) revert NotMailbox();
        
        // Decode message
        (bytes32 remoteAdapter, bytes32 recipient, bytes memory payload) = abi.decode(
            message,
            (bytes32, bytes32, bytes)
        );
        
        // Verify sender is a known remote adapter
        if (remoteAdapters[origin] != sender) revert NotMailbox();
        
        // Prevent replay attacks
        bytes32 messageId = keccak256(abi.encodePacked(origin, sender, message));
        if (deliveredMessages[messageId]) revert NotMailbox();
        deliveredMessages[messageId] = true;
        
        // Forward to the intended recipient
        // The recipient must implement IERC7786GatewayDestination
        (bool success, ) = address(uint160(uint256(recipient))).call(
            abi.encodeWithSignature(
                "receiveMessage(uint32,bytes32,bytes)",
                origin,
                sender,
                payload
            )
        );
        require(success, "Message delivery failed");
        
        emit MessageDelivered(messageId, origin, sender, payload);
    }
    
    // === Administrative Functions ===
    
    /**
     * @notice Sets the remote adapter address for a destination chain
     * @param domain Hyperlane domain ID
     * @param adapter Address of the adapter on the remote chain (bytes32)
     */
    function setRemoteAdapter(uint32 domain, bytes32 adapter) external {
        // Add access control (e.g., onlyOwner) as needed
        remoteAdapters[domain] = adapter;
    }
    
    /**
     * @notice Parses an ERC-7930 interoperable address
     * @dev Format: chain_id (uint256) + address (bytes32) = 64 bytes total
     * @param data The interoperable address bytes
     * @return chainId The CAIP-2 chain ID as uint32 (Hyperlane domain)
     * @return addressBytes The 32-byte address
     */
    function _parseInteroperableAddress(bytes memory data) 
        internal 
        pure 
        returns (uint32 chainId, bytes32 addressBytes) 
    {
        require(data.length >= 64, "Invalid interoperable address length");
        
        // First 32 bytes: chain ID (as uint256)
        uint256 chainIdUint;
        assembly {
            chainIdUint := mload(add(data, 32))
        }
        chainId = uint32(chainIdUint);
        
        // Next 32 bytes: address
        assembly {
            addressBytes := mload(add(data, 64))
        }
    }
}