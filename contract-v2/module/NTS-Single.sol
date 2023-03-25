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

    // Step2. Calculation reward
    /**
    * @dev Calculates the reward for a staked token.
    * @param _tokenType The type of the staked token (0 for TMHC, 1 for MOMO).
    * @param _tokenId The ID of the staked token.
    * @return The reward amount for the staked token.
    */
    function _calReward(uint _tokenType, uint16 _tokenId) internal view returns (uint256 _Reward){
        // The tokenType can be either 0 for TMHC or 1 for MOMO.
        uint256 _stakeTime = 0;
        if(_tokenType==0)
        {
            // TMHC
            // Check if the token is owned by the caller and if it is already staked.
            if(tmhcToken.balanceOf(msg.sender, _tokenId) == 1 && inStakedtmhc[_tokenId].stakeowner == msg.sender && inStakedtmhc[_tokenId].staketeam == 0){
                // If the token is already staked, calculate the stake time.
                _stakeTime = _stakeTime + (block.timestamp - inStakedtmhc[_tokenId].lastUpdateBlock);
            }else{
                // If the token is not owned by the caller or not staked, return 0 as the reward.
                return 0;
            }
        }else if(_tokenType==1){
            // MOMO
            // Check if the token is owned by the caller and if it is already staked.
            if(momoToken.ownerOf(_tokenId) == msg.sender && inStakedmomo[_tokenId].stakeowner == msg.sender && inStakedmomo[_tokenId].staketeam == 0){
                // If the token is already staked, calculate the stake time.
                _stakeTime = _stakeTime + (block.timestamp - inStakedmomo[_tokenId].lastUpdateBlock);
            }else{
                // If the token is not owned by the caller or not staked, return 0 as the reward.
                return 0;
            }
        }
        // Calculate the reward based on the stake time and rewardPerHour.
        return ((_stakeTime * rewardPerHour) / 3600);
    }

    // Step2. Clculation rewalrd all stake
    /**
    * @dev Calculates the total reward for all staked tokens of the caller.
    * @return The total reward amount for all staked tokens of the caller.
    */
    function _calRewardAll() internal view returns(uint256 _Reward){
        // Get the list of staked TMHC and MOMO tokens for the caller.
        uint16[] memory _sktaedtmhc = users[msg.sender].stakedtmhc;
        uint16[] memory _stakedmomo = users[msg.sender].stakedmomo;
        uint256 _totalReward = 0;

        // Loop through all staked TMHC tokens and calculate the reward for each.
        for (uint16 i = 0; i < _sktaedtmhc.length; i++){
            uint16 _tokenId = _sktaedtmhc[i];
            _totalReward = _totalReward + _calReward(0, _tokenId);
        }

        // Loop through all staked MOMO tokens and calculate the reward for each.
        for (uint16 i = 0; i < _stakedmomo.length; i++){
            uint16 _tokenId = _stakedmomo[i];
            _totalReward = _totalReward + _calReward(1, _tokenId);
        }
        return _totalReward;
    }

    // Step3. Claim reward
    /**
    * @dev Claims the reward for a staked token and transfers it to the caller's address.
    * @param _tokenType The type of the staked token (0 for TMHC, 1 for MOMO).
    * @param _tokenId The ID of the staked token.
    */
    function _claim(uint _tokenType, uint16 _tokenId) internal {
        // Calculate the reward for the staked token.
        uint256 _myReward = _calReward(_tokenType, _tokenId);
        // Transfer the reward tokens to the caller using the transferToken function of the ERC-20 token.
        rewardVault.transferToken(msg.sender, _myReward);
        // Reset the last update block for the staked token.
        if(_tokenType==0){
            inStakedtmhc[_tokenId].lastUpdateBlock = block.timestamp;
        }else if(_tokenType==1){
            inStakedmomo[_tokenId].lastUpdateBlock = block.timestamp;
        }
        // Update the user's total rewards earned and store the reward payment information.
        users[msg.sender].rewardsEarned += _myReward;
        // Emit an event to indicate that the reward has been paid.
        emit RewardPaid(msg.sender, _myReward);
    }

    // Step4. Claim reward all stake
    /**
    * @dev Claims the rewards for all staked tokens of the caller and transfers them to the caller's address.
    */
    function _claimAll() internal {
        // Calculate the total reward for all staked tokens of the caller.
        uint256 _myReward = _calRewardAll();
        // Reset the last update block for all staked tokens of the caller.
        uint16[] memory _stakedtmhc = users[msg.sender].stakedtmhc;
        uint16[] memory _stakedmomo = users[msg.sender].stakedmomo;
        for(uint16 i = 0; i < _stakedtmhc.length; i++)
        {
            inStakedtmhc[i].lastUpdateBlock = block.timestamp;
        }

        for(uint16 i = 0; i < _stakedmomo.length; i++)
        {
            inStakedmomo[i].lastUpdateBlock = block.timestamp;
        }

        // Transfer the reward tokens to the caller using the transferToken function of the ERC-20 token.
        rewardVault.transferToken(msg.sender, _myReward); 
        // Update the user's total rewards earned and store the reward payment information.
        users[msg.sender].rewardsEarned += _myReward;
        // Emit an event to indicate that the rewards have been paid.
        emit RewardPaid(msg.sender, _myReward);
    }

    // Step5. unstake single staking
    /**
    * @dev Unstakes the specified tokens of the specified token type and transfers the rewards to the caller's address.
    * @param _tokenType The type of the tokens to unstake (0 for TMHC, 1 for MOMO).
    * @param _tokenIds An array of token IDs to unstake.
    */
    function _unStake(uint _tokenType, uint16[] calldata _tokenIds) internal {
        require(_tokenType == 0 || _tokenType == 1, "Invalid tokentype.");
        // Token type 0 represents TMHC and 1 represents MOMO.
        if(_tokenType==0)
        {
            for (uint16 i = 0; i < _tokenIds.length; i++) {
                uint16 _tokenId = _tokenIds[i];
                // TMHC
                // Check if the caller is the owner of the token and if the token is already staked.
                require(tmhcToken.balanceOf(msg.sender, _tokenId) == 1, "not TMHC owner.");
                require(inStakedtmhc[_tokenId].stakeowner == msg.sender, "TMHC not staked.");
                require(inStakedtmhc[_tokenId].staketeam == 0 , "TMHC is on the team.");
                // Claim the reward before unstaking the token.
                _claim(_tokenType, _tokenId);
                // Remove the staked token from the user's stakedtmhc array.
                uint16[] memory _array = users[msg.sender].stakedtmhc;
                for (uint ii = 0; ii < _array.length; ii++) {
                    if (_array[ii] == _tokenId) {
                        users[msg.sender].stakedtmhc[ii] = _array[_array.length - 1];
                        users[msg.sender].stakedtmhc.pop();
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
                require(momoToken.ownerOf(_tokenId) == msg.sender, "not MOMO owner.");
                require(inStakedmomo[_tokenId].stakeowner == msg.sender, "MOMO not staked.");
                require(inStakedmomo[_tokenId].staketeam == 0 , "TMHC is on the team.");
                // Claim the reward before unstaking the token.
                _claim(_tokenType, _tokenId);
                // Remove the staked token from the user's stakedmomo array.
                uint16[] memory _array = users[msg.sender].stakedmomo;
                for (uint ii = 0; ii < _array.length; ii++) {
                    if (_array[ii] == _tokenId) {
                        users[msg.sender].stakedmomo[ii] = _array[_array.length - 1];
                        users[msg.sender].stakedmomo.pop();
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
        emit unStaked(msg.sender, _tokenType, _tokenIds);    
    }
}