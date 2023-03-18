// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

contract NTSRewardVault is PermissionsEnumerable {
    using SafeERC20 for IERC20;
    IERC20 private _acceptedToken;

    constructor(IERC20 acceptedToken) {
        _acceptedToken = acceptedToken;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function receiveToken(uint256 amount) external {
        _acceptedToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function transferToken(address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE){
        _acceptedToken.safeTransfer(recipient, amount);
    }

    function getTokenBalance() public view returns (uint256) {
        return _acceptedToken.balanceOf(address(this));
    }

    function setRole(address _address) external onlyRole(DEFAULT_ADMIN_ROLE){
        _setupRole(DEFAULT_ADMIN_ROLE, _address);
    }
}