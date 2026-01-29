// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/// @title ERC-2981 NFT Royalty Standard Interface
/// @notice Interface for ERC-2981 royalty information with custom errors
/// @dev This interface includes all custom errors used by ERC-2981 implementations
interface ISwap {

    function transferSupply(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    function onSupplyReceived(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

}
