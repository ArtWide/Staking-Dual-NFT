# Staking-Dual-NFT(NTStaking, Non Tansfer Staking)

## Overview
NTS Staking Contract is a smart contract that enables users to stake and unstake TMHC and MOMO tokens in exchange for rewards. The contract also allows users to form teams and stake together for additional rewards. The rewards are distributed in the form of ERC-20 tokens that are held in a reward vault.

## Requirements
* Solidity v0.8.0 or higher
* OpenZeppelin v4.3.0 or higher
* Thirdweb@latest

## Features
* Stake TMHC and MOMO tokens for rewards.
* Form teams and stake together for additional rewards.
* Team Staking earns bonuses based on MOMO's grades.
* Claim rewards at any time.
* Unstake tokens at any time.
* View staked tokens, rewards earned, and team information.
* Admin can set bonus percentages for token grades and team boosts.

## Contract Architecture
* NTSRewardVault: A smart contract that holds ERC-20 tokens as rewards for stakers.
* NTSStaking: A smart contract that allows users to stake and unstake tokens, and claim rewards.
* NTSTeamStaking: A smart contract that allows users to form teams and stake together for additional rewards.
