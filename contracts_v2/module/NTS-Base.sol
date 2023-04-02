// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./RewardVault.sol";
import "./UserStorage.sol";

contract NTSBase {
    // Staking target ERC1155 NFT contract - TMHC
    IERC1155 public tmhcToken;
    // Staking target ERC721 NFT contract - MOMO
    IERC721 public momoToken;
    // Reward ERC20 Token contract
    NTSRewardVault public rewardVault;

    NTSUserManager public UserStorage;
    
    // Reward per Hour - TMHC
    uint256 public rewardPerHour;    
    // Reward per Hour - MOMO
    uint256 public rewardPerHourSub;



    event Staked(address indexed user, uint tokenType, uint16 [] indexed tokenId);       
    event unStaked(address indexed user, uint tokenType, uint16[] boostId);    
    event RewardPaid(address indexed user, uint256 reward);
}

