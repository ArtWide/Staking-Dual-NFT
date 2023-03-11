// SPDX-License-Identifier: BSL 1.1

/* 
*This code is subject to the Business Source License version 1.1
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved
*/
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@thirdweb-dev/contracts/token/TokenERC20.sol";

contract NTSBase {
    // Staking target ERC1155 NFT contract - TMHC
    IERC1155 public tmhcToken;
    // Staking target ERC721 NFT contract - MOMO
    IERC721 public momoToken;
    // Reward ERC20 Token contract
    TokenERC20 public rewardToken;
    // Reward per each block (for eth, about 13~15 sec)
    uint256 public rewardPerHour;    

    event Staked(address indexed user, uint tokenType, uint16 [] indexed tokenId);       
    event unStaked(address indexed user, uint tokenType, uint16[] boostId);    
    event RewardPaid(address indexed user, uint256 reward);
}

