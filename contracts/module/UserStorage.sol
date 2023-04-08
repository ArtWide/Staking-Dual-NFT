// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/
pragma solidity ^0.8.17;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

contract NTSUserManager is PermissionsEnumerable{
    constructor(address _admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    struct StakeUser{
        uint256 rewardsEarned;
        uint16[] stakedteam;
        uint16[] stakedtmhc;
        uint16[] stakedmomo;
    }

    // Staking user array for cms.
    address[] internal usersArray;
    mapping(address=>StakeUser) internal users;

    // Stores staking information based on MOMO NFT ownership.
    struct StakeMOMO {
        address stakeowner;
        uint16 staketeam;
        uint256 lastUpdateTime;
    }

    // Stores staking information based on TMHC NFT ownership.
    struct StakeTMHC {
        address stakeowner;
        uint16 staketeam;
        uint256 lastUpdateTime;
    }

    // Arrays to store staking information for MOMO and TMHC NFTs respectively.
    StakeMOMO[10000] internal inStakedmomo;
    StakeTMHC[10000] internal inStakedtmhc;

    // Structure that represents a staked team.
    struct StakeTeam {
        address stakeowner; // Address of the team's stakeowner.
        uint16[] boostIds; // IDs of the team's boosts.
        uint256 lastUpdateTime; // Block number of the last update to the team's stake.
    }

    // Array that stores all staked teams.
    StakeTeam[10000] internal inStakedteam;

    /*///////////////////////////////////////////////////////////////
                         Stake Item Storage
    //////////////////////////////////////////////////////////////*/

    // @dev MOMO Stake
    function getStakedMOMO(uint16 _tokenId) external view returns(StakeMOMO memory){
        return inStakedmomo[_tokenId];
    }
    function setInStakedMOMO(uint16 _tokenId, StakeMOMO memory stake) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(_tokenId < inStakedmomo.length, "_tokenId out of bounds");
        inStakedmomo[_tokenId] = stake;
    }
    function setInStakedMOMOTime(uint16 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE){
        inStakedmomo[_tokenId].lastUpdateTime = block.timestamp;
    }
    function delInStakedMOMO(uint16 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(_tokenId < inStakedmomo.length, "_tokenId out of bounds");
        delete inStakedmomo[_tokenId];
    }

    // @dev TMHC Stake
    function getStakedTMHC(uint16 _tokenId) external view returns(StakeTMHC memory values){
        return inStakedtmhc[_tokenId];
    }
    function setInStakedTMHC(uint16 _tokenId, StakeTMHC memory stake) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(_tokenId < inStakedtmhc.length, "_tokenId out of bounds");
        inStakedtmhc[_tokenId] = stake;
    }
    function setInStakedTMHCTime(uint16 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE){
        inStakedtmhc[_tokenId].lastUpdateTime = block.timestamp;
    }
    function delInStakedTMHC(uint16 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(_tokenId < inStakedtmhc.length, "_tokenId out of bounds");
        delete inStakedtmhc[_tokenId];
    }

    // @dev Team Stake
    function setInStakedTeam(uint16 _tokenId, StakeTeam memory stake) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tokenId < inStakedteam.length, "_tokenId out of bounds");
        inStakedteam[_tokenId] = stake;
    }
    function getInStakedTeam(uint16 _tokenId) external view returns (StakeTeam memory) {
        require(_tokenId < inStakedteam.length, "_tokenId out of bounds");
        return inStakedteam[_tokenId];
    }
    function setInStakedTeamTime(uint16 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE){
        inStakedteam[_tokenId].lastUpdateTime = block.timestamp;
    }
    function delInStakedTeam(uint16 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tokenId < inStakedteam.length, "_tokenId out of bounds");
        delete inStakedteam[_tokenId];
    }

    /*///////////////////////////////////////////////////////////////
                              User Storage
    //////////////////////////////////////////////////////////////*/

    // Get rewardsEarned for a user
    function getRewardsEarned(address user) external view returns (uint256) {
        return users[user].rewardsEarned;
    }

    // Get stakedteam for a user
    function getStakedUserTeam(address user) external view returns (uint16[] memory) {
        return users[user].stakedteam;
    }

    // Get stakedtmhc for a user
    function getStakedUserTmhc(address user) external view returns (uint16[] memory) {
        return users[user].stakedtmhc;
    }

    // Get stakedmomo for a user
    function getStakedUserMomo(address user) external view returns (uint16[] memory) {
        return users[user].stakedmomo;
    }

    // Add rewardsEarned for a user
    function addRewardsEarned(address user, uint256 rewards) external onlyRole(DEFAULT_ADMIN_ROLE){
        users[user].rewardsEarned = users[user].rewardsEarned + rewards;
    }

    // Push team id to stakedteam for a user
    function pushStakedTeam(address user, uint16 teamId) external onlyRole(DEFAULT_ADMIN_ROLE){
        users[user].stakedteam.push(teamId);
    }

    // Push tmhc id to stakedtmhc for a user
    function pushStakedTmhc(address user, uint16 tmhcId) external onlyRole(DEFAULT_ADMIN_ROLE){
        users[user].stakedtmhc.push(tmhcId);
    }

    // Push momo id to stakedmomo for a user
    function pushStakedMomo(address user, uint16 momoId) external onlyRole(DEFAULT_ADMIN_ROLE){
        users[user].stakedmomo.push(momoId);
    }

    // Pop a specific team id from stakedteam for a user
    function popStakedTeam(address user, uint16 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE){
        uint16[] storage teamArray = users[user].stakedteam;
        uint256 length = teamArray.length;

        for (uint256 i = 0; i < length; i++) {
            if (teamArray[i] == tokenId) {
                // Swap the last element with the element to delete
                teamArray[i] = teamArray[length - 1];
                // Remove the last element
                teamArray.pop();
                return;
            }
        }
        revert("Token ID not found in stakedteam array");
    }

    // Pop a specific tmhc id from stakedtmhc for a user
    function popStakedTmhc(address user, uint16 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE){
        uint16[] storage tmhcArray = users[user].stakedtmhc;
        uint256 length = tmhcArray.length;

        for (uint256 i = 0; i < length; i++) {
            if (tmhcArray[i] == tokenId) {
                // Swap the last element with the element to delete
                tmhcArray[i] = tmhcArray[length - 1];
                // Remove the last element
                tmhcArray.pop();
                return;
            }
        }
        revert("Token ID not found in stakedtmhc array");
    }

    // Pop a specific momo id from stakedmomo for a user
    function popStakedMomo(address user, uint16 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE){
        uint16[] storage momoArray = users[user].stakedmomo;
        uint256 length = momoArray.length;

        for (uint256 i = 0; i < length; i++) {
            if (momoArray[i] == tokenId) {
                // Swap the last element with the element to delete
                momoArray[i] = momoArray[length - 1];
                // Remove the last element
                momoArray.pop();
                return;
            }
        }
        revert("Token ID not found in stakedmomo array");
    }

    function getUsersArray() public view returns (address[] memory) {
        return usersArray;
    }


    /**
    * @dev Adds the caller's address to the usersArray if they have no staked tokens.
    */
    function procAddUser(address _player) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(users[_player].stakedtmhc.length == 0 && users[_player].stakedmomo.length == 0 && users[_player].stakedteam.length ==0){
            usersArray.push(_player);
        }
    }

    /**
    * @dev Deletes the caller's address from the usersArray if they have no staked tokens.
    */
    function procDelUser(address _player) external  onlyRole(DEFAULT_ADMIN_ROLE) {
        if(users[_player].stakedtmhc.length == 0 && users[_player].stakedmomo.length == 0 && users[_player].stakedteam.length ==0){
            address[] memory _userArray = usersArray;
            for(uint256 i = 0; i <_userArray.length; i++){
                if(_userArray[i] == _player){
                    usersArray[i] = _userArray[_userArray.length-1];
                    usersArray.pop();
                }
            }
        }
    }
}