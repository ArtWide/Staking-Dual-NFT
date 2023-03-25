// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/
pragma solidity ^0.8.17;

contract NTSUserManager {

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
    function procAddUser() internal {
        if(users[msg.sender].stakedtmhc.length == 0 && users[msg.sender].stakedmomo.length == 0 && users[msg.sender].stakedteam.length ==0){
            usersArray.push(msg.sender);
        }
    }

    /**
    * @dev Deletes the caller's address from the usersArray if they have no staked tokens.
    */
    function procDelUser() internal {
        if(users[msg.sender].stakedtmhc.length == 0 && users[msg.sender].stakedmomo.length == 0 && users[msg.sender].stakedteam.length ==0){
            address[] memory _userArray = usersArray;
            for(uint256 i = 0; i <_userArray.length; i++){
                if(_userArray[i] == msg.sender){
                    usersArray[i] = _userArray[_userArray.length-1];
                    usersArray.pop();
                }
            }
        }
    }
}