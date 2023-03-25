// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/

pragma solidity ^0.8.17;
// Token
import "@thirdweb-dev/contracts/token/TokenERC20.sol";
// Access Control + security
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";


contract NTStakeReward is PermissionsEnumerable {
    // Minter(Reward Role)
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // Reward ERC20 Token contract
    TokenERC20 public rewardToken;
    // 
    uint256 rewardPerHour;
    //
    bool Pause = false;
    //
    event RewardPaid(address indexed user, uint256 reward);

    constructor(TokenERC20 _rewardToken, uint256 _rewardPerHour, address _defaultAdmin) {
        rewardToken = _rewardToken;
        rewardPerHour = _rewardPerHour;
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
    }

    function mintReward(address to, uint256 rewardAmount) external {
        require(Pause==false, "Pause - Reward contract");
        require(hasRole(MINTER_ROLE, msg.sender));
        rewardToken.mintTo(to, rewardAmount);
        emit RewardPaid(msg.sender, rewardAmount);
    }

    function setRewardPerHour(uint256 _rewardPerHour) external { 
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        rewardPerHour = _rewardPerHour;
    }

    function getRewardPerHour() public view returns (uint256 _rewardPerHour){
        return rewardPerHour;
    }

    function setRewardPause(bool _pause) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        Pause = _pause;
    }

    function setRole(address _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _setupRole(MINTER_ROLE, _address);
    }

    function unsetRole(address _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _setupRole(MINTER_ROLE, _address);
    }
    
}