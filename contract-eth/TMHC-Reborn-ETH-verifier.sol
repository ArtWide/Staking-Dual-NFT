// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

//    _______ _______ ___ ___ _______ ______  ___     ___ ______  _______     ___     _______ _______  _______ 
//   |   _   |   _   |   Y   |   _   |   _  \|   |   |   |   _  \|   _   |   |   |   |   _   |   _   \|   _   |
//   |   1___|.  1___|.  |   |.  1___|.  |   |.  |   |.  |.  |   |.  1___|   |.  |   |.  1   |.  1   /|   1___|
//   |____   |.  __)_|.  |   |.  __)_|.  |   |.  |___|.  |.  |   |.  __)_    |.  |___|.  _   |.  _   \|____   |
//   |:  1   |:  1   |:  1   |:  1   |:  |   |:  1   |:  |:  |   |:  1   |   |:  1   |:  |   |:  1    |:  1   |
//   |::.. . |::.. . |\:.. ./|::.. . |::.|   |::.. . |::.|::.|   |::.. . |   |::.. . |::.|:. |::.. .  |::.. . |
//   `-------`-------' `---' `-------`--- ---`-------`---`--- ---`-------'   `-------`--- ---`-------'`-------'
//   NFTHolderCheck V0.1.0

contract NFTHolderCheck is PermissionsEnumerable, Multicall{
    address public erc1155NftAddress;
    address public erc721NftAddress;

    event ERC1155NftHolder(address indexed holder, uint256[] tokenIds);
    event ERC721NftHolder(address indexed holder, uint256[] tokenIds);

    constructor(address admin) {
         _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function updateERC1155NftAddress(address _newAddress) external{
        erc1155NftAddress = _newAddress;
    }

    function updateERC721NftAddress(address _newAddress) external{
        erc721NftAddress = _newAddress;
    }

    function checkERC1155NftHolder(address _holder, uint256[] calldata _tokenIds) external {
        require(erc1155NftAddress != address(0), "ERC1155 NFT address not set");
        IERC1155 erc1155Nft = IERC1155(erc1155NftAddress);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(erc1155Nft.balanceOf(_holder, _tokenIds[i]) > 0, "Not an ERC1155 NFT holder");
        }
        emit ERC1155NftHolder(_holder, _tokenIds);
    }

    function checkERC721NftHolder(address _holder, uint256[] calldata _tokenIds) external {
        require(erc721NftAddress != address(0), "ERC721 NFT address not set");
        IERC721 erc721Nft = IERC721(erc721NftAddress);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(erc721Nft.ownerOf(_tokenIds[i]) == _holder, "Not an ERC721 NFT holder");
        }
        emit ERC721NftHolder(_holder, _tokenIds);
    }
}
