// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface ISupplier {

    function sendCrosschainSupply(uint256 destChain, address destAddress, uint256 amount) external;

    function receiveCrosschainSupply(uint256 destChain, address destAddress, uint256 amount) external;

}
