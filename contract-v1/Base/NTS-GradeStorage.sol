// SPDX-License-Identifier: BSL 1.1

/* 
*This code is subject to the Business Source License version 1.1
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved
*/
pragma solidity ^0.8.17;

contract NTStakeGradeStorage{
    address private owner;
    uint8[] nftGrades;
    uint8[10] boostBonus = [10,20,30,40,50,60,70,80,90,100];

    constructor() {
        owner = msg.sender;
    }

    /*///////////////////////////////////////////////////////////////
                            Admin Function
    //////////////////////////////////////////////////////////////*/
    function setNftGrades(uint8[] calldata _grades) public {
        require(msg.sender == owner, "Not owner");
        for(uint256 i = 0; i < _grades.length; i++){
            nftGrades.push(_grades[i]);
        }
    }

    function getNftGrade(uint16 _tokenId) public view returns(uint8 _grade){
        return nftGrades[_tokenId];
    }

    function getBoostBonus(uint8 _grade) public view returns(uint8 _boost){
        return boostBonus[_grade];
    }
}