// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Structures mirroring core Cosmos IBC specifications
library IBCMsgs {

	struct MsgSendPacket {
		string sourcePort;
		string sourceChannel;
		uint64 timeoutTimestamp; // Nanoseconds
		bytes payload;
	}

	struct Packet {
		uint64 sequence;
		string sourcePort;
		string sourceChannel;
		string destinationPort;
		string destinationChannel;
		bytes payload;
		uint64 timeoutTimestamp;
	}
	
}

