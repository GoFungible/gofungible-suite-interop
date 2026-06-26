// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;


interface IMessenger {

    function sendCrosschainMessage(uint256 destChain, address destAddress, uint256 amount) external;

    function registerReceiver(address _receiver) external;

    function unregisterReceiver(address _receiver) external;

    function receiveCrosschainMessage(uint256 destChain, address destAddress, uint256 amount) external;

}