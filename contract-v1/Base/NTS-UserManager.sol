// SPDX-License-Identifier: BSL 1.1

/* 
*This code is subject to the Business Source License version 1.1
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved
*/

pragma solidity ^0.8.17;

contract NTStakeUserManager{
    // Staking user array for cms.
    address[] internal usersArray;

    struct StakeUser{
        uint256 rewardsEarned;
        uint16 stakedteam;
        uint16 stakedtmhc;
        uint16 stakedmomo;
    }

    // SafeMath Function
    function add(uint16 a, uint256 b) internal pure returns (uint16) {
        require(b <= uint256(type(uint16).max), "Value out of range");
        return uint16(a + uint16(b));
    }

    function sub(uint16 a, uint256 b) internal pure returns (uint16) {
        require(a >= uint16(b), "Subtraction result out of range");
        return uint16(a - uint16(b));
    }

    function addUser() internal {
        usersArray.push(msg.sender);
    }

    function delUser() internal {
        address[] memory _userArray = usersArray;
        for(uint256 i = 0; i <_userArray.length; i++){
            if(_userArray[i] == msg.sender){
                usersArray[i] = _userArray[_userArray.length-1];
                usersArray.pop();
            }
        }
    }

    function getUserArray() external view returns(address[] memory _userArray){
        return usersArray;
    }

    function getUserCount() external view returns(uint256 _userCount){
        return usersArray.length;
    }
}