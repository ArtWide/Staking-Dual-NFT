// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

import "./module/NTS-Multi.sol";
import "./module/NTS-UserManager.sol";
import "./module/RewardVault.sol";


contract TMHCRebornStakeR5 is PermissionsEnumerable, Initializable, ReentrancyGuard, NTStakeMulti{
    // Staking pool onwer / admin
    address private owner;
    // Operation status of the Pool.
    bool public PauseStake;
    // Staking user array for cms.

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(IERC1155 _EditionToken, IERC721 _NFTtoken, NTSRewardVault _RewardVault, uint256 _rewardPerHour, address _owner) initializer {
        owner = _owner;
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        tmhcToken = _EditionToken;
        momoToken = _NFTtoken;
        rewardVault = _RewardVault;
        rewardPerHour = _rewardPerHour;
    }

    /*///////////////////////////////////////////////////////////////
                            Basic Staking Info
    //////////////////////////////////////////////////////////////*/
    /**
    * @dev Returns an array of token IDs representing all the TMHC tokens staked by the caller.
    * @return stakedIds An array of token IDs representing all the staked TMHC tokens.
    */
    function getStakedTMHC(address player) public view returns(uint16[] memory stakedIds){
        return users[player].stakedtmhc;
    }

    /**
    * @dev Returns an array of token IDs representing all the MOMO tokens staked by the caller.
    * @return stakedIds An array of token IDs representing all the staked MOMO tokens.
    */
    function getStakedMOMO(address player) public view returns(uint16[] memory stakedIds){
        return users[player].stakedmomo;
    }

    /**
    * @dev Returns an array of token IDs representing all the team tokens staked by the caller.
    * @return stakedIds An array of token IDs representing all the staked team tokens.
    */
    function getStakedTeam(address player) public view returns(uint16[] memory stakedIds){
        return users[player].stakedteam;
    }

    /**
    * @dev Returns an array of boost IDs representing all the boosts for the specified team staked by the caller.
    * @param _staketeam The team ID whose boost IDs are being returned.
    * @return boostIds An array of boost IDs representing all the boosts for the specified team.
    */
    function getTeamBoosts(uint16 _staketeam) public view returns(uint16[] memory boostIds){
        return inStakedteam[_staketeam].boostIds;
    }

    /*///////////////////////////////////////////////////////////////
                        Single Stake Interface
    //////////////////////////////////////////////////////////////*/
    /**
    * @dev Stakes the specified tokens of the given token type for the caller.
    * @param _tokenType The type of the tokens to be staked (0 for TMHC, 1 for MOMO).
    * @param _tokenIds An array of token IDs to be staked.
    */
    function stake(uint _tokenType, uint16[] calldata _tokenIds) external nonReentrant {
        _stake(_tokenType, _tokenIds);
    }

    /**
    * @dev Claims the reward for the specified token of the given token type for the caller.
    * @param _tokenType The type of the token for which the reward is claimed (0 for TMHC, 1 for MOMO).
    * @param _tokenId The ID of the token for which the reward is claimed.
    */
    function claim(uint _tokenType, uint16 _tokenId) external nonReentrant {
        _claim(_tokenType, _tokenId);
    }

    /**
    * @dev Claims the rewards for all staked tokens of the caller.
    */
    function claimAll() external nonReentrant {
        _claimAll();
    }

    /**
    * @dev Unstakes the specified tokens of the given token type for the caller.
    * @param _tokenType The type of the tokens to be unstaked (0 for TMHC, 1 for MOMO).
    * @param _tokenIds An array of token IDs to be unstaked.
    */
    function unStake(uint _tokenType, uint16[] calldata _tokenIds) external nonReentrant {
        _unStake(_tokenType, _tokenIds);
    }

    /**
    * @dev Calculates the reward for the specified token of the given token type for the caller.
    * @param _tokenType The type of the token for which the reward is to be calculated (0 for TMHC, 1 for MOMO).
    * @param _tokenId The ID of the token for which the reward is to be calculated.
    * @return _Reward The amount of reward for the specified token.
    */
    function calReward(address player, uint _tokenType, uint16 _tokenId) external view returns(uint256 _Reward){
        return _calReward(player, _tokenType, _tokenId);
    }

    /**
    * @dev Calculates the total reward for all staked tokens of the caller.
    * @return _totalReward The total reward amount for all staked tokens of the caller.
    */
    function calRewardAll(address player) external view returns(uint256 _totalReward){
        return _calRewardAll(player);
    }

    /*///////////////////////////////////////////////////////////////
                         Multi Stake Interface
    //////////////////////////////////////////////////////////////*/
    /**
    * @dev Stakes the specified team leader and boosts for the caller.
    * @param _leaderId The ID of the team leader to be staked.
    * @param _boostIds An array of IDs of the boosts to be staked.
    */
    function stakeTeam(uint16 _leaderId ,uint16[] calldata _boostIds) external nonReentrant{
        _stakeTeam(_leaderId, _boostIds);
    }

    /**
    * @dev Claims the reward for the specified team leader and all the boosts for the caller.
    * @param _leaderId The ID of the team leader for which the rewards are claimed.
    */
    function claimTeam(uint16 _leaderId) external nonReentrant{
        _claimTeam(_leaderId);
    }

    /**
    * @dev Claims the rewards for all staked team leaders and their boosts for the caller.
    */
    function calimTeamAll() external nonReentrant{
        _claimTeamAll();
    }

    /**
    * @dev Unstakes the specified team leaders and boosts for the caller.
    * @param _leaderIds An array of IDs of the team leaders to be unstaked.
    */
    function unStakeTeam(uint16[] calldata _leaderIds) external nonReentrant{
        _unStakeTeam(_leaderIds);
    }

    /**
    * @dev Calculates the total reward for the specified staked team.
    * @param _staketeam The ID of the team for which the reward is to be calculated.
    * @return _TotalReward The total reward amount for the specified staked team.
    */
    function calRewardTeam(address player, uint16 _staketeam) external view returns(uint256 _TotalReward){
        return _calRewardTeam(player, _staketeam);
    }

    /**
    * @dev Calculates the total reward for all staked teams of the caller.
    * @return _TotalReward The total reward amount for all staked teams of the caller.
    */
    function calRewardTeamAll(address player) external view returns (uint256 _TotalReward){
        return _calRewardTeamAll(player);
    }

    /**
    * @dev Calculates the boost rate for the specified staked team.
    * @param _staketeam The ID of the team for which the boost rate is to be calculated.
    * @return _boostrate The boost rate for the specified staked team.
    */
    function calBoostRate(uint16 _staketeam) external view returns(uint256 _boostrate){
        return _calBoostRate(_staketeam);
    }

    /*///////////////////////////////////////////////////////////////
                            Admin Function
    //////////////////////////////////////////////////////////////*/
    /**
    * @dev Sets the MOMO grades to be used for calculating the bonus rate.
    * @param _momogrades An array of MOMO grades to be added to the existing grades.
    * Requirements:
    * - The function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    */
    function setAddMomoGrades(uint8[] calldata _momogrades) external onlyRole(DEFAULT_ADMIN_ROLE){
        for(uint256 i = 0; i < _momogrades.length; i++){
            momoGrades.push(_momogrades[i]);
        }
    }

    /**
    * @dev Sets the bonus rates for each token grade.
    * @param _gradesbonus An array of bonus rates for each token grade.
    * Requirements:
    * - The function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    */
    function setGradesBonus(uint8[10] calldata _gradesbonus) external onlyRole(DEFAULT_ADMIN_ROLE){
        gradesBonus = _gradesbonus;
    }


    function setRewardPeHour(uint256 _rewardPerHour) external onlyRole(DEFAULT_ADMIN_ROLE){
        rewardPerHour = _rewardPerHour;
    }

    /*///////////////////////////////////////////////////////////////
                            View Function
    //////////////////////////////////////////////////////////////*/
    /**
    * @dev Returns an array of all users who have interacted with the contract.
    * @return _userArray An array of addresses representing all the users who have interacted with the contract.
    */
    function getUserArray() public view returns(address[] memory _userArray){
        return usersArray;
    }

    /**
    * @dev Returns the count of all users who have interacted with the contract.
    * @return _userCount The count of all users who have interacted with the contract.
    */
    function getUserCount() public view returns(uint256 _userCount){
        return usersArray.length;
    }

    /**
    * @dev Returns the amount of claimed NTS tokens for the single staking pool.
    * @return _singleClaimed The amount of claimed NTS tokens for the single staking pool.
    */
    function getSingleClaimed() public view returns(uint256 _singleClaimed){
        return _getSingleClaimed();
    }

    /**
    * @dev Returns the amount of unclaimed NTS tokens for the single staking pool.
    * @return _singleUnClaim The amount of unclaimed NTS tokens for the single staking pool.
    */
    function getSingleUnClaim() public view returns(uint256 _singleUnClaim){
        return _getSingleUnClaim();
    }

    /**
    * @dev Returns the amount of claimed NTS tokens for the team staking pool.
    * @return _teamClaimed The amount of claimed NTS tokens for the team staking pool.
    */
    function getTeamClaimed() public view returns(uint256 _teamClaimed){
        return _getTeamClaimed();
    }

    /**
    * @dev Returns the amount of unclaimed NTS tokens for the team staking pool.
    * @return _teamUnClaim The amount of unclaimed NTS tokens for the team staking pool.
    */
    function getTeamUnClaim() public view returns(uint256 _teamUnClaim){
        return _getTeamUnClaim();
    }
}