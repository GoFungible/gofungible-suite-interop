pragma solidity 0.8.30;

interface ZetaMPI {
	/**
	 * @dev Sending value and data cross-chain is as easy as calling zeta.send(SendInput)
	 */
	function send(ZetaInterfaces.SendInput calldata input) external;
}
