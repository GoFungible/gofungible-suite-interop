// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/IMessageRelayer.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/token/IMultichainToken.sol";

import "./interfaces/IBCAppCallbacks.sol";
import "./interfaces/IICS26Router.sol";
import "./interfaces/IBCMsgs.sol";

contract MessengeRelayer is IMessageRelayer {

  // Core IBC Routing Router on the EVM Chain
  IICS26Router public immutable ibcRouter;

	constructor(address _ibcRouter) {
		require(_ibcRouter != address(0), "Invalid router address");
		ibcRouter = IICS26Router(_ibcRouter);
	}

	function sendCrosschainMessage(uint32 toChain, address toAddress, string calldata message) external override {

		// 1. Instantiate the struct matching your Cosmos payload architecture
		CustomPacketData memory packetData = CustomPacketData({
				creator: creator,
				message: message
		});

		// 2. EVM Codec Step: ABI Encode the structural payload to binary bytes
		bytes memory encodedPayload = abi.encode(packetData);

		// 3. Construct the packet parameters for the router
		IBCMsgs.MsgSendPacket memory msgSend = IBCMsgs.MsgSendPacket({
				sourcePort: sourcePort,
				sourceChannel: sourceChannel,
				timeoutTimestamp: timeoutTimestampNano,
				payload: encodedPayload
		});

		// 4. Dispatch the packet to the core router out to the Relayer network
		uint64 sequence = ibcRouter.sendPacket(msgSend);

	}

	/**
	 * @notice Callback invoked by the core IBC router when a packet is routed to this app
	 */
	function onRecvPacket(IBCMsgs.Packet calldata packet, address relayer) external override returns (bytes memory) {

		// Enforce security: Only allow the authorized Core IBC Router to trigger callbacks
		require(msg.sender == address(ibcRouter), "Unauthorized execution caller");

		// 1. EVM Codec Step: Decode the raw payload back into the structural entity
		(CustomPacketData memory decodedData) = abi.decode(packet.payload, (CustomPacketData));

		// 2. Perform validity assertions
		require(bytes(decodedData.creator).length > 0, "Codec Error: Empty creator field");

		emit PacketReceived(packet.sequence, decodedData.creator, decodedData.message);

		// 4. Create and ABI-encode a successful Acknowledgement response
		bytes memory successAck = abi.encode("success");
		return successAck;
	}

}