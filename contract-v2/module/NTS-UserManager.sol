// SPDX-License-Identifier: BSL 1.1

/* 
*This code is subject to the Business Source License version 1.1
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved
*/
pragma solidity ^0.8.17;

contract NTSUserManager {

    // 스테이킹 사용자를 관리합니다. 사용자가 현재까지 받은 리워드를 기록합니다.
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
    // 최초 사용자일 경우 등록, 기존 사용자라면 삭제
    function procAddUser() internal {
        if(users[msg.sender].stakedtmhc.length == 0 && users[msg.sender].stakedmomo.length == 0 && users[msg.sender].stakedteam.length ==0){
            usersArray.push(msg.sender);
        }
    }
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