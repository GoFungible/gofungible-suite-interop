// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LibMultichainStorage {

	struct Multichain {

		uint256 chainSupply;

		mapping (uint256 => address) counterartNetworks;

		mapping (uint256 => address) counterartNetworkTokens;

	}

}