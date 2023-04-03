// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/
pragma solidity ^0.8.17;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

contract NTSUserManager is PermissionsEnumerable{

    struct StakeUser{
        uint256 rewardsEarned;
        uint16[] stakedteam;
        uint16[] stakedtmhc;
        uint16[] stakedmomo;
    }

    // Staking user array for cms.
    address[] public usersArray;
    mapping(address=>StakeUser) public users;

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
    StakeMOMO[10000] public inStakedmomo;
    StakeTMHC[10000] public inStakedtmhc;

    // @dev MOMO Stake Interface
    function getStakedMOMO(uint16 _tokenId) public view returns(StakeMOMO memory){
        return inStakedmomo[_tokenId];
    }

    // Set inStakedmomo by _tokenId
    function setInStakedMOMO(uint16 _tokenId, StakeMOMO memory stake) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(_tokenId < inStakedmomo.length, "_tokenId out of bounds");
        inStakedmomo[_tokenId] = stake;
    }

    function setInStakedMOMOTime(uint16 _tokenId) public{
        inStakedmomo[_tokenId].lastUpdateTime = block.timestamp;
    }

    function delInStakedMOMO(uint16 _tokenId) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(_tokenId < inStakedmomo.length, "_tokenId out of bounds");
        delete inStakedmomo[_tokenId];
    }

    // @dev TMHC Stake Interface
    function getStakedTMHC(uint16 _tokenId) public view returns(StakeTMHC memory){
        return inStakedtmhc[_tokenId];
    }

    // Set inStakedtmhc by _tokenId
    function setInStakedTMHC(uint16 _tokenId, StakeTMHC memory stake) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(_tokenId < inStakedtmhc.length, "_tokenId out of bounds");
        inStakedtmhc[_tokenId] = stake;
    }

    function setInStakedTMHCTime(uint16 _tokenId) public {
        inStakedtmhc[_tokenId].lastUpdateTime = block.timestamp;
    }

    function delInStakedTMHC(uint16 _tokenId) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(_tokenId < inStakedtmhc.length, "_tokenId out of bounds");
        delete inStakedtmhc[_tokenId];
    }

    // Get rewardsEarned for a user
    function getRewardsEarned(address user) public view returns (uint256) {
        return users[user].rewardsEarned;
    }

    // Get stakedteam for a user
    function getStakedUserTeam(address user) public view returns (uint16[] memory) {
        return users[user].stakedteam;
    }

    // Get stakedtmhc for a user
    function getStakedUserTmhc(address user) public view returns (uint16[] memory) {
        return users[user].stakedtmhc;
    }

    // Get stakedmomo for a user
    function getStakedUserMomo(address user) public view returns (uint16[] memory) {
        return users[user].stakedmomo;
    }

    // Add rewardsEarned for a user
    function addRewardsEarned(address user, uint256 rewards) public {
        users[user].rewardsEarned = users[user].rewardsEarned + rewards;
    }

    // Push team id to stakedteam for a user
    function pushStakedTeam(address user, uint16 teamId) public {
        users[user].stakedteam.push(teamId);
    }

    // Push tmhc id to stakedtmhc for a user
    function pushStakedTmhc(address user, uint16 tmhcId) public {
        users[user].stakedtmhc.push(tmhcId);
    }

    // Push momo id to stakedmomo for a user
    function pushStakedMomo(address user, uint16 momoId) public {
        users[user].stakedmomo.push(momoId);
    }

    // Pop a specific team id from stakedteam for a user
    function popStakedTeam(address user, uint16 tokenId) public {
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
    function popStakedTmhc(address user, uint16 tokenId) public {
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
    function popStakedMomo(address user, uint16 tokenId) public {
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
    function procAddUser(address _player) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if(users[_player].stakedtmhc.length == 0 && users[_player].stakedmomo.length == 0 && users[_player].stakedteam.length ==0){
            usersArray.push(_player);
        }
    }

    /**
    * @dev Deletes the caller's address from the usersArray if they have no staked tokens.
    */
    function procDelUser(address _player) public  onlyRole(DEFAULT_ADMIN_ROLE) {
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