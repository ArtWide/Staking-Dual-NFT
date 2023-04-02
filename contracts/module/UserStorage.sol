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

    /*///////////////////////////////////////////////////////////////
                            Internal Function
    //////////////////////////////////////////////////////////////*/
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