// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@thirdweb-dev/contracts/token/TokenERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./module/NTS-Multi.sol";
import "./module/NTS-UserManager.sol";

contract TMHCRebornStake is ReentrancyGuard, NTStakeMulti{
    // Staking pool onwer / admin
    address private owner;
    // Operation status of the Pool.
    bool public PauseStake;
    // Staking user array for cms.

    constructor(IERC1155 _EditionToken, IERC721 _NFTtoken, TokenERC20 _rewardToken, uint256 _rewardPerHour, address _owner) {
        owner = _owner;
        tmhcToken = _EditionToken;
        momoToken = _NFTtoken;
        rewardToken = _rewardToken;
        rewardPerHour = _rewardPerHour;
    }

    /*///////////////////////////////////////////////////////////////
                            Basic Staking Info
    //////////////////////////////////////////////////////////////*/
    function getStakedTMHC() public view returns(uint16[] memory stakedIds){
        return users[msg.sender].stakedtmhc;
    }

    function getStakedMOMO() public view returns(uint16[] memory stakedIds){
        return users[msg.sender].stakedmomo;
    }

    function getStakedTeam() public view returns(uint16[] memory stakedIds){
        return users[msg.sender].stakedteam;
    }

    function getTeamBoosts(uint16 _staketeam) public view returns(uint16[] memory boostIds){
        return inStakedteam[_staketeam].boostIds;
    }

    /*///////////////////////////////////////////////////////////////
                        Single Stake Interface
    //////////////////////////////////////////////////////////////*/
    function stake(uint _tokenType, uint16[] calldata _tokenIds) external nonReentrant {
        _stake(_tokenType, _tokenIds);
    }

    function claim(uint _tokenType, uint16 _tokenId) external nonReentrant {
        _claim(_tokenType, _tokenId);
    }

    function claimAll() external nonReentrant {
        _claimAll();
    }

    function unStake(uint _tokenType, uint16[] calldata _tokenIds) external nonReentrant {
        _unStake(_tokenType, _tokenIds);
    }

    /*///////////////////////////////////////////////////////////////
                         Multi Stake Interface
    //////////////////////////////////////////////////////////////*/
    function stakeTeam(uint16 _leaderId ,uint16[] calldata _boostIds) external nonReentrant{
        _stakeTeam(_leaderId, _boostIds);
    }

    function claimTeam(uint16 _leaderId) external nonReentrant{
        _claimTeam(_leaderId);
    }

    function calimTeamAll() external nonReentrant{
        _claimTeamAll();
    }

    function unStakeTeam(uint16 _leaderId) external nonReentrant{
        _unStakeTeam(_leaderId);
    }

    function unStakeTeamBatch(uint16[] calldata _leaderIds) external nonReentrant {
        _unStakeTeamBatch(_leaderIds);
    }

    function editStakeTeam(uint16 _leaderId, uint16[] calldata _newBoostIds) external nonReentrant {
        _editStakeTeam(_leaderId, _newBoostIds);
    }

    /*///////////////////////////////////////////////////////////////
                            Admin Function
    //////////////////////////////////////////////////////////////*/
    function setAddMomoGrades(uint8[] calldata _momogrades) public {
        require(msg.sender == owner, "Not owner");
        for(uint256 i = 0; i < _momogrades.length; i++){
            momoGrades.push(_momogrades[i]);
        }
    }

    function setGradesBonus(uint8[10] calldata _gradesbonus) public {
        require(msg.sender == owner, "Not owner");
        gradesBonus = _gradesbonus;
    }
    function getUserArray() public view returns(address[] memory _userArray){
        require(msg.sender == owner, "Not owner");
        return usersArray;
    }
    function getUserCount() public view returns(uint256 _userCount){
        require(msg.sender == owner, "Not owner");
        return usersArray.length;
    }

}