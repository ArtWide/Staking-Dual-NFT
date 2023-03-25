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
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

import "./RewardVault.sol";

contract TMHCRebornStake is PermissionsEnumerable, Initializable, ReentrancyGuard{
    // Staking pool onwer / admin
    address private owner;
    // Operation status of the Pool.
    bool public PauseStake;
    // Staking user array for cms.

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor() initializer {}

    function initialize(IERC1155 _EditionToken, IERC721 _NFTtoken, NTSRewardVault _RewardVault, uint256 _rewardPerHour, address _owner) external initializer {
        owner = _owner;
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        tmhcToken = _EditionToken;
        momoToken = _NFTtoken;
        rewardVault = _RewardVault;
        rewardPerHour = _rewardPerHour;
    }

    // Staking target ERC1155 NFT contract - TMHC
    IERC1155 public tmhcToken;
    // Staking target ERC721 NFT contract - MOMO
    IERC721 public momoToken;
    // Reward ERC20 Token contract
    NTSRewardVault public rewardVault;
    // Reward per each block (for eth, about 13~15 sec)
    uint256 public rewardPerHour;    

    event Staked(address indexed user, uint tokenType, uint16 [] indexed tokenId);       
    event unStaked(address indexed user, uint tokenType, uint16[] boostId);    
    event RewardPaid(address indexed user, uint256 reward);
    event StakedTeam(address indexed user, uint16 indexed leaderId, uint16[] boostId);
    event unStakedTeam(address indexed user, uint16 indexed leaderId);

    // 스테이킹 사용자를 관리합니다. 사용자가 현재까지 받은 리워드를 기록합니다.
    struct StakeUser{
        uint256 rewardsEarned;
        uint16[] stakedteam;
        uint16[] stakedtmhc;
        uint16[] stakedmomo;
    }

    // Staking user array for cms.
    address[] public usersArray;
    mapping(address=>StakeUser) public users;

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
                            User Control
    //////////////////////////////////////////////////////////////*/

    function procAddUser() internal {
        if(users[msg.sender].stakedtmhc.length == 0 && users[msg.sender].stakedmomo.length == 0 && users[msg.sender].stakedteam.length ==0){
            usersArray.push(msg.sender);
        }
    }
    function procDelUser() internal {
        if(users[msg.sender].stakedtmhc.length == 0 && users[msg.sender].stakedmomo.length == 0 && users[msg.sender].stakedteam.length ==0){
            address[] memory _userArray = usersArray;
            for(uint256 i = 0; i <_userArray.length; i++){
                if(_userArray[i] == msg.sender){
                    usersArray[i] = _userArray[_userArray.length-1];
                    usersArray.pop();
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Single Staking
    //////////////////////////////////////////////////////////////*/

    //Step1. Start single staking
    function _stake(uint _tokenType, uint16[] calldata _tokenIds) internal {
        // tokenType에 따라 0은 TMHC, 1은 MOMO를 나타냅니다.
        require(_tokenType == 0 || _tokenType == 1, "Invalid tokentype.");
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
    function _calReward(uint _tokenType, uint16 _tokenId) internal view returns (uint256 _Reward){
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
    function _calRewardAll() internal view returns(uint256 _Reward){
        uint16[] memory _sktaedtmhc = users[msg.sender].stakedtmhc;
        uint16[] memory _stakedmomo = users[msg.sender].stakedmomo;
        uint256 _totalReward = 0;

        for (uint16 i = 0; i < _sktaedtmhc.length; i++){
            uint16 _tokenId = _sktaedtmhc[i];
            _totalReward = _totalReward + _calReward(0, _tokenId);
        }

        for (uint16 i = 0; i < _stakedmomo.length; i++){
            uint16 _tokenId = _stakedmomo[i];
            _totalReward = _totalReward + _calReward(1, _tokenId);
        }
        return _totalReward;
    }
    // Step4. Claim reward
    function _claim(uint _tokenType, uint16 _tokenId) internal {
        // 전체 리워드를 계산하여 받아옵니다.
        uint256 _myReward = _calReward(_tokenType, _tokenId);
        // ERC-20 토큰 발행 함수로 교체
        rewardVault.transferToken(msg.sender, _myReward);
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
        uint256 _myReward = _calRewardAll();
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
        rewardVault.transferToken(msg.sender, _myReward); 
        // 사용자 리워드 지급 정보 저장
        users[msg.sender].rewardsEarned += _myReward;
        // 보상이 지급되었음을 나타내는 이벤트 발생
        emit RewardPaid(msg.sender, _myReward);
    }
    // Step5. unstake single staking
    function _unStake(uint _tokenType, uint16[] calldata _tokenIds) internal {
        require(_tokenType == 0 || _tokenType == 1, "Invalid tokentype.");
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

    /*///////////////////////////////////////////////////////////////
                            Multi Staking Info
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

    function _calRewardTeam(uint16 _staketeam) internal view returns (uint256 _Reward){
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

    function _calRewardTeamAll() internal view returns(uint256 _TotalReward){
        uint16[] memory _myStakeTeam = users[msg.sender].stakedteam;
        uint256 _totalReward = 0;
        for(uint16 i = 0; i < _myStakeTeam.length; i++){
            _totalReward = _totalReward + _calRewardTeam(_myStakeTeam[i]);
        }
        return _totalReward;
    }

    function _calBoostRate(uint16 _staketeam) internal view returns(uint256 _boostrate){
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
        uint256 _myReward = _calRewardTeam(_leaderId);
        // 리워드 민팅팅
        rewardVault.transferToken(msg.sender, _myReward);
        // 팀 블록타임 갱신
        inStakedteam[_leaderId].lastUpdateBlock = block.timestamp;
        // 보상이 지급되었음을 나타내는 이벤트 발생
        emit RewardPaid(msg.sender, _myReward);
    }

    function _claimTeamAll() internal {
        // 전체 리워드를 계산하여 받아옵니다.
        uint256 _myReward = _calRewardTeamAll();
        // ERC-20 토큰 발행 함수로 교체
        rewardVault.transferToken(msg.sender, _myReward); 
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
            uint256 _myReward = _calRewardTeam(_leaderId);
            // 리워드 민팅팅
            rewardVault.transferToken(msg.sender, _myReward);
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

    /*///////////////////////////////////////////////////////////////
                            Basic Staking Info
    //////////////////////////////////////////////////////////////*/
    function getStakedTMHC() public view returns(uint16[] memory stakedIds){
        return users[msg.sender].stakedtmhc;
    }

    function getStakedMOMO() public view returns(uint16[] memory stakedIds){
        return users[msg.sender].stakedmomo;
    }

    function getStakedTeam() public view returns(uint16[] memory stakedIds){
        return users[msg.sender].stakedteam;
    }

    function getTeamBoosts(uint16 _staketeam) public view returns(uint16[] memory boostIds){
        return inStakedteam[_staketeam].boostIds;
    }

    /*///////////////////////////////////////////////////////////////
                        Single Stake Interface
    //////////////////////////////////////////////////////////////*/
    function stake(uint _tokenType, uint16[] calldata _tokenIds) external nonReentrant {
        _stake(_tokenType, _tokenIds);
    }

    function claim(uint _tokenType, uint16 _tokenId) external nonReentrant {
        _claim(_tokenType, _tokenId);
    }

    function claimAll() external nonReentrant {
        _claimAll();
    }

    function unStake(uint _tokenType, uint16[] calldata _tokenIds) external nonReentrant {
        _unStake(_tokenType, _tokenIds);
    }

    function calReward(uint _tokenType, uint16 _tokenId) external view returns(uint256 _Rawrd){
        return _calReward(_tokenType, _tokenId);
    }

    function calRewardAll() external view returns(uint256 _Reward){
        return _calRewardAll();
    }

    /*///////////////////////////////////////////////////////////////
                         Multi Stake Interface
    //////////////////////////////////////////////////////////////*/
    function stakeTeam(uint16 _leaderId ,uint16[] calldata _boostIds) external nonReentrant{
        _stakeTeam(_leaderId, _boostIds);
    }

    function claimTeam(uint16 _leaderId) external nonReentrant{
        _claimTeam(_leaderId);
    }

    function calimTeamAll() external nonReentrant{
        _claimTeamAll();
    }

    function unStakeTeam(uint16[] calldata _leaderIds) external nonReentrant{
        _unStakeTeam(_leaderIds);
    }

    function calRewardTeam(uint16 _staketeam) external view returns(uint256 _TotalReward){
        return _calRewardTeam(_staketeam);
    }

    function calRewardTeamAll() external view returns (uint256 _TotalReward){
        return _calRewardTeamAll();
    }

    function calBoostRate(uint16 _staketeam) external view returns(uint256 _boostrate){
        return _calBoostRate(_staketeam);
    }

    /*///////////////////////////////////////////////////////////////
                            Admin Function
    //////////////////////////////////////////////////////////////*/
    function setAddMomoGrades(uint8[] calldata _momogrades) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for(uint256 i = 0; i < _momogrades.length; i++){
            momoGrades.push(_momogrades[i]);
        }
    }

    function setGradesBonus(uint8[10] calldata _gradesbonus) external onlyRole(DEFAULT_ADMIN_ROLE) {
        gradesBonus = _gradesbonus;
    }
    function getUserArray() public view returns(address[] memory _userArray){
        return usersArray;
    }
    function getUserCount() public view returns(uint256 _userCount){
        return usersArray.length;
    }

}