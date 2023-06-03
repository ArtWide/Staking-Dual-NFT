// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

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

contract StakeEventLogger is PermissionsEnumerable, Multicall{
    event StakedTMHC(address indexed user, uint16[] tokenIds);
    event ClaimedTMHC(address indexed user, uint16[] tokenIds);
    event UnstakedTMHC(address indexed user, uint16[] tokenIds);
    event StakedMOMO(address indexed user, uint16[] tokenIds);
    event ClaimedMOMO(address indexed user, uint16[] tokenIds);
    event UnstakedMOMO(address indexed user, uint16[] tokenIds);
    event StakedTeam(address indexed user, uint16 leaderId, uint16[] boostIds);
    event UnstakedTeam(address indexed user, uint16 leaderId, uint16[] boostIds);
    event RewardPaid(address indexed user, uint256 reward);

    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    constructor(address adminAddr) {
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddr);
        _setupRole(FACTORY_ROLE, adminAddr);
    }

    function stakeTMHC(address user, uint16[] memory tokenIds) external onlyRole(FACTORY_ROLE){
        emit StakedTMHC(user, tokenIds);
    }

    function claimTMHC(address user, uint16[] memory tokenIds) external onlyRole(FACTORY_ROLE){
        emit ClaimedTMHC(user, tokenIds);
    }

    function unstakeTMHC(address user, uint16[] memory tokenIds) external onlyRole(FACTORY_ROLE){
        emit UnstakedTMHC(user, tokenIds);
    }

    function stakeMOMO(address user, uint16[] memory tokenIds) external onlyRole(FACTORY_ROLE){
        emit StakedMOMO(user, tokenIds);
    }

    function claimMOMO(address user, uint16[] memory tokenIds) external onlyRole(FACTORY_ROLE){
        emit ClaimedMOMO(user, tokenIds);
    }

    function unstakeMOMO(address user, uint16[] memory tokenIds) external onlyRole(FACTORY_ROLE){
        emit UnstakedMOMO(user, tokenIds);
    }

    function stakeTeam(address user, uint16 leaderId, uint16[] memory boostIds) external onlyRole(FACTORY_ROLE){
        emit StakedTeam(user, leaderId, boostIds);
    }

    function unstakeTeam(address user, uint16 leaderId, uint16[] memory boostIds) external onlyRole(FACTORY_ROLE){
        emit UnstakedTeam(user, leaderId, boostIds);
    }

    function RewardPay(address user, uint256 reward) external onlyRole(FACTORY_ROLE){
        emit RewardPaid(user, reward);
    }
}
