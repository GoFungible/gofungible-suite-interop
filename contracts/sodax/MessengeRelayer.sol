// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/IMessageRelayer.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/token/IMultichainToken.sol";

contract MessengeRelayer is IMessageRelayer {
	

    constructor(address _gateway, address _gasService) {

    }


		function sendCrosschainMessage(uint32 toChain, address toAddress, string calldata message) external override {


		}

}