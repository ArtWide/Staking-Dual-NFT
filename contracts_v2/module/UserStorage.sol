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


    function getStakedMOMO(uint256 _tokenId) external view returns(address _stakeowner, uint16 _staketeam, uint256 _lastUpdateTime){
        return (inStakedmomo[_tokenId].stakeowner ,inStakedmomo[_tokenId].staketeam, inStakedmomo[_tokenId].lastUpdateTime); 
    }

    function setStakedMOMO(uint256 _tokenId, address _stakeowner, uint16 _staketeam, uint256 _lastUpdateTime) external onlyRole(DEFAULT_ADMIN_ROLE){
        StakeMOMO memory _stakemomo = StakeMOMO(_stakeowner, _staketeam, _lastUpdateTime);
        inStakedmomo[_tokenId] = _stakemomo;
    }

    function getStakedTMHC(uint256 _tokenId) external view returns(address _stakeowner, uint16 _staketeam, uint256 _lastUpdateTime){
        return (inStakedtmhc[_tokenId].stakeowner ,inStakedtmhc[_tokenId].staketeam, inStakedtmhc[_tokenId].lastUpdateTime); 
    }

    function setStakedTMHC(uint256 _tokenId, address _stakeowner, uint16 _staketeam, uint256 _lastUpdateTime) external onlyRole(DEFAULT_ADMIN_ROLE){
        StakeTMHC memory _staketmhc = StakeTMHC(_stakeowner, _staketeam, _lastUpdateTime);
        inStakedtmhc[_tokenId] = _staketmhc;
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