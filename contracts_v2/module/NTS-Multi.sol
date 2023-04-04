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

import "./NTS-Single.sol";

contract NTStakeMulti is NTStakeSingle {

    // Event emitted when a user stakes their team.
    event StakedTeam(address indexed user, uint16 indexed leaderId, uint16[] boostId);
    // Event emitted when a user unstakes their team.
    event unStakedTeam(address indexed user, uint16 indexed leaderId);

    // Array that stores all possible grades for the team.
    uint8[] public momoGrades;
    // Array that stores all grade bonuses for the team.
    uint8[10] public gradesBonus;

    uint256 internal teamStakeClaimed;

    /**
     * @dev Check if the player is the owner of the leader token.
     */
    function chkLeaderOwner(address player, uint16 _leaderId) internal view returns (bool) {
        return tmhcToken.balanceOf(player, _leaderId) == 1;
    }

    /**
     * @dev Check if the player is the owner of the boost token.
     */
    function chkBoostOwner(address player, uint16 _boostId) internal view returns (bool) {
        return momoToken.ownerOf(_boostId) == player;
    }

    /**
     * @dev Check if the player owns both the leader and boost tokens.
     */
    function chkOwnerAll(address player, uint16 _leaderId, uint16[] memory _boostIds) internal view returns (bool){
        if(chkLeaderOwner(player, _leaderId) == false){ return false;}
        for (uint16 i = 0; i < _boostIds.length; i++) {
            if(chkBoostOwner(player, _boostIds[i]) == false){ return false;}
        }
        return true;
    }

    function _getTeamBoost(address player, uint16 _staketeam) internal view returns (uint256 _boostRates) {
        NTSUserManager.StakeTeam memory _inStakedteam = NTSUserManager.getInStakedTeam(_staketeam);
        uint16[] memory _boostIds = _inStakedteam.boostIds;
        // Add bonus rewards for each boost owned by the team.
        for(uint16 i = 0; i < _boostIds.length; i++) {
            uint16 _boostId = _boostIds[i];
            if(!chkBoostOwner(player, _boostId)) { _boostRates = 0; return _boostRates; }
            uint8 _boostGrade = momoGrades[_boostId];
            uint8 _boostRate = gradesBonus[_boostGrade];
            _boostRates = _boostRate;
        }
        return _boostRates;
    }

    /**
     * @dev Check if the player needs to refresh their staking status.
     */
    function chkRefresh(address player, uint16 _staketeam) internal view returns (bool) {
        NTSUserManager.StakeTMHC memory _inStakedtmhc = userStorage.getStakedTMHC(_staketeam);
        if(!chkLeaderOwner(player, _staketeam) && _inStakedtmhc.stakeowner == player){
            return true;
        }

        NTSUserManager.StakeMOMO memory _inStakedmomo = userStorage.getStakedMOMO(_staketeam);
        uint16[] memory _boostIds = _inStakedmomo.boostIds;
        for(uint16 i = 0; i < _boostIds.length; i++) {
            uint16 _boostId = _boostIds[i];
            if(!chkBoostOwner(player, _boostId) && _inStakedmomo.stakeowner == player){
                return true;
            }
        }
        return false;
    }

    /*///////////////////////////////////////////////////////////////
                Team Stake / Rewards / unStake cycle
    //////////////////////////////////////////////////////////////*/
    /**
    * @dev Stake a team by staking a leader NFT and booster NFTs.
    * @param _leaderId ID of the leader NFT to stake.
    * @param _boostIds Array of IDs of booster NFTs to stake.
    */
    function _stakeTeam(address _player, uint16 _leaderId, uint16[] calldata _boostIds) public {
        require(chkOwnerAll(_player, _leaderId, _boostIds), "Not NFT owner.");
        NTSUserManager.StakeTMHC memory _inStakedtmhc = userStorage.getStakedTMHC(_leaderId);
        require(_inStakedtmhc.stakeowner != _player, "TMHC already staked.");
        require(_boostIds.length <= 5, "A maximum of 5 booster NFTs are available.");

        // Stake each booster NFT.
        for (uint16 i = 0; i < _boostIds.length; i++) {
            uint16 _boostId = _boostIds[i];
            NTSUserManager.StakeMOMO memory _inStakedmomo = userStorage.getStakedMOMO(_boostId);
            require(_inStakedmomo.stakeowner != _player, "MOMO already staked.");

            _inStakedmomo.staketeam = _leaderId;
            _inStakedmomo.stakeowner = _player;
        }

        // Stake the leader NFT.
        _inStakedtmhc.staketeam = _leaderId;
        _inStakedtmhc.stakeowner = _player;

        // Add user to the user list.
        userStorage.procAddUser(_player);
        // Add the staked team to the user's staked team list.
        userStorage.pushStakedTeam(_player, _leaderId);

        // Add the staked team to the global staked team list.
        NTSUserManager.StakeTeam memory _newTeam = userStorage.StakeTeam(_player, _boostIds, block.timestamp);
        userStorage.setInStakedTeam(_leaderId, _newTeam);

        // Emit an event to indicate that a team has been staked.
        emit StakedTeam(_player, _leaderId, _boostIds);
    }

    /**
    * @dev Calculates the reward for a staked team.
    * @param _staketeam The ID of the staked team to calculate the reward for.
    * @return _totalReward The calculated reward for the staked team.
    */
    function _calRewardTeam(address player, uint16 _staketeam) internal view returns (uint256 _totalReward) {
        // If the sender is not the stakeowner of the team, return 0.
        if(!chkLeaderOwner(player, _staketeam)) { _totalReward=0; return _totalReward; }

        NTSUserManager.StakeTeam memory _inStakedteam = userStorage.getInStakedTeam(_staketeam);
                // Get the boost IDs and last update block for the staked team.
        uint256 _lastUpdateTime = _inStakedteam.lastUpdateTime;

        // Calculate the base TMHC reward for the team.
        uint256 _tmhcReward = ((block.timestamp - _lastUpdateTime) * rewardPerHour) / 3600;

        // Add bonus rewards for each boost owned by the team.
        uint256 _boostRate = _getTeamBoost(player, _staketeam);
        if(_boostRate == 0) { _totalReward=0; return _totalReward; }
        _boostRate = _boostRate / 100;
        _totalReward = _tmhcReward + (_tmhcReward * _boostRate);

        return _totalReward;
    }

    /**
    * @dev Calculates the total reward for all staked teams of the caller.
    * @return _TotalReward The total calculated reward for all staked teams of the caller.
    */
    function _calRewardTeamAll(address _player) internal view returns (uint256 _TotalReward) {
        // Get the IDs of all staked teams owned by the caller.
        uint16[] memory _myStakeTeam = userStorage.getStakedUserTeam(_player);
        uint256 _totalReward = 0;

        // Calculate the total reward for all owned staked teams.
        for(uint16 i = 0; i < _myStakeTeam.length; i++) {
            _totalReward = _totalReward + _calRewardTeam(_player, _myStakeTeam[i]);
        }

        return _totalReward;
    }

    /**
    * @dev Unsets all boosts for a staked team when the team is unstaked.
    * @param _staketeam The ID of the staked team to unset boosts for.
    */
    function _unsetAllBoost(uint16 _staketeam) internal {
        // Unset all boosts for the staked team.
        NTSUserManager.StakeTeam memory _inStakedteam = userStorage.getInStakedTeam(_staketeam);
        uint16[] memory _boostIds = _inStakedteam.boostIds;
        for(uint16 i = 0; i < _boostIds.length; i++) {
            uint16 _boostId = _boostIds[i];
            if(momoToken.ownerOf(_boostId) == msg.sender) {
                // If the caller is the owner of the boost, unset the boost's staked team.
                userStorage.delInStakedMOMO(_boostId);
            }
        }
    }

    function _refreshTeam(address _player, uint16 _staketeam) internal {
        if(chkRefresh(_player, _staketeam)){
            userStorage.popStakedTeam(_player, _staketeam);
            // If the caller has no staked teams, remove their stake from the users list.
            userStorage.procDelUser(_player);
        }else{
            return;
        }

        NTSUserManager.StakeTeam memory _inStakedteam = userStorage.getInStakedTeam(_staketeam);
        if(!chkLeaderOwner(_player, _staketeam) && _inStakedteam.stakeowner == _player){
            userStorage.delInStakedTMHC(_staketeam);
        }

        uint16[] memory _boostIds = _inStakedteam.boostIds;
        for(uint16 i = 0; i < _boostIds.length; i++) {
            uint16 _boostId = _boostIds[i];
            NTSUserManager.StakeMOMO memory _inStakedmomo = userStorage.getStakedMOMO(_boostId);
            if(!chkBoostOwner(msg.sender, _boostId) && _inStakedmomo.stakeowner == msg.sender){
                userStorage.delInStakedMOMO[_boostId];
            }
        }
    }

    /**
    * @dev Refreshes all staked teams owned by the caller by verifying ownership and updating their boosts.
    */
    function _refreshAllTeam(address _player) internal {
        // Get the IDs of all staked teams owned by the caller.
        uint16[] memory _myStakeTeam = userStorage.getStakedUserTeam(_player);

        // Refresh each staked team owned by the caller.
        for(uint16 i = 0; i < _myStakeTeam.length; i++) {
            _refreshTeam(_myStakeTeam[i]);
        }
    }

    /**
    * @dev Calculates the reward for the staked team with the given leader NFT ID, transfers the reward to the caller, updates the staked team's last update block, and emits a RewardPaid event.
    * @param _leaderId The ID of the staked team's leader NFT.
    */
    function _claimTeam(address _player, uint16 _leaderId) internal {
        // Calculate the reward for the staked team.
        uint256 _myReward = _calRewardTeam(_player, _leaderId);
        if(_myReward > 0){
            // Transfer the reward to the caller.
            rewardVault.transferToken(_player, _myReward);
            // Update the last update block for the staked team.
            inStakedteam[_leaderId].lastUpdateTime = block.timestamp;
            // Emit a RewardPaid event to indicate that the reward has been paid.
            teamStakeClaimed = teamStakeClaimed + _myReward;
            emit RewardPaid(_player, _myReward);
        }
    }

    /**
    * @dev Calculates the total reward for all staked teams owned by the caller, transfers the reward to the caller using the transferToken function of the ERC-20 reward token, updates the last update block for each staked team, and emits a RewardPaid event.
    */
    function _claimTeamAll(address _player) internal {
        // claim for each staked team owned by the caller.
        uint16[] memory _myStakeTeam = users[_player].stakedteam;
        for(uint16 i = 0; i < _myStakeTeam.length; i++) {
            _claimTeam(_player, _myStakeTeam[i]);
        }
    }

    /**
    * @dev Unstakes the teams with the given leader NFT IDs owned by the caller, calculates the reward for each team, transfers the rewards to the caller, removes the staked teams and associated boosts from the caller's stakedteam array, and emits an unStakedTeam event for each team that was unstaked.
    * @param _leaderIds An array of leader NFT IDs corresponding to the staked teams to be unstaked.
    */
    function _unStakeTeam(uint16[] calldata _leaderIds) internal {
        for(uint16 i = 0; i < _leaderIds.length; i++) {
            uint16 _leaderId = _leaderIds[i];
            // Check that the caller is the owner of the TMHC NFT, is the owner of the staked team, and the TMHC NFT is on the staked team.
            require(tmhcToken.balanceOf(msg.sender, _leaderId) == 1, "not TMHC owner.");
            require(inStakedteam[_leaderId].stakeowner == msg.sender, "not Team owner.");
            require(inStakedtmhc[_leaderId].staketeam != 0 , "TMHC is not on the team.");
            // Delete TMHC data
            delete inStakedtmhc[_leaderId];
            // Calculate the reward for the staked team.
            uint256 _myReward = _calRewardTeam(msg.sender, _leaderId);
            // Transfer the reward to the caller.
            rewardVault.transferToken(msg.sender, _myReward);
            // Emit a RewardPaid event to indicate that the reward has been paid.
            emit RewardPaid(msg.sender, _myReward);

            // Remove the staked team from the caller's stakedteam array.
            uint16[] memory _array = users[msg.sender].stakedteam;
            for (uint ii = 0; ii < _array.length; ii++) {
                if (_array[ii] == _leaderId) {
                    users[msg.sender].stakedteam[ii] = _array[_array.length - 1];
                    users[msg.sender].stakedteam.pop();
                    break;
                }
            }

            // Unset all boosts associated with the staked team.
            _unsetAllBoost(_leaderId);
            // Delete the staked user from the user mapping if the user no longer has any staked teams.
            procDelUser();
            // Emit an unStakedTeam event to indicate that the team has been unstaked.
            emit unStakedTeam(msg.sender, _leaderId);
        }
    }

    /**
    * @dev A function to get the total unclaimed rewards across all staking players.
    * @return _totalUnClaim The total amount of unclaimed rewards.
    */
    function _getTeamUnClaim() internal view returns (uint256 _totalUnClaim) {
        address[] memory _usersArray = usersArray;
        for(uint256 i = 0; i < _usersArray.length; i++)
        {   
            address _player = _usersArray[i];
            _totalUnClaim = _totalUnClaim + _calRewardTeamAll(_player);
        }
        return _totalUnClaim;
    }

    /**
    * @dev Returns the total amount of rewards claimed for team staking.
    * @return _teamStakeClaimed The total amount of rewards claimed for team staking.
    */
    function _getTeamClaimed() internal view returns(uint256 _teamStakeClaimed){
        return teamStakeClaimed;
    }
}