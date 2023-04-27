// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
}

contract NFTValidator {
    // ERC-1155 contract address
    address public erc1155ContractAddress;

    // ERC-1155 contract instance
    IERC1155 private erc1155Contract;

    // Event to be emitted when user is an NFT owner
    event NFTOwner(address indexed userAddress, uint256[] tokenIds);

    constructor(address _erc1155ContractAddress) {
        erc1155ContractAddress = _erc1155ContractAddress;
        erc1155Contract = IERC1155(erc1155ContractAddress);
    }

    function isNFTOwner(address userAddress, uint256[] memory tokenIds) external {
        // Create an array of user addresses with the same length as tokenIds
        address[] memory accounts = new address[](tokenIds.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            accounts[i] = userAddress;
        }

        // Check if the user owns the specified tokenIds
        uint256[] memory balances = erc1155Contract.balanceOfBatch(accounts, tokenIds);
        for (uint256 i = 0; i < balances.length; i++) {
            require(balances[i] > 0, "User is not an NFT owner");
        }

        // Emit the NFTOwner event
        emit NFTOwner(userAddress, tokenIds);
    }
}
