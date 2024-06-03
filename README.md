# Staqe Protocol

<div style="text-align:center" align="center">
    <img src="https://raw.githubusercontent.com/staqeprotocol/v1-core/master/image.svg" width="600">
</div>

## Overview

Staqe is a comprehensive staking platform built on Ethereum, enabling users to stake ERC20 and ERC721 tokens. It offers a versatile environment where users can participate in various staking pools, earn rewards, and even create their own pools if they possess a Genesis NFT. This contract allows dynamic staking pool creation, management, and interaction, with each pool featuring distinct settings and reward mechanisms. Additionally, the platform supports cross-chain reward claims using Chainlink's CCIP for ERC20Q tokens.

## Features

- **ERC20 and ERC721 Token Staking**: Users can stake both types of tokens in designated pools.
- **Genesis Pool**: Stake in the Genesis pool to gain the ability to create new pools.
- **Pool Creation**: Users can launch new pools, defining the staking and reward tokens, maximum stake limits, and other configurations.
- **Reward System**: Pool owners can add rewards to incentivize staking, with detailed mechanisms for reward distribution, including cross-chain rewards via Chainlink CCIP.
- **Ownership and Transferability**: Each pool is an ERC721 token itself, allowing for ownership transfer and pool trading.
- **Flexible Staking/Unstaking**: Users have the freedom to stake and unstake tokens anytime without penalties.
- **Claim Rewards**: Stakers can claim their due rewards from pools they've participated in, with support for cross-chain reward claims.

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

Users claim their rewards using the `claimRewards` function, specifying the pools and reward IDs they wish to claim. This function supports cross-chain reward claims using Chainlink's CCIP for ERC20Q tokens, allowing users to claim rewards across different blockchain networks.

## Dev

```
/**
 * @dev
 *      anvil --block-time 10 --chain-id 1337
 *      sleep 10 && forge script script/StaqeAnvil.s.sol --fork-url http://localhost:8545 --broadcast
 *
 *      Doc: https://github.com/mds1/multicall?tab=readme-ov-file#new-deployments
 *      cast publish "$(cat script/TX.txt)" --rpc-url http://localhost:8545
 *
 *      IPFS NFTs:     ipfs://bafybeieyb62vnkv46zr5mw3nfqlhcxt7v2frd2tu6k3cwgkqfgwmnyflme/
 *      Pool Metadata: ipfs://bafybeie6uhfmylorsaumqwuo6dyc4rtxv2k5ofm7uihb2qbwtg2v4gibja/
 *
 *      Toqen:          0x5FbDB2315678afecb367f032d93F642f64180aa3
 *      Stake ERC20:    0xa16E02E87b7454126E5E10d957A927A7F5B5d2be
 *      Stake ERC721:   0xB7A5bd0345EF1Cc5E66bf61BdeC17D2461fBd968
 *      Reward ERC20:   0xeEBe00Ac0756308ac4AaBfD76c05c4F3088B8883
 *      Genesis NFT:    0x10C6E9530F1C1AF873a391030a1D9E8ed0630D26
 *      Staqe Protocol: 0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82
 *      Other ERC20:    0x603E1BD79259EbcbAaeD0c83eeC09cA0B89a5bcC
 */
```
