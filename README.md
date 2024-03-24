# Staqe Protocol

<div style="text-align:center" align="center">
    <img src="https://raw.githubusercontent.com/staqeprotocol/v1-core/master/image.svg" width="600">
</div>

## Overview

Staqe is a comprehensive staking platform built on Ethereum, allowing users to stake ERC20 and ERC721 tokens. It offers a versatile environment where users can participate in various staking pools, earn rewards, and even create their own pools if they possess a Genesis NFT. This contract enables dynamic staking pool creation, management, and interaction, with each pool having its distinct settings and reward mechanisms.

## Features

- **ERC20 and ERC721 Token Staking**: Users can stake both types of tokens in designated pools.
- **Genesis Pool**: Stake in the Genesis pool to gain the ability to create new pools.
- **Pool Creation**: Users can launch new pools, defining the staking and reward tokens, maximum stake limits, and other configurations.
- **Reward System**: Pool owners can add rewards to incentivize staking, with detailed mechanisms for reward distribution.
- **Ownership and Transferability**: Each pool is an ERC721 token itself, allowing for ownership transfer and pool trading.
- **Flexible Staking/Unstaking**: Users have the freedom to stake and unstake tokens anytime without penalties.
- **Claim Rewards**: Stakers can claim their due rewards from pools they've participated in.

## Contract Interactions

### Launching a Pool

To create a new pool, users must have staked in the Genesis pool. The `launchPool` function is used to set up a new pool, specifying the staking and reward tokens, maximum staking limits, and tokenURI for the pool's NFT representation.

### Staking Tokens

Users can stake tokens using the `stake` function, providing the pool ID, amount (for ERC20), or token ID (for ERC721). The contract records and tracks each stake.

### Adding Rewards

Pool owners can add rewards to their pools with the `addReward` function, defining the reward token, amount, and eligibility criteria.

### Unstaking Tokens

Tokens can be unstaked at any time using the `unstake` function, which requires the pool ID and the stake IDs to be unstaked.

### Claiming Rewards

Users claim their rewards using the `claimRewards` function, specifying the pools and reward IDs they wish to claim.
