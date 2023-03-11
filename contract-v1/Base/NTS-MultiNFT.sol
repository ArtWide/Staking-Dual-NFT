// SPDX-License-Identifier: BSL 1.1

/* 
*This code is subject to the Business Source License version 1.1
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved
*/
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./NTS-ERC721.sol";
import "./NTS-ERC1155.sol";
import "./NTS-Reward.sol";
import "./NTS-GradeStorage.sol";

// Access Control
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

contract NTStakeMulti {
    // Staking target ERC1155 NFT contract - TMHC
    NTStakeEdition private tmhcStake;
    // Staking target ERC721 NFT contract - MOMO
    NTStakeNFT private momoStake;
    // Reward ERC20 Token contract
    NTStakeReward public rewardContract;
    // Boost Grade storage
    NTStakeGradeStorage public GradeStorage;

    constructor(NTStakeReward _rewardContract, NTStakeNFT _NFTStake, NTStakeEdition _EditionStake, NTStakeGradeStorage _GradeStorage) {
        rewardContract = _rewardContract;
        tmhcStake = _EditionStake;
        momoStake = _NFTStake;
        GradeStorage = _GradeStorage;
    }

    struct StakeTeam{
        address stakeowner;
        uint16[] boostIds;
        uint256 lastUpdateBlock;
    }

    StakeTeam[10000] public inStakedTeam;

    function chkOwnerAll(address sender, uint16 _leaderId, uint16[] memory _boostIds) internal view returns (bool _ownAll){
        if(tmhcStake.chkOwner(sender, _leaderId) == false){ return false;}
        for (uint16 i = 0; i < _boostIds.length; i++) {
            if(momoStake.chkOwner(sender, _boostIds[i]) == false){ return false;}
        }
        return true;
    }

    function stakeTeam(address sender, uint16 _leaderId, uint16[] calldata _boostIds) external{
        require(chkOwnerAll(sender, _leaderId, _boostIds), "Not Token Owner");
        tmhcStake.stakeLeader(sender, _leaderId);
        momoStake.stakeBoost(sender, _leaderId, _boostIds);

        StakeTeam memory _staketeam = StakeTeam(sender, _boostIds, block.timestamp);
        inStakedTeam[_leaderId] = _staketeam;
    }

    function unStakeTeam(address sender, uint16 _leaderId) external {
        uint16[] memory _boostIds = inStakedTeam[_leaderId].boostIds;
        require(chkOwnerAll(sender, _leaderId, _boostIds), "Not Token Owner");
        tmhcStake.unStakeTeam(sender, _leaderId);
        momoStake.unStakeTeam(sender, _leaderId, _boostIds);
    }

    function calReward(address sender, uint16 _leaderId) public view returns (uint256 _totlaReward){
        if(tmhcStake.chkOwner(sender, _leaderId) == false){ return 0;}

        _totlaReward = 0;
        uint256 _rewardPerHour = rewardContract.getRewardPerHour();
        uint256 _stakeTime = (block.timestamp - inStakedTeam[_leaderId].lastUpdateBlock);
        uint256 _tmhcReward = ((_stakeTime * _rewardPerHour) / 3600);

        uint16[] memory _boostIds = inStakedTeam[_leaderId].boostIds;
        for (uint16 i = 0; i < _boostIds.length; i++) {
            if(momoStake.chkOwner(sender, _boostIds[i]) == false){return 0;}
            uint16 _boostId = _boostIds[i];
            uint8 _boostGrade = GradeStorage.getNftGrade(_boostId);
            uint8 _boostRate = GradeStorage.getBoostBonus(_boostGrade);
            _totlaReward = _totlaReward + ((_tmhcReward * _boostRate) / 100);
        }
        return _totlaReward;
    }

    function calRewardBatch(address sender, uint16[] calldata _leaderIds) public view returns (uint256 _totalReward){
        _totalReward = 0;
        for (uint16 i = 0; i < _leaderIds.length; i++) {
            uint16 _leaderId = _leaderIds[i];
            _totalReward = _totalReward + calReward(sender, _leaderId);
        }
        return _totalReward;
    }

    function claimTeam(address sender, uint16 _leaderId) external {
        uint256 _myReward = calReward(sender, _leaderId);
        if (_myReward == 0){ return; }
        // 블록타임 초기화
        inStakedTeam[_leaderId].lastUpdateBlock = block.timestamp;
        // ERC-20 토큰 발행 함수로 교체
        rewardContract.mintReward(sender, _myReward);
    }

    function getTeamBoost(uint16 _leaderId) public view returns (uint16[] memory _boostIds){
        return inStakedTeam[_leaderId].boostIds;
    }
    
}