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

import "./NTS-Single.sol";
import "./NTS-UserManager.sol"; 
import "./NTS-Base.sol";

contract NTStakeMulti is NTStakeSingle {

    event StakedTeam(address indexed user, uint16 indexed leaderId, uint16[] boostId);
    event unStakedTeam(address indexed user, uint16 indexed leaderId);

    // TMHC-MOMO 결합 팀 스테이킹 여부를 저장합니다.
    struct StakeTeam{
        address stakeowner;
        uint16[] boostIds;
        uint256 lastUpdateBlock;
    }

    StakeTeam[10000] public inStakedteam;
    uint8[] public momoGrades;
    uint8[10] public gradesBonus;


    /*///////////////////////////////////////////////////////////////
                Team Stake / Rewards / unStake cycle
    //////////////////////////////////////////////////////////////*/
    function _stakeTeam(uint16 _leaderId ,uint16[] calldata _boostIds) public {
        // 리더의 오너 및 스테이킹 여부를 확인합니다.
        require(tmhcToken.balanceOf(msg.sender, _leaderId) == 1, "not TMHC owner.");
        require(inStakedtmhc[_leaderId].stakeowner != msg.sender, "TMHC already staked.");
        require(_boostIds.length <= 5, "A maximum of 5 booster NFTs are available.");


        for (uint16 i = 0; i < _boostIds.length; i++) {
            // 부스터의 오너 및 스테이킹 여부를 확인합니다.
            uint16 _boostId = _boostIds[i];
            require(momoToken.ownerOf(_boostId) == msg.sender, "not MOMO owner.");
            require(inStakedmomo[_boostId].stakeowner != msg.sender, "MOMO already staked.");

            // 모모 스테이킹 스토리지에 기록합니다.
            inStakedmomo[_boostId].staketeam = _leaderId;
            inStakedmomo[_boostId].stakeowner = msg.sender;
        }
        // TMHC 스테이킹 스토리지에 기록합니다.
        inStakedtmhc[_leaderId].staketeam = _leaderId;
        inStakedtmhc[_leaderId].stakeowner = msg.sender;

        //최초 사용자 추가
        procAddUser();

        // 사용자 팀 스테이킹 정보에 추가합니다.
        users[msg.sender].stakedteam.push(_leaderId);

        // 새로운 팀을 팀 스토리지에 기록합니다.
        StakeTeam memory newTeam = StakeTeam(msg.sender, _boostIds, block.timestamp);
        inStakedteam[_leaderId] = newTeam;        
        // 이벤트 처리
        emit StakedTeam(msg.sender, _leaderId, _boostIds);
    }

    function calRewardTeam(uint16 _staketeam) public view returns (uint256 _Reward){
        // Team staking status check
        if(inStakedteam[_staketeam].stakeowner != msg.sender){
            return 0;
        }
        
        uint16[] memory _boostIds = inStakedteam[_staketeam].boostIds;
        uint256 _lastUpdateBlock = inStakedteam[_staketeam].lastUpdateBlock;

        uint256 _tmhcReward = ((block.timestamp - _lastUpdateBlock) * rewardPerHour) / 3600;
        uint256 _totlaReward = _tmhcReward;

        for(uint16 i = 0; i < _boostIds.length; i ++)
        {
            uint16 _boostId = _boostIds[i];
            uint8 _boostGrade = momoGrades[_boostId];
            uint8 _boostRate = gradesBonus[_boostGrade];
            _totlaReward = _totlaReward + ((_tmhcReward * _boostRate) / 100);
        }

        return _totlaReward;
    }

    function calRewardTeamAll() public view returns(uint256 _TotalReward){
        uint16[] memory _myStakeTeam = users[msg.sender].stakedteam;
        uint256 _totalReward = 0;
        for(uint16 i = 0; i < _myStakeTeam.length; i++){
            _totalReward = _totalReward + calRewardTeam(_myStakeTeam[i]);
        }
        return _totalReward;
    }

    function calBoostRate(uint16 _staketeam) public view returns(uint256 _boostrate){
        // Team staking status check
        if(inStakedteam[_staketeam].stakeowner != msg.sender){
            return 0;
        }

        uint16[] memory _boostIds = inStakedteam[_staketeam].boostIds;
        uint8 _boostRate = 0;

        for(uint16 i = 0; i < _boostIds.length; i ++)
        {
            uint16 _boostId = _boostIds[i];
            if(momoToken.ownerOf(_boostId) == msg.sender)
            {
                uint8 _boostGrade =  momoGrades[_boostId];
                _boostRate = _boostRate + gradesBonus[_boostGrade];
            }else{
                _boostRate = 0;
                break;
            }

        }

        return _boostRate;
    }

    function _unsetAllBoost(uint16 _staketeam) internal{
        // 팀 해체/언스테이킹 시 부스트 해제 
        uint16[] memory _boostIds = inStakedteam[_staketeam].boostIds;
        for (uint16 i = 0; i < _boostIds.length; i++) {
            uint16 _boostId = _boostIds[i];
            if(momoToken.ownerOf(_boostId) == msg.sender){
                // 부스터의 소유권이 있을경우 부스트의 팀 해제
                inStakedmomo[_boostId].staketeam = 0;
                inStakedmomo[_boostId].stakeowner = address(0);
            }
        }
    }

    function _refreshTeam(uint16 _staketeam) internal{
        // 팀 스테이킹 리플레시
        require(inStakedteam[_staketeam].stakeowner == msg.sender, "Not Team Owner");
        uint16 _leaderId = _staketeam;
        address _stakeowner = inStakedteam[_staketeam].stakeowner;
        uint16[] memory _boostIds = inStakedteam[_staketeam].boostIds;

        //스테이킹의 소유자가 아니거나 TMHC 소유권이 없을경우 사용자의 팀에서 삭제
        if(msg.sender != _stakeowner || tmhcToken.balanceOf(msg.sender, _leaderId) != 1){
            uint16[] memory _array = users[msg.sender].stakedteam;
            for (uint i = 0; i < _array.length; i++) {
                if (_array[i] == _staketeam) {
                    users[msg.sender].stakedteam[i] = _array[_array.length - 1];
                    users[msg.sender].stakedteam.pop();
                    break;
                }
            }
            // 팀 해체에 따른 부스트 NFT의 정보 갱신(언스테이킹)
            _unsetAllBoost(_staketeam);

            // 사용자의 스테이킹 정보가 없을경우 삭제
            procDelUser();

        }else{
            //스테이킹 소유자 / TMHC 소유권 확인 된 경우 부스터만 재 확인
            //부스터 갱신을 위해 삭제 후 재 확인
            for (uint16 i = 0; i < _boostIds.length; i++) {
                // 부스터의 오너 및 스테이킹 여부를 확인합니다.
                uint16 _boostId = _boostIds[i];
                if(momoToken.ownerOf(_boostId) != msg.sender){
                    // 부스터의 소유권이 없을경우 부스터 리스트에서 제거
                    inStakedteam[_staketeam].boostIds[i] =_boostIds[_boostIds.length -1];
                    inStakedteam[_staketeam].boostIds.pop();
                }
            }
        }
    }

    function _refreshAllTeam() internal{
        uint16[] memory _myStakeTeam = users[msg.sender].stakedteam;
        for(uint16 i = 0; i < _myStakeTeam.length; i++){
            _refreshTeam(_myStakeTeam[i]);
        }
    }

    function _claimTeam(uint16 _leaderId) internal {
        // 팀 리워드 계산
        uint256 _myReward = calRewardTeam(_leaderId);
        // 리워드 민팅팅
        rewardToken.mintTo(msg.sender, _myReward);
        // 팀 블록타임 갱신
        inStakedteam[_leaderId].lastUpdateBlock = block.timestamp;
        // 보상이 지급되었음을 나타내는 이벤트 발생
        emit RewardPaid(msg.sender, _myReward);
    }

    function _claimTeamAll() internal {
        // 전체 리워드를 계산하여 받아옵니다.
        uint256 _myReward = calRewardTeamAll();
        // ERC-20 토큰 발행 함수로 교체
        rewardToken.mintTo(msg.sender, _myReward); 
        // 팀 블록체인 타임 갱신
        uint16[] memory _myStakeTeam = users[msg.sender].stakedteam;
        for(uint16 i = 0; i < _myStakeTeam.length; i++){
            inStakedteam[i].lastUpdateBlock = block.timestamp;
        }
        // 보상이 지급되었음을 나타내는 이벤트 발생
        emit RewardPaid(msg.sender, _myReward);
    }

    function _unStakeTeam(uint16[] calldata _leaderIds) internal {
        for(uint16 i = 0; i < _leaderIds.length; i++){
            uint16 _leaderId = _leaderIds[i];
            // 토큰의 소유자 여부, 이미 스테이킹 여부를 확인합니다.
            require(tmhcToken.balanceOf(msg.sender, _leaderId) == 1, "not TMHC owner.");
            require(inStakedteam[_leaderId].stakeowner == msg.sender, "not Team owner.");
            require(inStakedtmhc[_leaderId].staketeam != 0 , "TMHC is not on the team.");
            // 팀 리워드 계산
            uint256 _myReward = calRewardTeam(_leaderId);
            // 리워드 민팅팅
            rewardToken.mintTo(msg.sender, _myReward);
            // 보상이 지급되었음을 나타내는 이벤트 발생
            emit RewardPaid(msg.sender, _myReward);

            //사용자 정보에서 스테이킹 팀 삭제
            uint16[] memory _array = users[msg.sender].stakedteam;
            for (uint ii = 0; ii < _array.length; ii++) {
                if (_array[ii] == _leaderId) {
                    users[msg.sender].stakedteam[ii] = _array[_array.length - 1];
                    users[msg.sender].stakedteam.pop();
                    break;
                }
            }

            _unsetAllBoost(_leaderId);
            //사용자의 팀이 더이상 없을경우 스테이킹 사용자 삭제
            procDelUser();
            // 이벤트 로그 처리
            emit unStakedTeam(msg.sender, _leaderId);
        }
    }

    
}