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

import "./NTS-UserManager.sol";
import "./NTS-Base.sol";

contract NTStakeSingle is NTSUserManager, NTSBase {
    // Stores staking information based on MOMO NFT ownership.
    struct StakeMOMO {
        address stakeowner;
        uint16 staketeam;
        uint256 lastUpdateBlock;
    }

    // Stores staking information based on TMHC NFT ownership.
    struct StakeTMHC {
        address stakeowner;
        uint16 staketeam;
        uint256 lastUpdateBlock;
    }

    // Arrays to store staking information for MOMO and TMHC NFTs respectively.
    StakeMOMO[10000] public inStakedmomo;
    StakeTMHC[10000] public inStakedtmhc;

    uint256 internal SingleStakeClaimed;

    /*///////////////////////////////////////////////////////////////
               Single Stake / Rewards / unStake cycle
    //////////////////////////////////////////////////////////////*/

    //Step1. Start single staking
    function _stake(uint _tokenType, uint16[] calldata _tokenIds) internal {
        // tokenType 0 is for TMHC, and 1 is for MOMO.
        require(_tokenType == 0 || _tokenType == 1, "Invalid tokentype.");

        if(_tokenType==0)
        {
            for (uint16 i = 0; i < _tokenIds.length; i++) {
                uint16 _tokenId = _tokenIds[i];
                // TMHC
                // Check the ownership and the staking status of the token.
                require(tmhcToken.balanceOf(msg.sender, _tokenId) == 1, "not TMHC owner.");
                require(inStakedtmhc[_tokenId].staketeam == 0, "MOMO is part of the team.");
                require(inStakedtmhc[_tokenId].stakeowner != msg.sender, "TMHC already staked.");

                // Add the user to the system if they haven't staked before.
                procAddUser();
                // Add the staking to the user's information.
                users[msg.sender].stakedtmhc.push(_tokenId);
                // Save the staking information.
                StakeTMHC memory _staketmhc = StakeTMHC(msg.sender, 0, block.timestamp);
                inStakedtmhc[_tokenId] = _staketmhc;
            }
        }else if(_tokenType==1){
            for (uint16 i = 0; i < _tokenIds.length; i++) {
                uint16 _tokenId = _tokenIds[i];
                // MOMO
                // Check the ownership and the staking status of the token.
                require(momoToken.ownerOf(_tokenId) == msg.sender, "not MOMO owner.");
                require(inStakedmomo[_tokenId].staketeam == 0, "MOMO is part of the team.");
                require(inStakedmomo[_tokenId].stakeowner != msg.sender, "MOMO already staked.");

                // Add the user to the system if they haven't staked before.
                procAddUser();
                // Add the staking to the user's information.
                users[msg.sender].stakedmomo.push(_tokenId);
                // Save the staking information.
                StakeMOMO memory _stakemomo = StakeMOMO(msg.sender, 0, block.timestamp);
                inStakedmomo[_tokenId] = _stakemomo;
            }
        }
        emit Staked(msg.sender, _tokenType, _tokenIds);    // Emit the staking event.
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
            // Check if the token is owned by the caller and if it is already staked.
            if(tmhcToken.balanceOf(player, _tokenId) == 1 && inStakedtmhc[_tokenId].stakeowner == player && inStakedtmhc[_tokenId].staketeam == 0){
                // If the token is already staked, calculate the stake time.
                _stakeTime = _stakeTime + (block.timestamp - inStakedtmhc[_tokenId].lastUpdateBlock);
            }else{
                // If the token is not owned by the caller or not staked, return 0 as the reward.
                return 0;
            }
        }else if(_tokenType==1){
            // MOMO
            // Check if the token is owned by the caller and if it is already staked.
            if(momoToken.ownerOf(_tokenId) == player && inStakedmomo[_tokenId].stakeowner == player && inStakedmomo[_tokenId].staketeam == 0){
                // If the token is already staked, calculate the stake time.
                _stakeTime = _stakeTime + (block.timestamp - inStakedmomo[_tokenId].lastUpdateBlock);
            }else{
                // If the token is not owned by the caller or not staked, return 0 as the reward.
                return 0;
            }
        }
        // Calculate the reward based on the stake time and rewardPerHourSub.
        _Reward = ((_stakeTime * rewardPerHourSub) / 3600);
        return _Reward;
    }

    // Step2-2. Clculation rewalrd all stake
    /**
    * @dev Calculates the total reward for all staked tokens of the caller.
    * @return _totalReward The total reward amount for all staked tokens of the caller.
    */
    function _calRewardAll(address player) internal view returns(uint256 _totalReward){
        // Get the list of staked TMHC and MOMO tokens for the caller.
        uint16[] memory _sktaedtmhc = users[player].stakedtmhc;
        uint16[] memory _stakedmomo = users[player].stakedmomo;

        // Loop through all staked TMHC tokens and calculate the reward for each.
        for (uint16 i = 0; i < _sktaedtmhc.length; i++){
            uint16 _tokenId = _sktaedtmhc[i];
            _totalReward = _totalReward + _calReward(player, 0, _tokenId);
        }

        // Loop through all staked MOMO tokens and calculate the reward for each.
        for (uint16 i = 0; i < _stakedmomo.length; i++){
            uint16 _tokenId = _stakedmomo[i];
            _totalReward = _totalReward + _calReward(player, 1, _tokenId);
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
                inStakedtmhc[_tokenId].lastUpdateBlock = block.timestamp;
            }else if(_tokenType==1){
                inStakedmomo[_tokenId].lastUpdateBlock = block.timestamp;
            }
            // Update the user's total rewards earned and store the reward payment information.
            users[_player].rewardsEarned += _myReward;
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
        uint16[] memory _stakedtmhc = users[_player].stakedtmhc;
        uint16[] memory _stakedmomo = users[_player].stakedmomo;
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
                require(inStakedtmhc[_tokenId].stakeowner ==_player, "TMHC not staked.");
                require(inStakedtmhc[_tokenId].staketeam == 0 , "TMHC is on the team.");
                // Claim the reward before unstaking the token.
                _claim(_player, _tokenType, _tokenId);
                // Remove the staked token from the user's stakedtmhc array.
                uint16[] memory _array = users[_player].stakedtmhc;
                for (uint ii = 0; ii < _array.length; ii++) {
                    if (_array[ii] == _tokenId) {
                        users[_player].stakedtmhc[ii] = _array[_array.length - 1];
                        users[_player].stakedtmhc.pop();
                        break;
                    }
                }
                // Delete the staked token from the inStakedtmhc mapping.
                delete inStakedtmhc[_tokenId];
            }
        }else if(_tokenType==1){
            for (uint16 i = 0; i < _tokenIds.length; i++) {
                uint16 _tokenId = _tokenIds[i];
                // MOMO
                // Check if the caller is the owner of the token and if the token is already staked.
                require(momoToken.ownerOf(_tokenId) == _player, "not MOMO owner.");
                require(inStakedmomo[_tokenId].stakeowner == _player, "MOMO not staked.");
                require(inStakedmomo[_tokenId].staketeam == 0 , "TMHC is on the team.");
                // Claim the reward before unstaking the token.
                _claim(_player, _tokenType, _tokenId);
                // Remove the staked token from the user's stakedmomo array.
                uint16[] memory _array = users[_player].stakedmomo;
                for (uint ii = 0; ii < _array.length; ii++) {
                    if (_array[ii] == _tokenId) {
                        users[_player].stakedmomo[ii] = _array[_array.length - 1];
                        users[_player].stakedmomo.pop();
                        break;
                    }
                }
                // Delete the staked token from the inStakedmomo mapping.
                delete inStakedmomo[_tokenId];
            }
        }else{
            revert("Invalid tokentype.");
        }
        // Delete the user from the users mapping if they have no staked tokens.
        procDelUser();
        // Emit an event to indicate that the tokens have been unstaked.
        emit unStaked_player, _tokenType, _tokenIds);    
    }

    /**
    * @dev A function to get the total unclaimed rewards across all staking players.
    * @return _totalUnClaim The total amount of unclaimed rewards.
    */
    function _getSingleUnClaim() internal view returns (uint256 _totalUnClaim) {
        address[] memory _usersArray = usersArray;
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