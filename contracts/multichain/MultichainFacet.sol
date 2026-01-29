// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../../providers/transfer-liquidity/TramferMoneyWithHiperlaneWarp.sol";

contract MultichainFacet {

	ISendMoney sender = new TramferMoneyWithHiperlaneWarp(toChain);

	// current chain
  function initialize(string memory name_, string memory symbol_, uint256 supply_) public {
		
  }

	// chain ecosystem
  function transferLiquidity(uint256 toChain, uint256 amount) public {

		chainSupply = chainSupply - amount;

		address tokenAddress = counterartNetworkTokens[toChain];
		sender.sendMoney(tokenAddress, chainSupply);
		
  }

  function receiveLiquidity(uint256 amount) public {

		chainSupply = chainSupply + amount;
				
  }

}
