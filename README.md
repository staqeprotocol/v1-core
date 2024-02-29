# Staqe Protocol

<div style="text-align:center" align="center">
    <img src="https://raw.githubusercontent.com/staqeprotocol/v1-core/master/image.svg" width="300">
</div>

This Solidity contract is a comprehensive implementation of a staking protocol designed for the Ethereum blockchain. It allows users to stake both ERC20 and ERC721 tokens in various pools and earn rewards in ERC20 tokens based on their stake proportion. Here's a detailed breakdown of its components and functionalities:

### Imports and Contract Declaration

- The contract imports interfaces (`IStaqe`, `IERC20`, `IERC721`, `IERC165`) and utility contracts (`ReentrancyGuard`, `Context`) from OpenZeppelin and the Staqe Protocol. These are used for secure contract interactions, reentrancy protection, and context management.
- `Staqe` contract implements the `IStaqe` interface, along with `Context` for access control and `ReentrancyGuard` for preventing reentrancy attacks.

### State Variables

- `_totalPools`: Tracks the total number of staking pools.
- `_pools`: Maps pool IDs to `Pool` structs, containing each pool's configuration and state.
- `_rewards`: Links pool IDs to arrays of `Reward` structs, detailing the rewards available per pool.
- `_stakes`: Maps staker addresses and pool IDs to arrays of `Stake` structs, representing the stakes a user has in a pool.
- `_claimedAmount`: Records the amount of rewards claimed by a staker in a specific pool, to prevent double claiming.

### Constructor

- Initializes the contract by creating a "Genesis Pool," which is required for launching new pools. Users must stake in the Genesis Pool to have the privilege to launch new pools.

### View Functions

- Functions like `getTotalPools()`, `getPool()`, `getRewards()`, `getStakes()`, `getClaimedAmount()`, `calculateReward()`, `blocksToReward()`, `isActiveStaker()`, and `isClaimed()` provide read-only access to contract state, allowing users to query pool details, stakes, rewards, and more.

### Transaction Functions

- `launchPool()`: Allows users who have staked in the Genesis Pool to launch new staking pools. It checks for ERC721 interface support if an ERC721 token is involved and initializes the pool with provided parameters.
- `editPool()`: Enables the rewarder of a pool to update its metadata. It ensures that the pool exists and that the metadata is not empty or unchanged.
- `stake()`: Allows users to stake ERC20 or ERC721 tokens in a specified pool. It performs validations and records the stake.
- `addReward()`: Enables the rewarder to add rewards to a pool. It validates the reward conditions and updates the rewards mapping.
- `unstake()`: Allows users to withdraw their stakes from a pool. It calculates the stakes to be returned and transfers the tokens back to the staker.
- `claimRewards()`: Enables users to claim rewards from one or more pools. It calculates the reward amounts and transfers the rewards to the specified recipient.

### Internal Functions

- `_calculateUnstake()`, `_calculateReward()`, `_blocksToReward()`, `_isClaimed()`, `_isActiveStaker()`, `_isERC721()`: Utility functions that support the main transaction functions by performing calculations, checks, and interface support validations.

### Events

- The contract emits events such as `PoolLaunched`, `PoolEdited`, `StakeCreated`, `RewardAdded`, and `StakeWithdrawn` to log significant actions and changes in the contract state, providing transparency and traceability.

### Tests

```
Ran 10 tests for test/Staqe.t.sol:StaqeTest
[PASS] testFuzz_AddReward(uint256) (runs: 256, μ: 892484, ~: 892475)
[PASS] testFuzz_AddReward_Errors(bytes32) (runs: 256, μ: 607183, ~: 607326)
[PASS] testFuzz_EditPool(bytes32) (runs: 256, μ: 555989, ~: 556413)
[PASS] testFuzz_LaunchPool(address,bytes32) (runs: 256, μ: 352910, ~: 353105)
[PASS] testFuzz_LaunchPool_Errors(address) (runs: 256, μ: 305593, ~: 305941)
[PASS] testFuzz_Stake(uint256) (runs: 256, μ: 1705191, ~: 1705187)
[PASS] testFuzz_Stake_Errors(uint256) (runs: 256, μ: 390561, ~: 390561)
[PASS] testFuzz_Unstake(uint256) (runs: 256, μ: 1197276, ~: 1197272)
[PASS] testFuzz_Unstake_Errors(uint256) (runs: 256, μ: 1234558, ~: 1234556)
[PASS] test_ClaimRewards() (gas: 4566321)
Suite result: ok. 10 passed; 0 failed; 0 skipped; finished in 447.21ms (2.19s CPU time)
```

| contracts/StaqeDeploy.sol:StaqeDeploy contract |                 |        |        |        |         |
| ---------------------------------------------- | --------------- | ------ | ------ | ------ | ------- |
| Deployment Cost                                | Deployment Size |        |        |        |         |
| 2872897                                        | 13132           |        |        |        |         |
| Function Name                                  | min             | avg    | median | max    | # calls |
| addReward                                      | 44566           | 125481 | 168478 | 214079 | 14      |
| claimRewards                                   | 105400          | 120591 | 117068 | 138854 | 8       |
| editPool                                       | 29612           | 32582  | 32728  | 35307  | 6       |
| getPool                                        | 1855            | 7188   | 1855   | 17855  | 9       |
| getRewards                                     | 3348            | 3348   | 3348   | 3348   | 3       |
| getStakes                                      | 1806            | 3664   | 4284   | 4284   | 4       |
| getTotalPools                                  | 668             | 668    | 668    | 668    | 1       |
| launchPool                                     | 34871           | 144561 | 158681 | 181321 | 23      |
| stake                                          | 29263           | 134934 | 128520 | 246721 | 84      |
| unstake                                        | 47052           | 95125  | 54814  | 189437 | 8       |

### Summary

The `Staqe` contract is a robust platform for staking ERC20 and ERC721 tokens to earn rewards. It is designed with flexibility to support multiple staking pools, each with its own configuration and reward system. The contract ensures security through reentrancy guards and leverages OpenZeppelin's contracts for standard compliant interactions with ERC tokens. The Genesis Pool mechanism for launching new pools adds a unique layer of participation and privilege, fostering an engaged and active staking community.
