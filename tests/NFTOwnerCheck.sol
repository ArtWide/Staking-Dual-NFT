// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
}

contract NFTValidator {
    // ERC-1155 contract address
    address public erc1155ContractAddress = 0x008aECaD1722C3350eD9c710517eCE27cE2C9869;

    // ERC-1155 contract instance
    IERC1155 private erc1155Contract = IERC1155(erc1155ContractAddress);

    // Event to be emitted when user is an NFT owner
    event NFTOwner(address indexed userAddress, uint256 tokenId);

    function isNFTOwner(address userAddress, uint256 tokenId) external {
        // Check if the user owns the specified tokenId
        uint256 balance = erc1155Contract.balanceOf(userAddress, tokenId);
        if (balance > 0) {
            // Check if the user has approved the contract to spend their NFTs
            bool isApproved = erc1155Contract.isApprovedForAll(userAddress, address(this));
            if (isApproved) {
                // Emit the NFTOwner event
                emit NFTOwner(userAddress, tokenId);
            }
        }
    }
}