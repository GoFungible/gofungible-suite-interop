// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../relayers/ISupplyRelayer.sol";

import "../token/IMultichainToken.sol";

contract MockedSupplyRelayer is ISupplyRelayer {


	function sendCrosschainSupply(uint256 toChain, address toAddress, uint256 amount) external override {

			emit CrosschainSupplySent(toChain, toAddress, amount);

			IMultichainToken(toAddress).onCrosschainSupply(toChain, toAddress, amount);

			emit CrosschainSupplyReceived(toChain, toAddress, amount);

	}

}