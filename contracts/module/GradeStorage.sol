// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/
pragma solidity ^0.8.17;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

contract NTSGradeStorage is PermissionsEnumerable{
    uint8[] nftGrades;
    uint16[5] boostBonus = [10,30,100,300,0];

    constructor(address _admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /*///////////////////////////////////////////////////////////////
                            Admin Function
    //////////////////////////////////////////////////////////////*/
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

    /**
    * @dev Sets the MOMO grades to be used for calculating the bonus rate.
    * @param _momogrades An array of MOMO grades to be added to the existing grades.
    * Requirements:
    * - The function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    */
    function setMomoGrades(uint8[] calldata _momogrades) external onlyRole(DEFAULT_ADMIN_ROLE){
        for(uint256 i = 0; i < _momogrades.length; i++){
            nftGrades.push(_momogrades[i]);
        }
    }

    function setEditMomoGrades(uint256 startIdx, uint256 endIdx, uint8[] calldata newGrades) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(startIdx < endIdx, "Invalid range");
        require(endIdx <= nftGrades.length, "Out of bounds");

        for (uint256 i = startIdx; i < endIdx; i++) {
            nftGrades[i] = newGrades[i - startIdx];
        }
    }

    /**
    * @dev Sets the bonus rates for each token grade.
    * @param _gradesbonus An array of bonus rates for each token grade.
    * Requirements:
    * - The function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    */
    function setGradesBonus(uint8[5] calldata _gradesbonus) external onlyRole(DEFAULT_ADMIN_ROLE){
        boostBonus = _gradesbonus;
    }
}