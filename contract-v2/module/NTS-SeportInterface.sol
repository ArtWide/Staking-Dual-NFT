// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/
pragma solidity ^0.8.17;
import "https://github.com/ProjectOpenSea/seaport/blob/main/contracts/Seaport.sol";


contract NFTHider {
    Seaport private _seaport;

    constructor(address seaportAddress) {
        _seaport = Seaport(seaportAddress);
    }

    function hideNFT(uint256 tokenId, address nftAddress) public {
        _seaport.updateERC721Listing(
            nftAddress,
            tokenId,
            true,
            address(0x0),
            0,
            "",
            "",
            false
        );
    }
}