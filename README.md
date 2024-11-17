# Staqe Protocol

<div style="text-align:center" align="center">
    <img src="https://raw.githubusercontent.com/staqeprotocol/v1-core/master/image.svg" width="600">
</div>

# Staqe Protocol

Staqe is a cutting-edge, decentralized protocol that allows users to stake NFTs and ERC20 tokens through uniquely created liquidity pools. This non-custodial platform enables anyone to set up their own pool by defining both on-chain data (like ERC20 and ERC721 addresses for staking and rewards) and off-chain data (such as pool name, description, and visual identity) stored securely on IPFS.

<div style="text-align:center" align="center">
    <img src="https://raw.githubusercontent.com/staqeprotocol/v1-core/master/scr.png" width="600">
</div>

## Overview

Staqe is a comprehensive staking platform built on Ethereum, enabling users to stake ERC20 and ERC721 tokens. It offers a versatile environment where users can participate in various staking pools, earn rewards, and even create their own pools if they possess a Genesis NFT. This contract allows dynamic staking pool creation, management, and interaction, with each pool featuring distinct settings and reward mechanisms. Additionally, the platform supports cross-chain reward claims using Chainlink's CCIP for ERC20Q tokens.

## Features

- **ERC20 and ERC721 Token Staking**: Users can stake both types of tokens in designated pools.
- **Genesis Pool**: Stake in the Genesis pool to gain the ability to create new pools.
- **Pool Creation**: Users can launch new pools, defining the staking and reward tokens, maximum staking limits, and other configurations.
- **Reward System**: Pool owners can add rewards to incentivize staking, with detailed mechanisms for reward distribution, including cross-chain rewards via Chainlink CCIP.
- **Ownership and Transferability**: Each pool is an ERC721 token itself, allowing for ownership transfer and pool trading.
- **Flexible Staking/Unstaking**: Users have the freedom to stake and unstake tokens anytime without penalties.
- **Claim Rewards**: Stakers can claim their due rewards from pools they've participated in, with support for cross-chain reward claims.
- **Decentralized and Non-Custodial**: Staqe’s commitment to a serverless, fully decentralized architecture is evident in its requirement for users to provide a Pinata token to handle metadata uploads, ensuring that all operations remain on-chain and resistant to central points of failure.
- **Browser Extension**: To enhance user experience and engagement, Staqe offers a browser extension. This tool allows pool creators and stakers to monitor pool activities, including the volume of staked assets and the distribution of rewards.

## How It Works

### Pool Creation

<div style="text-align:center" align="center">
    <img src="https://raw.githubusercontent.com/staqeprotocol/v1-core/master/nft.png" width="600">
</div>

The pool creation process is straightforward yet secure. It requires users to be active stakers in the Genesis pool, which can be joined by minting a Genesis NFT directly on the pool's page. This requirement ensures a committed community and adds a foundational layer to the protocol's security.

Each pool on Staqe operates as its own entity, compliant with the NFT standard, and is transferable, meaning it can be sold or transferred to other users just like any other NFT. This feature adds a layer of versatility and ownership that is not commonly found in traditional staking environments.

### Metadata and Token Lists

<div style="text-align:center" align="center">
    <img src="https://raw.githubusercontent.com/staqeprotocol/v1-core/master/tokenlists.png" width="600">
</div>

The metadata associated with each pool adheres to the ERC721 standard and the "tokenlists" protocol, ensuring full transparency and compatibility within the Ethereum ecosystem. The metadata includes detailed information about the tokens and visual elements associated with the pool.

### Browser Extension

<div style="text-align:center" align="center">
    <img src="https://raw.githubusercontent.com/staqeprotocol/v1-core/master/extensions.png" width="600">
</div>

To enhance user experience and engagement, Staqe offers a browser extension. This tool allows pool creators and stakers to monitor pool activities, including the volume of staked assets and the distribution of rewards.

### Staking and Rewards

<div style="text-align:center" align="center">
    <img src="https://raw.githubusercontent.com/staqeprotocol/v1-core/master/reward.png" width="600">
</div>

For stakers, the protocol provides the flexibility to stake both NFTs and ERC20 tokens. Rewards are distributed based on the pool settings defined by the creator, who can also set specific times for reward claims, adding another layer of customization to the staking process.

## Contract Interactions

### Launching a Pool

To create a new pool, users must have staked in the Genesis pool. The `launchPool` function is used to set up a new pool, specifying the staking and reward tokens, maximum staking limits, and `tokenURI` for the pool's NFT representation.

```solidity
function launchPool(
    IERC20 stakeERC20,
    IERC721 stakeERC721,
    IERC20 rewardToken,
    uint256 totalMax,
    string memory tokenURI
) external override nonReentrant returns (uint256 poolId);
```

### Staking Tokens

Users can stake tokens using the `stake` function, providing the pool ID, amount (for ERC20), or token ID (for ERC721). The contract records and tracks each stake.

```solidity
function stake(
    uint256 poolId,
    uint256 amount,
    uint256 id
) external override nonReentrant returns (uint256 stakeId);
```

### Adding Rewards

Pool owners can add rewards to their pools with the `addReward` function, defining the reward token, amount, and eligibility criteria.

```solidity
function addReward(
    uint256 poolId,
    IERC20 rewardToken,
    uint256 rewardAmount,
    uint256 claimAfterBlocks,
    bool isForERC721Stakers
) external override nonReentrant returns (uint256 rewardId);
```

### Unstaking Tokens

Tokens can be unstaked at any time using the `unstake` function, which requires the pool ID and the stake IDs to be unstaked.

```solidity
function unstake(
    uint256 poolId,
    uint256[] calldata stakeIds
) external override nonReentrant returns (uint256 amountERC20, uint256[] memory idsERC721);
```

### Claiming Rewards

Users claim their rewards using the `claimRewards` function, specifying the pools and reward IDs they wish to claim. This function supports cross-chain reward claims using Chainlink's CCIP for ERC20Q tokens, allowing users to claim rewards across different blockchain networks.

```solidity
function claimRewards(
    uint256[] memory poolIds,
    uint256[][] memory rewardIds,
    address recipient
) external override nonReentrant returns (IERC20[][] memory tokens, uint256[][] memory amounts);
```

## Conclusion

In summary, Staqe provides a versatile and user-centric platform for the crypto community, offering innovative solutions for creating, managing, and participating in staking pools. This protocol not only enhances liquidity and engagement within the blockchain ecosystem but also paves the way for new forms of asset interaction and reward systems.

By combining ERC20 and ERC721 staking capabilities with customizable pools and rewards, Staqe stands out as a unique platform that empowers users to actively participate in the DeFi space while maintaining full control over their assets.

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
