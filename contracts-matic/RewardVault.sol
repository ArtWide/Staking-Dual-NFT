// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";

/* 
//    _______ _______ ___ ___ _______ ______  ___     ___ ______  _______     ___     _______ _______  _______ 
//   |   _   |   _   |   Y   |   _   |   _  \|   |   |   |   _  \|   _   |   |   |   |   _   |   _   \|   _   |
//   |   1___|.  1___|.  |   |.  1___|.  |   |.  |   |.  |.  |   |.  1___|   |.  |   |.  1   |.  1   /|   1___|
//   |____   |.  __)_|.  |   |.  __)_|.  |   |.  |___|.  |.  |   |.  __)_    |.  |___|.  _   |.  _   \|____   |
//   |:  1   |:  1   |:  1   |:  1   |:  |   |:  1   |:  |:  |   |:  1   |   |:  1   |:  |   |:  1    |:  1   |
//   |::.. . |::.. . |\:.. ./|::.. . |::.|   |::.. . |::.|::.|   |::.. . |   |::.. . |::.|:. |::.. .  |::.. . |
//   `-------`-------' `---' `-------`--- ---`-------`---`--- ---`-------'   `-------`--- ---`-------'`-------'
*/

/**
 * @title NTSRewardVault
 * @dev Contract to manage the rewards tokens accepted and transferred in the system.
 */
contract NTSRewardVault is PermissionsEnumerable, Multicall {
    using SafeERC20 for IERC20;
    IERC20 private _acceptedToken;

    /**
     * @dev Initializes the contract by setting the acceptedToken and granting the DEFAULT_ADMIN_ROLE to the deployer.
     * @param acceptedToken The token that will be accepted and transferred as reward.
     */
    constructor(IERC20 acceptedToken, address _admin) {
        _acceptedToken = acceptedToken;
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @dev Allows anyone to deposit tokens into the contract as a reward.
     * @param amount The amount of tokens to be transferred.
     */
    function receiveToken(uint256 amount) external {
        _acceptedToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev Allows the DEFAULT_ADMIN_ROLE to transfer tokens as rewards to a recipient.
     * @param recipient The address to which the tokens will be transferred.
     * @param amount The amount of tokens to be transferred.    
     * @param _payId.
     */
    function transferToken(address recipient, uint256 amount, uint256 _payId) external onlyRole(DEFAULT_ADMIN_ROLE){
        _acceptedToken.safeTransfer(recipient, amount);
    }

    /**
     * @dev Returns the balance of the acceptedToken held in the contract.
     * @return The balance of the acceptedToken.
     */
    function getTokenBalance() public view returns (uint256) {
        return _acceptedToken.balanceOf(address(this));
    }

    /**
     * @dev Allows the DEFAULT_ADMIN_ROLE to set a new address to the DEFAULT_ADMIN_ROLE.
     * @param _address The address to which the DEFAULT_ADMIN_ROLE will be granted.
     */
    function setRole(address _address) external onlyRole(DEFAULT_ADMIN_ROLE){
        _setupRole(DEFAULT_ADMIN_ROLE, _address);
    }
}