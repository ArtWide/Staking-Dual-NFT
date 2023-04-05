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

import "./NTS-Base.sol";

contract NTStakeSingle is NTSBase{

    uint256 internal SingleStakeClaimed;
    /*///////////////////////////////////////////////////////////////
               Single Stake / Rewards / unStake cycle
    //////////////////////////////////////////////////////////////*/
    
    //Step1. Start single staking
    function _stake(address player, uint _tokenType, uint16[] calldata _tokenIds) internal {
        // tokenType 0 is for TMHC, and 1 is for MOMO.
        require(_tokenType == 0 || _tokenType == 1, "Invalid tokentype.");

        if(_tokenType==0)
        {
            for (uint16 i = 0; i < _tokenIds.length; i++) {
                uint16 _tokenId = _tokenIds[i];
                // TMHC
                // Check the ownership and the staking status of the token.
                require(tmhcToken.balanceOf(player, _tokenId) == 1, "not TMHC owner.");
                NTSUserManager.StakeTMHC memory _inStakedtmhc = userStorage.getStakedTMHC(_tokenId);
                require(_inStakedtmhc.staketeam == 0, "MOMO is part of the team.");
                require(_inStakedtmhc.stakeowner != player, "TMHC already staked.");

                // Add the user to the system if they haven't staked before.
                userStorage.procAddUser(player);
                // Add the staking to the user's information.
                userStorage.pushStakedTmhc(player, _tokenId);
                // Save the staking information.
                NTSUserManager.StakeTMHC memory _staketmhc = NTSUserManager.StakeTMHC(player, 0, block.timestamp);
                userStorage.setInStakedTMHC(_tokenId, _staketmhc);
            }
        }else if(_tokenType==1){
            for (uint16 i = 0; i < _tokenIds.length; i++) {
                uint16 _tokenId = _tokenIds[i];
                // MOMO
                // Check the ownership and the staking status of the token.
                require(momoToken.ownerOf(_tokenId) == player, "not MOMO owner.");
                NTSUserManager.StakeMOMO memory _inStakedmomo = userStorage.getStakedMOMO(_tokenId);
                require(_inStakedmomo.staketeam == 0, "MOMO is part of the team.");
                require(_inStakedmomo.stakeowner != player, "MOMO already staked.");

                // Add the user to the system if they haven't staked before.
                userStorage.procAddUser(player);
                // Add the staking to the user's information.
                userStorage.pushStakedMomo(player, _tokenId);
                // Save the staking information.
                NTSUserManager.StakeMOMO memory _stakemomo = NTSUserManager.StakeMOMO(player, 0, block.timestamp);
                userStorage.setInStakedMOMO(_tokenId, _stakemomo);
            }
        }
        emit Staked(player, _tokenType, _tokenIds);    // Emit the staking event.
    }

    // Step2-1. Calculation reward
    /**
    * @dev Calculates the reward for a staked token.
    * @param _tokenType The type of the staked token (0 for TMHC, 1 for MOMO).
    * @param _tokenId The ID of the staked token.
    * @return _Reward The amount of reward for the staked token.
    */
    function _calReward(address player, uint _tokenType, uint16 _tokenId) internal view returns (uint256 _Reward){
        // The tokenType can be either 0 for TMHC or 1 for MOMO.
        uint256 _stakeTime = 0;
        if(_tokenType==0)
        {
            // TMHC
            NTSUserManager.StakeTMHC memory _inStakedtmhc = userStorage.getStakedTMHC(_tokenId);
            // Check if the token is owned by the caller and if it is already staked.
            if(tmhcToken.balanceOf(player, _tokenId) == 1 && _inStakedtmhc.stakeowner == player && _inStakedtmhc.staketeam == 0){
                // If the token is already staked, calculate the stake time.
                _stakeTime = block.timestamp - _inStakedtmhc.lastUpdateTime;
            }else{
                // If the token is not owned by the caller or not staked, return 0 as the reward.
                return 0;
            }
            // Calculate the reward based on the stake time and rewardPerHour.
            _Reward = ((_stakeTime * rewardPerHour) / 3600);
        }else if(_tokenType==1){
            // MOMO
            NTSUserManager.StakeMOMO memory _inStakedmomo = userStorage.getStakedMOMO(_tokenId);
            // Check if the token is owned by the caller and if it is already staked.
            if(momoToken.ownerOf(_tokenId) == player && _inStakedmomo.stakeowner == player && _inStakedmomo.staketeam == 0){
                // If the token is already staked, calculate the stake time.
                _stakeTime = block.timestamp - _inStakedmomo.lastUpdateTime;
            }else{
                // If the token is not owned by the caller or not staked, return 0 as the reward.
                return 0;
            }
            // Calculate the reward based on the stake time and rewardPerHourSub.
            _Reward = ((_stakeTime * rewardPerHourSub) / 3600);
        }

        return _Reward;
    }

    // Step2-2. Clculation rewalrd all stake
    /**
    * @dev Calculates the total reward for all staked tokens of the caller.
    * @return _totalReward The total reward amount for all staked tokens of the caller.
    */
    function _calRewardAll(address _player) internal view returns(uint256 _totalReward){
        // Get the list of staked TMHC and MOMO tokens for the caller.
        uint16[] memory _stakedtmhc = userStorage.getStakedUserTmhc(_player);
        uint16[] memory _stakedmomo = userStorage.getStakedUserMomo(_player);

        // Loop through all staked TMHC tokens and calculate the reward for each.
        for (uint16 i = 0; i < _stakedtmhc.length; i++){
            uint16 _tokenId = _stakedtmhc[i];
            _totalReward = _totalReward + _calReward(_player, 0, _tokenId);
        }

        // Loop through all staked MOMO tokens and calculate the reward for each.
        for (uint16 i = 0; i < _stakedmomo.length; i++){
            uint16 _tokenId = _stakedmomo[i];
            _totalReward = _totalReward + _calReward(_player, 1, _tokenId);
        }
        return _totalReward;
    }

    // Step3. Claim reward
    /**
    * @dev Claims the reward for a staked token and transfers it to the caller's address.
    * @param _tokenType The type of the staked token (0 for TMHC, 1 for MOMO).
    * @param _tokenId The ID of the staked token.
    */
    function _claim(address _player, uint _tokenType, uint16 _tokenId) internal {
        // Calculate the reward for the staked token.
        uint256 _myReward = _calReward(_player, _tokenType, _tokenId);
        
        if(_myReward > 0){
            // Transfer the reward tokens to the caller using the transferToken function of the ERC-20 token.
            rewardVault.transferToken(_player, _myReward);
            // Reset the last update block for the staked token.
            if(_tokenType==0){
                userStorage.setInStakedTMHCTime(_tokenId);
            }else if(_tokenType==1){
                userStorage.setInStakedMOMOTime(_tokenId);
            }
            // Update the user's total rewards earned and store the reward payment information.
            userStorage.addRewardsEarned(_player, _myReward);
            SingleStakeClaimed = SingleStakeClaimed + _myReward;
            // Emit an event to indicate that the reward has been paid.
            emit RewardPaid(_player, _myReward);
        }
    }

    // Step4. Claim reward all stake
    /**
    * @dev Claims the rewards for all staked tokens of the caller and transfers them to the caller's address.
    */
    function _claimAll(address _player) internal {
        // claim all staked tokens of the caller.
        uint16[] memory _stakedtmhc = userStorage.getStakedUserTmhc(_player);
        uint16[] memory _stakedmomo = userStorage.getStakedUserMomo(_player);
        for(uint16 i = 0; i < _stakedtmhc.length; i++)
        {
            _claim(_player, 0, _stakedtmhc[i]);
        }

        for(uint16 i = 0; i < _stakedmomo.length; i++)
        {
            _claim(_player, 1, _stakedmomo[i]);
        }
    }

    // Step5. unstake single staking
    /**
    * @dev Unstakes the specified tokens of the specified token type and transfers the rewards to the caller's address.
    * @param _tokenType The type of the tokens to unstake (0 for TMHC, 1 for MOMO).
    * @param _tokenIds An array of token IDs to unstake.
    */
    function _unStake(address _player, uint _tokenType, uint16[] calldata _tokenIds) internal {
        require(_tokenType == 0 || _tokenType == 1, "Invalid tokentype.");
        // Token type 0 represents TMHC and 1 represents MOMO.
        if(_tokenType==0)
        {
            for (uint16 i = 0; i < _tokenIds.length; i++) {
                uint16 _tokenId = _tokenIds[i];
                // TMHC
                // Check if the caller is the owner of the token and if the token is already staked.
                require(tmhcToken.balanceOf(_player, _tokenId) == 1, "not TMHC owner.");
                NTSUserManager.StakeTMHC memory _inStakedtmhc = userStorage.getStakedTMHC(_tokenId);
                require(_inStakedtmhc.stakeowner == _player, "TMHC not staked.");
                require(_inStakedtmhc.staketeam == 0 , "TMHC is on the team.");
                // Claim the reward before unstaking the token.
                _claim(_player, _tokenType, _tokenId);
                // Remove the staked token from the user's stakedtmhc array.
                userStorage.popStakedTmhc(_player, _tokenId);
                userStorage.delInStakedTMHC(_tokenId);
            }
        }else if(_tokenType==1){
            for (uint16 i = 0; i < _tokenIds.length; i++) {
                uint16 _tokenId = _tokenIds[i];
                // MOMO
                // Check if the caller is the owner of the token and if the token is already staked.
                require(momoToken.ownerOf(_tokenId) == _player, "not MOMO owner.");
                NTSUserManager.StakeMOMO memory _inStakedmomo = userStorage.getStakedMOMO(_tokenId);
                require(_inStakedmomo.stakeowner == _player, "MOMO not staked.");
                require(_inStakedmomo.staketeam == 0 , "TMHC is on the team.");
                // Claim the reward before unstaking the token.
                _claim(_player, _tokenType, _tokenId);
                // Remove the staked token from the user's stakedmomo array.
                userStorage.popStakedMomo(_player, _tokenId);
                userStorage.delInStakedMOMO(_tokenId);
            }
        }else{
            revert("Invalid tokentype.");
        }
        // Delete the user from the users mapping if they have no staked tokens.
        userStorage.procDelUser(_player);
        // Emit an event to indicate that the tokens have been unstaked.
        emit unStaked(_player, _tokenType, _tokenIds);    
    }

    /**
    * @dev A function to get the total unclaimed rewards across all staking players.
    * @return _totalUnClaim The total amount of unclaimed rewards.
    */
    function _getSingleUnClaim() internal view returns (uint256 _totalUnClaim) {
        address[] memory _usersArray = userStorage.getUsersArray();
        for(uint256 i = 0; i < _usersArray.length; i++)
        {   
            address _player = _usersArray[i];
            _totalUnClaim = _totalUnClaim + _calRewardAll(_player);
        }
        return _totalUnClaim;
    }

    /**
    * @dev Returns the total amount of rewards claimed for single staking.
    * @return _SingleStakeClaimed The total amount of rewards claimed for single staking.
    */
    function _getSingleClaimed() internal view returns(uint256 _SingleStakeClaimed){
        return SingleStakeClaimed;
    }
}