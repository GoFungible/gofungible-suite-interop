// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./IBCMsgs.sol";

interface IICS26Router {
  function sendPacket(IBCMsgs.MsgSendPacket calldata msgData) external returns (uint64 sequence);
}