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
import "./module/RewardVault.sol";


contract TMHCRebornStakeU2 is PermissionsEnumerable, Initializable, ReentrancyGuard, NTStakeMulti{
    // TMHC Reborn Stake Upgradeable Contract Release version 0.2
    // Staking pool onwer / admin
    address private owner;
    // Operation status of the Pool.
    bool public PauseStake;
    // Claim operation status of the Pool.
    bool public PauseClaim;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/ 

    constructor(NTSRewardVault _RewardVault, NTSUserManager _userStorage, NTSGradeStorage _gradeStorage, uint256 _rewardPerHour, uint256 _rewardPerHourSub, address _owner) initializer {
        owner = _owner;
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        rewardVault = _RewardVault;
        userStorage = _userStorage;
        gradeStorage = _gradeStorage;
        rewardPerHour = _rewardPerHour;
        rewardPerHourSub = _rewardPerHourSub;
        PauseStake = false;
        PauseClaim = false;
    }
    /*///////////////////////////////////////////////////////////////
                            Admin Staking Setup
    //////////////////////////////////////////////////////////////*/
    function setEditionToken(IERC1155 _EditionToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tmhcToken = _EditionToken;
    }

    function setNFTtoken(IERC721 _NFTtoken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        momoToken = _NFTtoken;
    }

    /*///////////////////////////////////////////////////////////////
                            Basic Staking Info
    //////////////////////////////////////////////////////////////*/
    /**
    * @dev Returns an array of token IDs representing all the TMHC tokens staked by the caller.
    * @return stakedIds An array of token IDs representing all the staked TMHC tokens.
    */
    function getStakedTMHC(address player) public view returns(uint16[] memory stakedIds){
        return userStorage.getStakedUserTmhc(player);
    }

    /**
    * @dev Returns an array of token IDs representing all the MOMO tokens staked by the caller.
    * @return stakedIds An array of token IDs representing all the staked MOMO tokens.
    */
    function getStakedMOMO(address player) public view returns(uint16[] memory stakedIds){
        return userStorage.getStakedUserMomo(player);
    }

    /**
    * @dev Returns an array of token IDs representing all the team tokens staked by the caller.
    * @return stakedIds An array of token IDs representing all the staked team tokens.
    */
    function getStakedTeam(address player) public view returns(uint16[] memory stakedIds){
        return userStorage.getStakedUserTeam(player);
    }

    /**
    * @dev Returns an array of boost IDs representing all the boosts for the specified team staked by the caller.
    * @param _staketeam The team ID whose boost IDs are being returned.
    * @return _TeamBoostRate An Staked team boost rate.
    */
    function getBoostsRate(address player, uint16 _staketeam) public view returns(uint256 _TeamBoostRate){
        return _getTeamBoostRate(player, _staketeam);
        
    }

    function getBoostIds(uint16 _staketeam) public view returns(uint16[] memory boostIds){
        NTSUserManager.StakeTeam memory _inStakedteam = userStorage.getInStakedTeam(_staketeam);
        return _inStakedteam.boostIds;
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
        require(!PauseStake, "Stacking pool is currently paused.");
        _stake(msg.sender, _tokenType, _tokenIds);
    }

    /**
    * @dev Claims the reward for the specified token of the given token type for the caller.
    * @param _tokenType The type of the token for which the reward is claimed (0 for TMHC, 1 for MOMO).
    * @param _tokenId The ID of the token for which the reward is claimed.
    */
    function claim(uint _tokenType, uint16 _tokenId) external nonReentrant {
        require(!PauseClaim, "The claim is currently paused.");
        _claim(msg.sender, _tokenType, _tokenId);
    }

    function claimBatch(uint _tokenType, uint16[] calldata _tokenIds) external nonReentrant {
        require(!PauseClaim, "The claim is currently paused.");
        _claimBatch(msg.sender, _tokenType, _tokenIds);
    }

    /**
    * @dev Claims the rewards for all staked tokens of the caller.
    */
    function claimAll() external nonReentrant {
        require(!PauseClaim, "The claim is currently paused.");
        _claimAll(msg.sender);
    }

    /**
    * @dev Unstakes the specified tokens of the given token type for the caller.
    * @param _tokenType The type of the tokens to be unstaked (0 for TMHC, 1 for MOMO).
    * @param _tokenIds An array of token IDs to be unstaked.
    */
    function unStake(uint _tokenType, uint16[] calldata _tokenIds) external nonReentrant {
        require(!PauseStake, "Stacking pool is currently paused.");
        _unStake(msg.sender, _tokenType, _tokenIds);
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
        require(!PauseStake, "Stacking pool is currently paused.");
        _stakeTeam(msg.sender, _leaderId, _boostIds);
    }

    /**
    * @dev Claims the reward for the specified team leader and all the boosts for the caller.
    * @param _leaderId The ID of the team leader for which the rewards are claimed.
    */
    function claimTeam(uint16 _leaderId) external nonReentrant{
        require(!PauseClaim, "The claim is currently paused.");
        _claimTeam(msg.sender, _leaderId);
    }

    function claimTeamBatch(uint16[] calldata _leaderIds) external nonReentrant{
        require(!PauseClaim, "The claim is currently paused.");
        _claimTeamBatch(msg.sender, _leaderIds);
    }

    /**
    * @dev Claims the rewards for all staked team leaders and their boosts for the caller.
    */
    function claimTeamAll() external nonReentrant{
        require(!PauseClaim, "The claim is currently paused.");
        _claimTeamAll(msg.sender);
    }

    /**
    * @dev Unstakes the specified team leaders and boosts for the caller.
    * @param _leaderIds An array of IDs of the team leaders to be unstaked.
    */
    function unStakeTeam(uint16[] calldata _leaderIds) external nonReentrant{
        require(!PauseStake, "Stacking pool is currently paused.");
        _unStakeTeam(msg.sender, _leaderIds);
    }

    function refreshTeamAll() external nonReentrant{
        _refreshAllTeam(msg.sender);
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
    function calTeamBoost(address player, uint16 _staketeam) external view returns(uint256 _boostrate){
        return _getTeamBoostRate(player, _staketeam);
    }

    /*///////////////////////////////////////////////////////////////
                            Admin Function
    //////////////////////////////////////////////////////////////*/


    /**
    * @dev Sets the reward amount per hour for the stake.
    * @param _rewardPerHour The reward amount per hour.
    */
    function setRewardPeHour(uint256 _rewardPerHour) external onlyRole(DEFAULT_ADMIN_ROLE){
        rewardPerHour = _rewardPerHour;
    }

    function setRewardPeHourSub(uint256 _rewardPerHourSub) external onlyRole(DEFAULT_ADMIN_ROLE){
        rewardPerHourSub = _rewardPerHourSub;
    }

    /**
    * @dev Pauses the staking pool.
    * @param _status The status of the pause.
    */
    function setPausePool(bool _status) external onlyRole(DEFAULT_ADMIN_ROLE){
        PauseStake = _status;
    }

    /**
    * @dev Pauses the claim of rewards.
    * @param _status The status of the pause.
    */
    function setPauseCalim(bool _status) external onlyRole(DEFAULT_ADMIN_ROLE){
        PauseClaim = _status;
    }

    /**
    * @dev Allow the admin to claim the user's staking reward for a specific token.
    * @param _player The user address to claim the reward for.
    * @param _tokenType The type of token to claim reward for.
    * @param _tokenId The token id to claim reward for.
    * Requirements:
    * - The caller must have the DEFAULT_ADMIN_ROLE.
    * - Claim must not be paused.
    */
    function adminClaim(address _player, uint _tokenType, uint16 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        require(!PauseClaim, "The claim is currently paused.");
        _claim(_player, _tokenType, _tokenId);
    }

    function adminClaimBatch(address _player, uint _tokenType, uint16[] calldata _tokenIds) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        require(!PauseClaim, "The claim is currently paused.");
        _claimBatch(_player, _tokenType, _tokenIds);
    }

    /**
    * @dev Allow the admin to claim all the user's staking rewards.
    * @param _player The user address to claim the rewards for.
    * Requirements:
    * - The caller must have the DEFAULT_ADMIN_ROLE.
    * - Claim must not be paused.
    */
    function adminClaimAll(address _player) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        require(!PauseClaim, "The claim is currently paused.");
        _claimAll(_player);
    }

    /**
    * @dev Allow the admin to claim the team's staking reward for a specific leader.
    * @param _player The user address to claim the reward for.
    * @param _leaderId The leader id to claim reward for.
    * Requirements:
    * - The caller must have the DEFAULT_ADMIN_ROLE.
    * - Claim must not be paused.
    */
    function adminClaimTeam(address _player, uint16 _leaderId) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant{
        require(!PauseClaim, "The claim is currently paused.");
        _claimTeam(_player, _leaderId);
    }

    function adminClaimTeamBatch(address _player, uint16[] calldata _leaderIds) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant{
        require(!PauseClaim, "The claim is currently paused.");
        _claimTeamBatch(_player, _leaderIds);
    }

    /**
    * @dev Allow the admin to claim all the team's staking rewards.
    * @param _player The user address to claim the rewards for.
    * Requirements:
    * - The caller must have the DEFAULT_ADMIN_ROLE.
    * - Claim must not be paused.
    */
    function adminClaimTeamAll(address _player) external nonReentrant{
        require(!PauseClaim, "The claim is currently paused.");
        _claimTeamAll(_player);
    }


    /*///////////////////////////////////////////////////////////////
                            View Function
    //////////////////////////////////////////////////////////////*/
    /**
    * @dev Returns an array of all users who have interacted with the contract.
    * @return _usersArray An array of addresses representing all the users who have interacted with the contract.
    */
    function getUsersArray() public view returns(address[] memory _usersArray){
        _usersArray = userStorage.getUsersArray();
    }

    /**
    * @dev Returns the count of all users who have interacted with the contract.
    * @return _userCount The count of all users who have interacted with the contract.
    */
    function getUserCount() public view returns(uint256 _userCount){
        address[] memory _usersArray = userStorage.getUsersArray();
        return _usersArray.length;
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