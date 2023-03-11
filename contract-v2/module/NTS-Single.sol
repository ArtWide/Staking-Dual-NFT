// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@thirdweb-dev/contracts/token/TokenERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./NTS-UserManager.sol"; 
import "./NTS-Base.sol";

contract NTStakeSingle is NTSUserManager, NTSBase {
    // MOMO NFT 중심으로 스테이킹 여부를 저장합니다.
    struct StakeMOMO{
        address stakeowner;
        uint16 staketeam;
        uint256 lastUpdateBlock;
    }

    // TMHC NFT 중심으로 스테이킹 여부를 저장합니다.
    struct StakeTMHC{
        address stakeowner;
        uint16 staketeam;
        uint256 lastUpdateBlock;
    }

    StakeMOMO[10000] public inStakedmomo;
    StakeTMHC[10000] public inStakedtmhc;

    /*///////////////////////////////////////////////////////////////
               Single Stake / Rewards / unStake cycle
    //////////////////////////////////////////////////////////////*/

    //Step1. Start single staking
    function _stake(uint _tokenType, uint16[] calldata _tokenIds) internal {
        // tokenType에 따라 0은 TMHC, 1은 MOMO를 나타냅니다.
        require(_tokenType == 1 || _tokenType == 2, "Invalid tokentype.");
        if(_tokenType==0)
        {
            for (uint16 i = 0; i < _tokenIds.length; i++) {
                uint16 _tokenId = _tokenIds[i];
                // TMHC
                // 토큰의 소유자 여부, 이미 스테이킹 여부를 확인합니다.
                require(tmhcToken.balanceOf(msg.sender, _tokenId) == 1, "not TMHC owner.");
                require(inStakedtmhc[_tokenId].staketeam == 0, "MOMO is part of the team.");
                require(inStakedtmhc[_tokenId].stakeowner != msg.sender, "TMHC already staked.");
                //최초 사용자 추가
                procAddUser();
                // 사용자 정보에 스테이킹 추가
                users[msg.sender].stakedtmhc.push(_tokenId);
                // 스테이킹 정보 저장
                StakeTMHC memory _staketmhc = StakeTMHC(msg.sender, 0, block.timestamp);
                inStakedtmhc[_tokenId] = _staketmhc;
            }
        }else if(_tokenType==1){
            for (uint16 i = 0; i < _tokenIds.length; i++) {
                uint16 _tokenId = _tokenIds[i];
                // MOMO
                // 토큰의 소유자 여부, 이미 스테이킹 여부를 확인합니다.
                require(momoToken.ownerOf(_tokenId) == msg.sender, "not MOMO owner.");
                require(inStakedmomo[_tokenId].staketeam == 0, "MOMO is part of the team.");
                require(inStakedmomo[_tokenId].stakeowner != msg.sender, "MOMO already staked.");
                //최초 사용자 추가
                procAddUser();
                // 사용자 정보에 스테이킹 추가
                users[msg.sender].stakedmomo.push(_tokenId);
                // 스테이킹 정보 저장
                StakeMOMO memory _stakemomo = StakeMOMO(msg.sender, 0, block.timestamp);
                inStakedmomo[_tokenId] = _stakemomo;
            }
        }
        emit Staked(msg.sender, _tokenType, _tokenIds);    // 스테이킹 이벤트를 발생시킴
    }
    // Step2. Calculation reward
    function calReward(uint _tokenType, uint16 _tokenId) public view returns (uint256 _Reward){
        // tokenType에 따라 0은 TMHC, 1은 MOMO를 나타냅니다.
        uint256 _stakeTime = 0;
        if(_tokenType==0)
        {
            // TMHC
            // 토큰의 소유자 여부, 이미 스테이킹 여부를 확인합니다.
            if(tmhcToken.balanceOf(msg.sender, _tokenId) == 1 && inStakedtmhc[_tokenId].stakeowner == msg.sender && inStakedtmhc[_tokenId].staketeam == 0){
                _stakeTime = _stakeTime + (block.timestamp - inStakedtmhc[_tokenId].lastUpdateBlock);
            }else{
                return 0;
            }
        }else if(_tokenType==1){
            // MOMO
            // 토큰의 소유자 여부, 이미 스테이킹 여부를 확인합니다.
            if(momoToken.ownerOf(_tokenId) == msg.sender && inStakedmomo[_tokenId].stakeowner == msg.sender && inStakedmomo[_tokenId].staketeam == 0){
                _stakeTime = _stakeTime + (block.timestamp - inStakedmomo[_tokenId].lastUpdateBlock);
            }else{
                return 0;
            }
        }
        return ((_stakeTime * rewardPerHour) / 3600);
    }
    // Step2. Clculation rewalrd all stake
    function calRewardAll() public view returns(uint256 _Reward){
        uint16[] memory _sktaedtmhc = users[msg.sender].stakedtmhc;
        uint16[] memory _stakedmomo = users[msg.sender].stakedmomo;
        uint256 _totalReward = 0;

        for (uint16 i = 0; i < _sktaedtmhc.length; i++){
            uint16 _tokenId = _sktaedtmhc[i];
            _totalReward = _totalReward + calReward(0, _tokenId);
        }

        for (uint16 i = 0; i < _stakedmomo.length; i++){
            uint16 _tokenId = _stakedmomo[i];
            _totalReward = _totalReward + calReward(1, _tokenId);
        }
        return _totalReward;
    }
    // Step4. Claim reward
    function _claim(uint _tokenType, uint16 _tokenId) internal {
        // 전체 리워드를 계산하여 받아옵니다.
        uint256 _myReward = calReward(_tokenType, _tokenId);
        // ERC-20 토큰 발행 함수로 교체
        rewardToken.mintTo(msg.sender, _myReward);
        // 블록타임 초기화
        if(_tokenType==0){
            inStakedtmhc[_tokenId].lastUpdateBlock = block.timestamp;
        }else if(_tokenType==1){
            inStakedmomo[_tokenId].lastUpdateBlock = block.timestamp;
        }
        // 사용자 리워드 지급 정보 저장
        users[msg.sender].rewardsEarned += _myReward;
        // 보상이 지급되었음을 나타내는 이벤트 발생
        emit RewardPaid(msg.sender, _myReward);
    }
    // Step4. Claim reward all stake
    function _claimAll() internal {
        // 전체 리워드를 계산하여 받아옵니다.
        uint256 _myReward = calRewardAll();
        // 블록타임 초기화
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

        // ERC-20 토큰 발행 함수로 교체
        rewardToken.mintTo(msg.sender, _myReward); 
        // 사용자 리워드 지급 정보 저장
        users[msg.sender].rewardsEarned += _myReward;
        // 보상이 지급되었음을 나타내는 이벤트 발생
        emit RewardPaid(msg.sender, _myReward);
    }
    // Step5. unstake single staking
    function _unStake(uint _tokenType, uint16[] calldata _tokenIds) internal {
        require(_tokenType == 1 || _tokenType == 2, "Invalid tokentype.");
        // @dev tokenType에 따라 0은 TMHC, 1은 MOMO를 나타냅니다.
        if(_tokenType==0)
        {
            for (uint16 i = 0; i < _tokenIds.length; i++) {
                uint16 _tokenId = _tokenIds[i];
                // TMHC
                // @dev 토큰의 소유자 여부, 이미 스테이킹 여부를 확인합니다.
                require(tmhcToken.balanceOf(msg.sender, _tokenId) == 1, "not TMHC owner.");
                require(inStakedtmhc[_tokenId].stakeowner == msg.sender, "TMHC not staked.");
                require(inStakedtmhc[_tokenId].staketeam == 0 , "TMHC is on the team.");
                // 스테이킹 해제 전 리워드
                _claim(_tokenType, _tokenId);
                // 사용자 정보에 스테이킹 삭제
                uint16[] memory _array = users[msg.sender].stakedtmhc;
                for (uint ii = 0; ii < _array.length; ii++) {
                    if (_array[ii] == _tokenId) {
                        // Remove the element at index i by overwriting it with the last element
                        // and then decrementing the array's length.
                        users[msg.sender].stakedtmhc[ii] = _array[_array.length - 1];
                        users[msg.sender].stakedtmhc.pop();
                        break;
                    }
                }
                // 스테이킹 정보 저장
                delete inStakedtmhc[_tokenId];
            }
        }else if(_tokenType==1){
            for (uint16 i = 0; i < _tokenIds.length; i++) {
                uint16 _tokenId = _tokenIds[i];
                // MOMO
                // @dev 토큰의 소유자 여부, 이미 스테이킹 여부를 확인합니다.
                require(momoToken.ownerOf(_tokenId) == msg.sender, "not MOMO owner.");
                require(inStakedmomo[_tokenId].stakeowner == msg.sender, "MOMO not staked.");
                require(inStakedmomo[_tokenId].staketeam == 0 , "TMHC is on the team.");
                // 스테이킹 해제 전 리워드
                _claim(_tokenType, _tokenId);
                // 사용자 정보에 스테이킹 삭제제
                uint16[] memory _array = users[msg.sender].stakedmomo;
                for (uint ii = 0; ii < _array.length; ii++) {
                    if (_array[ii] == _tokenId) {
                        // Remove the element at index i by overwriting it with the last element
                        // and then decrementing the array's length.
                        users[msg.sender].stakedmomo[ii] = _array[_array.length - 1];
                        users[msg.sender].stakedmomo.pop();
                        break;
                    }
                }
                // 스테이킹 정보 저장
                delete inStakedmomo[_tokenId];
            }
        }else{
            revert("Invalid tokentype.");
        }
        // 사용자의 스테이킹이 없을경우 삭제
        procDelUser();
        emit unStaked(msg.sender, _tokenType, _tokenIds);    // 스테이킹 이벤트를 발생시킴
    }
}