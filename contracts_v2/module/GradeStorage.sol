// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/
pragma solidity ^0.8.17;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

contract NTStakeGradeStorage is PermissionsEnumerable{
    uint8[] nftGrades;
    uint16[4] boostBonus = [10,30,100,300];

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                            Admin Function
    //////////////////////////////////////////////////////////////*/
    function setNftGrades(uint8[] calldata _grades) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for(uint256 i = 0; i < _grades.length; i++){
            nftGrades.push(_grades[i]);
        }
    }

    function getNftGrade(uint16 _tokenId) public view returns(uint8 _grade){
        return nftGrades[_tokenId];
    }

    function getBoostBonus(uint8 _grade) public view returns(uint16 _boost){
        return boostBonus[_grade];
    }

    function getNftBonus(uint16 _tokenId) external view returns(uint16 _boost){
        uint8 _nftGrade = getNftGrade(_tokenId);
        return getBoostBonus(_nftGrade);
    }
}