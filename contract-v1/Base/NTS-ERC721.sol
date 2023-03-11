// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./NTS-Reward.sol";

// Access Control
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

contract NTStakeNFT is PermissionsEnumerable {
    // Staking Handler
    address public Handler;
    // Staking pool onwer / admin
    address private owner;
    // Staking target ERC721 NFT contract
    ERC721Enumerable public tNFT;
    // Reward ERC20 Token contract
    NTStakeReward public rewardContract;

    struct StakeNFT{
        address stakeowner;
        uint16 staketeam;
        uint256 lastUpdateBlock;
    }

    StakeNFT[10000] public inStakedNFT;

    constructor(ERC721Enumerable _tNFT, NTStakeReward _rewardContract) {
        tNFT = _tNFT;
        rewardContract = _rewardContract;
    }

    function getStakeOwner(uint16 _tokenId) public view returns (address _stakeowner){
        return inStakedNFT[_tokenId].stakeowner;
    }

    /*///////////////////////////////////////////////////////////////
               Single Stake / Rewards / unStake cycle
    //////////////////////////////////////////////////////////////*/

    //Step1. Start single staking
    function stake(address sender, uint16[] calldata _tokenIds) external {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            uint16 _tokenId = _tokenIds[i];
            // 토큰의 소유자 여부, 이미 스테이킹 여부를 확인합니다.
            require(tNFT.ownerOf(_tokenId) == sender, "not NFT owner.");
            require(inStakedNFT[_tokenId].staketeam == 0, "NFT is part of the team.");
            require(inStakedNFT[_tokenId].stakeowner != sender, "NFT already staked.");
            // 스테이킹 정보 저장장
            StakeNFT memory _stakenft = StakeNFT(sender, 0, block.timestamp);
            inStakedNFT[_tokenId] = _stakenft;
        }
    }

    function unStake(address sender, uint16[] calldata _tokenIds) external {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            uint16 _tokenId = _tokenIds[i];
            uint256 _myReward = calReward(sender, _tokenId);
            // 토큰의 소유자 여부, 이미 스테이킹 여부를 확인합니다.
            require(tNFT.ownerOf(_tokenId) == sender, "not NFT721 owner.");
            require(inStakedNFT[_tokenId].stakeowner == sender, "NFT721 not staked.");
            require(inStakedNFT[_tokenId].staketeam == 0 , "NFT721 is on the team.");
            // 리워드 처리
            rewardContract.mintReward(sender, _myReward);
            delete inStakedNFT[_tokenId];
        }
    }

    function chkOwner(address sender, uint16 _tokenId) external view returns(bool allOwner){
        if(tNFT.ownerOf(_tokenId) == sender){
            return true;
        }
        return false;
    }

    function stakeBoost(address sender, uint16 _leaderId, uint16 [] calldata _boostIds) external {
        for (uint16 i = 0; i < _boostIds.length; i++) {
            uint16 _tokenId = _boostIds[i];
            // 토큰의 소유자 여부, 이미 스테이킹 여부를 확인합니다.
            require(tNFT.ownerOf(_tokenId) == sender, "not NFT owner.");
            require(inStakedNFT[_tokenId].staketeam == 0, "NFT is part of the team.");
            require(inStakedNFT[_tokenId].stakeowner != sender, "NFT already staked.");
            // 스테이킹 정보 저장장
            StakeNFT memory _stakenft = StakeNFT(sender, _leaderId, block.timestamp);
            inStakedNFT[_tokenId] = _stakenft;
        }
    }

    function unStakeTeam(address sender, uint16 _leaderId, uint16 [] calldata _boostIds) external {
        for (uint16 i = 0; i < _boostIds.length; i++) {
            uint16 _tokenId = _boostIds[i];
            // 토큰의 소유자 여부, 이미 스테이킹 여부를 확인합니다.
            if(tNFT.ownerOf(_tokenId) == sender && inStakedNFT[_tokenId].stakeowner == sender && inStakedNFT[_tokenId].staketeam == _leaderId){
                delete inStakedNFT[_tokenId];
            }
        }
    }

    // Step2. Calculation reward
    function calReward(address sender, uint16 _tokenId) public view returns (uint256 _Reward){
        // 토큰의 소유자 여부, 이미 스테이킹 여부를 확인합니다.
        if(tNFT.ownerOf(_tokenId) == sender && inStakedNFT[_tokenId].stakeowner == sender){
            uint256 _rewardPerHour = rewardContract.getRewardPerHour();
            uint256 _stakeTime = (block.timestamp - inStakedNFT[_tokenId].lastUpdateBlock);
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
        if (_myReward == 0 || inStakedNFT[_tokenId].staketeam != 0) { return; }
        // 블록타임 초기화
        inStakedNFT[_tokenId].lastUpdateBlock = block.timestamp;
        // ERC-20 토큰 발행 함수로 교체
        rewardContract.mintReward(sender, _myReward);
    }

    function getTotalSupply() public view returns (uint256 _supply) {
        return tNFT.totalSupply();
    }
}