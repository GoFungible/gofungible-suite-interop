// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "gofungible-erc-20-multichain-relayer-extension/contracts/relayers/IMessageRelayer.sol";
import "gofungible-erc-20-multichain-relayer-extension/contracts/token/IMultichainToken.sol";

import "./interfaces/IAxelarGateway.sol";
import "./interfaces/IAxelarGasService.sol";

contract MessengeRelayer is IMessageRelayer {
	
    IAxelarGateway public gateway;

    IAxelarGasService public gasService;

		mapping(uint256 => string) public chainIdToName;

    constructor(address _gateway, address _gasService) {
			gateway = IAxelarGateway(_gateway);
			gasService = IAxelarGasService(_gasService);

			chainIdToName[1] = "ethereum";
			chainIdToName[250] = "Fantom";
			chainIdToName[43114] = "avalanche";
			chainIdToName[137] = "polygon";
			chainIdToName[42161] = "arbitrum";
			chainIdToName[8453] = "base";
			chainIdToName[56] = "bnbchain";
			chainIdToName[42220] = "celo";
			chainIdToName[10] = "optimism";
    }

    function getAxelarChainName(uint256 chainId) public view returns (string memory) {
			string memory name = chainIdToName[chainId];
			require(bytes(name).length != 0, "Chain ID not supported");
			return name;
    }

		function sendCrosschainMessage(uint32 toChain, address toAddress, string calldata message) external override {

			string memory _destinationChain = getAxelarChainName(toChain);

			string memory _destinationAddress = toAddress.toString();

			bytes memory payload = abi.encode(_message);

			// This is the core GMP call
			gateway.callContract{value: msg.value}(
				_destinationChain,
				_destinationAddress,
				payload
			);

		}

    // Axelar's `callContract` expects an `_execute` method that can be called by the gateway.
    // This function is called by the Axelar Gateway on the destination chain
    function _execute(
        bytes32 commandId,
        string memory sourceChain,
        string memory sourceAddress,
        bytes memory payload
    ) external {
			// Ensure this call comes from the Axelar Gateway
			require(msg.sender == address(gateway), "Not from Axelar Gateway");

			string fromChain = sourceChain;
			address fromAddress = address(bytes20(bytes32(bytes.concat(new bytes(12), hex"000000000000000000000000", bytes(sourceAddress))))); // Truncate sourceAddress
			string message = abi.decode(payload, (string));

			IMultichainToken(fromAddress).onCrosschainMessage(fromChain, fromAddress, message);

			emit CrosschainMessageReceived(fromChain, fromAddress, message);
    }

}