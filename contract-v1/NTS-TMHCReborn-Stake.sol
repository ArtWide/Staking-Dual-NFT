// SPDX-License-Identifier: BSL 1.1

/* 
*This code is subject to the Business Source License version 1.1
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved
*/
pragma solidity ^0.8.17;
import "./Base/NTS-UserManager.sol";
import "./Base/NTS-ERC721.sol";
import "./Base/NTS-ERC1155.sol";
import "./Base/NTS-Reward.sol";
import "./Base/NTS-MultiNFT.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TMHCRebornStake is ReentrancyGuardUpgradeable, NTStakeUserManager {
    using SafeMath for uint256;
    // Staking pool onwer / admin
    address private owner;
    // Staking target ERC1155 NFT contract - TMHC
    NTStakeEdition private tmhcStake;
    ERC721Enumerable public tNFT;
    // Staking target ERC721 NFT contract - MOMO
    NTStakeNFT private momoStake;
    IERC1155 public tEdition;
    // Staking Multi(721, 1155)
    NTStakeMulti private teamStake;
    // Operation status of the Pool.
    bool public PauseStake;
    // NTS UserManager
    mapping(address=>StakeUser) public users;


    constructor(NTStakeNFT _NFTStake, NTStakeEdition _EditionStake, NTStakeMulti _MultiStake, ERC721Enumerable _tNFT, IERC1155 _tEdition) {
        tmhcStake = _EditionStake;
        momoStake = _NFTStake;
        teamStake = _MultiStake;
        tNFT = _tNFT;
        tEdition = _tEdition;
    }

    // User Control Interface
    function addStakeUser() internal {
        if(users[msg.sender].stakedmomo == 0 && users[msg.sender].stakedtmhc == 0){
            addUser();
        }
    }

    function delStakeUser() internal {
        if(users[msg.sender].stakedmomo == 0 && users[msg.sender].stakedtmhc == 0){
            delUser();
        }
    }

    function chkOwner721(uint16 _tokenId) internal view returns(bool allOwner){
        if(tNFT.ownerOf(_tokenId) == msg.sender){
            return true;
        }
        return false;
    }

    function chkOwner1155(uint16 _tokenId) internal view returns(bool allOwner){
        
        if(tEdition.balanceOf(msg.sender, _tokenId) == 1){
            return true;
        }
        return false;
    }

    //ERC721 MOMO Stake Interface
    function stakeMOMO(uint16[] calldata _tokenIds) external nonReentrant{
        _stakeMOMO(_tokenIds);
    }

    function unStakeMOMO(uint16[] calldata _tokenIds) external nonReentrant {
        _unStakeMOMO(_tokenIds);
    }

    function claimMOMO(uint16[] calldata _tokenIds) external nonReentrant{
        _claimMOMO(_tokenIds);
    }

    function claimMOMOAll() external nonReentrant {
        _claimMOMOAll();
    }

    //ERC1155 TMHC Stake Inteface
    function stakeTMHC(uint16[] calldata _tokenIds) external nonReentrant{
        _stakeTMHC(_tokenIds);
    }

    function unStakeTMHC(uint16[] calldata _tokenIds) external nonReentrant {
        _unStakeTMHC(_tokenIds);
    }

    function claimTMHC(uint16[] calldata _tokenIds) external nonReentrant{
        _claimTMHC(_tokenIds);
    }

    function claimTMHCAll() external nonReentrant{
        _claimTMHCAll();
    }

    // Multi NFT Stake Interface
    function stakeTeam(uint16 _leaderId, uint16[] calldata _boostIds) external nonReentrant{
        _stakeTeam(_leaderId, _boostIds);
    } 

    function unStakeTeam(uint16 _leaderId) external nonReentrant{
        _unStakeTeam(_leaderId);
    }

    function claimTeam(uint16 _leaderId) external nonReentrant{
        _claimTeam(_leaderId);
    }

    function claimTeamAll() external nonReentrant{
        _claimTeamAll();
    }

    // MOMO Internal Logic
    function _stakeMOMO(uint16[] calldata _tokenIds) internal {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            uint16 _tokenId = _tokenIds[i];
            require(chkOwner721(_tokenId), "Not MOMO Ownewr");
        }
        momoStake.stake(msg.sender, _tokenIds);
        addStakeUser();
        users[msg.sender].stakedmomo = add(users[msg.sender].stakedmomo, _tokenIds.length);
    }

    function _unStakeMOMO(uint16[] calldata _tokenIds) internal {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            uint16 _tokenId = _tokenIds[i];
            require(chkOwner721(_tokenId), "Not MOMO Ownewr");
        }
        momoStake.unStake(msg.sender, _tokenIds);
        users[msg.sender].stakedmomo = sub(users[msg.sender].stakedmomo, _tokenIds.length);
        delStakeUser();
    }

    function _claimMOMO(uint16[] calldata _tokenIds) internal {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            uint16 _tokenId = _tokenIds[i];
            momoStake.claim(msg.sender, _tokenId);
        }
    }

    function _claimMOMOAll() internal {
        uint16[] memory _stakedmomos = getMyStakedMOMO();
        for (uint16 i = 0; i < _stakedmomos.length; i++) {
            uint16 _tokenId = _stakedmomos[i];
            momoStake.claim(msg.sender, _tokenId);
        }
    }
    
    function getMOMOOwner(uint16 _tokenId) internal view returns(address _stakeowner){
        return momoStake.getStakeOwner(_tokenId);
    }

    function getMyStakedMOMO() public view returns(uint16[] memory _stakedmomo){
        uint16 _stakesize = users[msg.sender].stakedmomo;
        if (_stakesize == 0) {
            return new uint16[](0);
        }

        uint16[] memory _stakedmomos = new uint16[](_stakesize);
        uint16 _index = 0;
        for (uint16 i = 0; i < momoStake.getTotalSupply(); i++){
            if(getMOMOOwner(i) == msg.sender){
                _stakedmomos[_index] = i;
                _index = _index + 1;
                if(_index >= _stakesize){
                    break;
                }
            }
        }
        return _stakedmomos;
    }

    function getRewardMOMO(uint16[] memory _tokenIds) public view returns(uint256 _totalReward){
        return momoStake.calRewardBatch(msg.sender, _tokenIds);
    }

    function getRewardMOMOAll() external view returns(uint256 _totalReward){
        uint16[] memory myStakedMOMO = getMyStakedMOMO();
        _totalReward = getRewardMOMO(myStakedMOMO);
        return _totalReward;
    }

    // TMHC Internal Logic
    function _stakeTMHC(uint16[] calldata _tokenIds) internal {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            uint16 _tokenId = _tokenIds[i];
            require(chkOwner1155(_tokenId), "Not TMHC Ownewr");
        }
        tmhcStake.stake(msg.sender, _tokenIds);
        addStakeUser();
        users[msg.sender].stakedtmhc = add(users[msg.sender].stakedtmhc, _tokenIds.length);
    }

    function _unStakeTMHC(uint16[] calldata _tokenIds) internal{
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            uint16 _tokenId = _tokenIds[i];
            require(chkOwner1155(_tokenId), "Not TMHC Ownewr");
        }
        tmhcStake.unStake(msg.sender, _tokenIds);
        users[msg.sender].stakedtmhc = sub(users[msg.sender].stakedtmhc, _tokenIds.length);
        delStakeUser();
    }

    function _claimTMHC(uint16[] calldata _tokenIds) internal {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            uint16 _tokenId = _tokenIds[i];
            tmhcStake.claim(msg.sender, _tokenId);
        }
    }

    function _claimTMHCAll() internal {
        uint16[] memory _tmhcStake = getMyStakedTMHC();
        for (uint16 i = 0; i < _tmhcStake.length; i++) {
            uint16 _tokenId = _tmhcStake[i];
            tmhcStake.claim(msg.sender,_tokenId);
        }
    }
    
    function getTMHCOwner(uint16 _tokenId) internal view returns(address _stakeowner){
        return tmhcStake.getStakeOwner(_tokenId);
    }

    function getMyStakedTMHC() public view returns(uint16[] memory _stakedtmhc){
        uint16 _stakesize = users[msg.sender].stakedtmhc;
        if (_stakesize == 0) {
            return new uint16[](0);
        }
        uint16[] memory _staketmhcs = new uint16[](_stakesize);
        uint16 _index;
        for (uint16 i = 0; i < 10000; i++){
            if(getTMHCOwner(i) == msg.sender){
                _staketmhcs[_index] = i;
                _index ++;
                if(_index >= _stakesize){
                    break;
                }
            }
        }
        return _staketmhcs;
    }

    function getRewardTMHC(uint16[] memory _tokenIds) public view returns(uint256 _totalReward){
        return tmhcStake.calRewardBatch(msg.sender, _tokenIds);
    }

    function getRewardTMHCAll() external view returns(uint256 _totalReward){
        uint16[] memory myStakedTMHC = getMyStakedTMHC();
        _totalReward = getRewardTMHC(myStakedTMHC);
        return _totalReward;
    }

    // Multi NFT Stake Logic
    function _stakeTeam(uint16 _leaderId, uint16[] calldata _boostIds) internal {
        teamStake.stakeTeam(msg.sender, _leaderId, _boostIds);
        addStakeUser();
        users[msg.sender].stakedteam = add(users[msg.sender].stakedteam, 1);
    }

    function _unStakeTeam(uint16 _leaderId) internal {
        teamStake.unStakeTeam(msg.sender, _leaderId);
        users[msg.sender].stakedteam = sub(users[msg.sender].stakedteam, 1);
        delStakeUser();
    }

    function _claimTeam(uint16 _leaderId) internal {
        teamStake.claimTeam(msg.sender, _leaderId);
    }

    function _claimTeamAll() internal {
        uint16[] memory _stakedteams = getMyStakedTeam();
        for (uint16 i = 0; i < _stakedteams.length; i++) {
            uint16 _leaderId = _stakedteams[i];
            teamStake.claimTeam(msg.sender, _leaderId);
        }
    }

    function getMyStakedTeam() public view returns (uint16[] memory _stakedteams){
        uint16 _stakesize = users[msg.sender].stakedteam;
        if (_stakesize == 0) {
            return new uint16[](0);
        }
        uint16[] memory _staketeams = new uint16[](_stakesize);
        uint16 _index;
        for (uint16 i = 0; i < 10000; i++){
            if(getTMHCOwner(i) == msg.sender){
                _staketeams[_index] = i;
                _index ++;
                if(_index >= _stakesize){
                    break;
                }
            }
        }
        return _staketeams;
    }

    function getRewardTeam(uint16[] memory _leaderIds) public view returns(uint256 _totalReward){
        return teamStake.calRewardBatch(msg.sender, _leaderIds);
    }

    function getRewardTeamAll() external view returns(uint256 _totalReward){
        uint16[] memory myStakedTeam = getMyStakedTeam();
        _totalReward = getRewardTeam(myStakedTeam);
        return _totalReward;
    }
}
