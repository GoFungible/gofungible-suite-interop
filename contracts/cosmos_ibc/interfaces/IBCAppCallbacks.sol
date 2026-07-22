// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./IBCMsgs.sol";

interface IBCAppCallbacks {
	function onRecvPacket(
			IBCMsgs.Packet calldata packet,
			address relayer
	) external returns (bytes memory acknowledgement);
}