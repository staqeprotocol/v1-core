# Staqe Protocol

<div style="text-align:center" align="center">
    <img src="https://raw.githubusercontent.com/staqeprotocol/v1-core/master/image.svg" width="300">
</div>

The Staqe is a versatile and robust Ethereum smart contract designed to facilitate a comprehensive staking system. It allows users to stake ERC20 or ERC721 tokens in various pools to earn rewards in ERC20 tokens. The contract is designed to support multiple staking pools, each with its unique configuration and rules, providing flexibility and opportunities for diverse staking strategies.

## Features

- **Multiple Staking Pools**: Create and manage various staking pools, each with distinct configurations for staked tokens and rewards.
- **ERC20 and ERC721 Staking**: Supports staking of both ERC20 and ERC721 tokens, catering to a broad range of assets and user preferences.
- **Reward Allocation**: Distribute ERC20 token rewards to stakers, with customizable rules based on the pool's configuration and the user's staked assets.
- **Dynamic Staking and Unstaking**: Users can stake and unstake their tokens at any time, according to the rules defined by each pool.
- **Reward Claims**: Stakers can claim their earned rewards after a specified number of blocks, ensuring fair distribution based on the staking duration and amount.
- **Transparent Operations**: The contract employs events and custom errors to provide clear feedback and tracking of all operations and state changes.

## Contract Interfaces

- **IStaqe**: The main interface defining the core functionalities like pool creation, staking, reward management, and unstaking.
- **IStaqeStructs**: Defines various data structures used by the contract, including Pool, Reward, Stake, StakerPool, and StakerReward.
- **IStaqeEvents**: Declares events emitted by the contract, offering insights into its operations and changes.
- **IStaqeErrors**: Lists custom errors for precise feedback on failed operations or invalid actions within the contract.

## Core Functionalities

### Pool Management

- **launchPool**: Create a new staking pool with specific parameters for staked tokens and rewards.
- **editPool**: Update the metadata of an existing pool, allowing dynamic adjustments by the pool's rewarder.

### Staking and Unstaking

- **stake**: Deposit ERC20 or ERC721 tokens into a pool to participate in reward distribution.
- **unstake**: Withdraw staked tokens from a pool, potentially after claiming due rewards.

### Reward Management

- **addReward**: Allocate rewards to a pool, defining the reward amount, token, and eligibility criteria.
- **claimRewards**: Retrieve earned rewards from one or multiple pools, transferred to a specified recipient address.

## Event Logging

- Events like `PoolLaunched`, `StakeCreated`, `StakeWithdrawn`, `RewardAdded`, and `RewardClaimed` provide transparency and traceability for all significant actions and state changes within the contract.

## Error Handling

- Custom errors like `InvalidStakeToken`, `RewardIsEmpty`, `PoolDoesNotExist`, and others offer specific and actionable feedback for unsuccessful operations.

## Usage

The Staqe is intended for use in decentralized finance (DeFi) applications that require a flexible and efficient staking mechanism. It can be integrated into platforms that offer staking services, allowing users to earn rewards by locking their digital assets in a secure and decentralized manner.

## Deployment

To deploy the Staqe, compile the Solidity code with a compatible compiler (version 0.8.20 or higher) and deploy it to the Ethereum network using a suitable deployment framework or toolchain.

## License

The Staqe is licensed under the Business Source License 1.1 (BUSL-1.1).
