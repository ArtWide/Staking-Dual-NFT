// SPDX-License-Identifier: BSL 1.1

/* 
*This code is subject to the Business Source License version 1.1
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved
*/
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./NTS-Reward.sol";

// Access Control
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

contract NTStakeEdition is PermissionsEnumerable {
    // Staking target ERC1155 NFT contract
    IERC1155 public tEdition;
    // Reward ERC20 Token contract
    NTStakeReward public rewardContract;
    uint256 totalSuply;

    event Staked(address indexed user, uint16 [] indexed tokenId);     
    event unStaked(address indexed user, uint16[] indexed boostId);   

    struct StakeEdition{
        address stakeowner;
        uint16 staketeam;
        uint256 lastUpdateBlock;
    }

    StakeEdition[10000] public inStakeEdition;

    constructor(IERC1155 _tEdition, NTStakeReward _rewardContract) {
        tEdition = _tEdition;
        rewardContract = _rewardContract;
        totalSuply = 10000;
    }

    function getStakeOwner(uint16 _tokenId) public view returns (address _stakeowner){
        return inStakeEdition[_tokenId].stakeowner;
    }

    /*///////////////////////////////////////////////////////////////
               Single Stake / Rewards / unStake cycle
    //////////////////////////////////////////////////////////////*/

    //Step1. Start single staking
    function stake(address sender, uint16[] calldata _tokenIds) external {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            uint16 _tokenId = _tokenIds[i];
            // 토큰의 소유자 여부, 이미 스테이킹 여부를 확인합니다.
            require(tEdition.balanceOf(sender, _tokenId) == 1, "not Edition owner.");
            require(inStakeEdition[_tokenId].stakeowner != sender, "Edition already staked.");
            // 스테이킹 정보 저장
            StakeEdition memory _stakedition = StakeEdition(sender, 0, block.timestamp);
            inStakeEdition[_tokenId] = _stakedition;
        }
    }

    function unStake(address sender, uint16[] calldata _tokenIds) external {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            uint16 _tokenId = _tokenIds[i];
            uint256 _myReward = calReward(sender, _tokenId);
            // 토큰의 소유자 여부, 이미 스테이킹 여부를 확인합니다.
            require(tEdition.balanceOf(sender, _tokenId) == 1, "not Edition owner.");
            require(inStakeEdition[_tokenId].stakeowner == sender, "Edition not staked.");
            require(inStakeEdition[_tokenId].staketeam == 0 , "Edition is on the team.");
            // 리워드 처리
            rewardContract.mintReward(sender, _myReward);
            // 스테이킹 정보 저장
            delete inStakeEdition[_tokenId];
        }
    }

    function unStakeTeam(address sender, uint16 _leaderId) external {
        // 토큰의 소유자 여부, 이미 스테이킹 여부를 확인합니다.
        if(tEdition.balanceOf(sender, _leaderId) == 1 && inStakeEdition[_leaderId].stakeowner == sender && inStakeEdition[_leaderId].staketeam == _leaderId){
            delete inStakeEdition[_leaderId];
        }
    }


    function chkOwner(address sender, uint16 _tokenId) external view returns(bool allOwner){
        if(tEdition.balanceOf(sender, _tokenId) == 1){
            return true;
        }
        return false;
    }

    function stakeLeader(address sender, uint16 _leaderId) external {            
        require(tEdition.balanceOf(sender, _leaderId) == 1, "not Edition owner.");
        require(inStakeEdition[_leaderId].stakeowner != sender, "Edition already staked.");
        // 스테이킹 정보 저장장
        StakeEdition memory _stakeEdition = StakeEdition(sender, _leaderId, block.timestamp);
        inStakeEdition[_leaderId] = _stakeEdition;
    }

    // Step2. Calculation reward
    function calReward(address sender, uint16 _tokenId) public view returns (uint256 _Reward){
        // 토큰의 소유자 여부, 이미 스테이킹 여부를 확인합니다.
        if(tEdition.balanceOf(sender, _tokenId) == 1 && inStakeEdition[_tokenId].stakeowner == sender){
            uint256 _rewardPerHour = rewardContract.getRewardPerHour();
            uint256 _stakeTime = (block.timestamp - inStakeEdition[_tokenId].lastUpdateBlock);
            return ((_stakeTime * _rewardPerHour) / 3600);
        }else{
            return 0;
        }
    }

    function calRewardBatch(address sender, uint16[] calldata _tokenIds) public view returns (uint256 _Reward){
        uint256 _totalReward = 0;
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            uint16 _tokenId = _tokenIds[i];
            _totalReward = _totalReward + calReward(sender, _tokenId);
        }
        return _totalReward;
    }

    // Step3. Claim reward
    function claim(address sender, uint16 _tokenId) external {
        // 전체 리워드를 계산하여 받아옵니다.
        uint256 _myReward = calReward(sender, _tokenId);
        if (_myReward == 0 || inStakeEdition[_tokenId].staketeam != 0) { return; }
        // 블록타임 초기화
        inStakeEdition[_tokenId].lastUpdateBlock = block.timestamp;
        // ERC-20 토큰 발행 함수로 교체
        rewardContract.mintReward(sender, _myReward);
    }

    function getTotalSupply() public view returns (uint256 _supply){
        return totalSuply;
    }
}