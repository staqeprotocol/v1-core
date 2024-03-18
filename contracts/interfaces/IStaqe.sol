// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721, IERC165} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IStaqeEvents} from "@staqeprotocol/v1-core/contracts/interfaces/IStaqeEvents.sol";
import {IStaqeErrors} from "@staqeprotocol/v1-core/contracts/interfaces/IStaqeErrors.sol";
import {IStaqeStructs} from "@staqeprotocol/v1-core/contracts/interfaces/IStaqeStructs.sol";
import {IStaqeERC721} from "@staqeprotocol/v1-core/contracts/interfaces/IStaqeERC721.sol";
import {IStaqeERC7572} from "@staqeprotocol/v1-core/contracts/interfaces/IStaqeERC7572.sol";
import {IStaqeReentrancy} from "@staqeprotocol/v1-core/contracts/interfaces/IStaqeReentrancy.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 *       _                     _       _             __
 *   ___| |_ __ _  __ _  ___  (_)_ __ | |_ ___ _ __ / _| __ _  ___ ___
 *  / __| __/ _` |/ _` |/ _ \ | | '_ \| __/ _ \ '__| |_ / _` |/ __/ _ \
 *  \__ \ || (_| | (_| |  __/ | | | | | ||  __/ |  |  _| (_| | (_|  __/
 *  |___/\__\__,_|\__, |\___| |_|_| |_|\__\___|_|  |_|  \__,_|\___\___|
 *                   |_|
 *
 * @title Staqe
 * @dev This contract implements a flexible staking system where users can stake ERC20 or ERC721 tokens
 * in various pools to earn rewards in the form of ERC20 tokens. The contract supports the creation and 
 * management of multiple staking pools, each with its own configuration for staked tokens and rewards.
 * Users can stake and unstake their tokens at any time, subject to the rules of each pool, and claim
 * their earned rewards after a specified number of blocks.
 *
 * The contract extends OpenZeppelin's ReentrancyGuard to prevent reentrant calls, and Context to provide
 * information about the transaction's context. It implements the IStaqe interface, which defines the core
 * functionality for staking, unstaking, reward management, and pool configuration.
 *
 * Key Features:
 * - Create and manage multiple staking pools with different configurations.
 * - Stake ERC20 or ERC721 tokens to participate in earning rewards.
 * - Configure rewards in ERC20 tokens for each staking pool.
 * - Claim rewards after a specified number of blocks, enforcing a minimum staking period.
 * - Flexible design allowing for various staking and reward strategies.
 *
 * The contract is designed to be versatile and adaptable, supporting a wide range of staking and reward
 * mechanisms to accommodate different types of staking assets and reward distributions.
 */
abstract contract IStaqe is IStaqeEvents, IStaqeErrors, IStaqeStructs, IStaqeERC721, IStaqeERC7572, IStaqeReentrancy {
    /**
     * @dev Launches a new staking pool with specified parameters.
     * This function allows the contract caller to create a new staking pool where users can 
     * stake specific ERC20 or ERC721 tokens to earn rewards.
     *
     * Emits a {IStaqeEvents-PoolLaunched} event.
     *
     * Requirements:
     * - The caller must have certain privileges, typically being an admin or contract owner.
     * - `stakeERC20` and `stakeERC721` cannot both be zero addresses; at least one valid 
     *   token address must be provided.
     * - `rewardToken` must be a valid ERC20 token address that will be used for distributing 
     *   rewards.
     * - `rewarder` is the address authorized to manage rewards for the pool, often the same 
     *   as the caller or a dedicated rewards manager.
     * - `metadata` is field that can be used to store additional information 
     *   about the pool.
     *
     * @param stakeERC20 The ERC20 token address that users will stake in this pool. Can be 
     * the zero address if the pool is for ERC721 staking.
     * @param stakeERC721 The ERC721 token address that users will stake in this pool. Can be 
     * the zero address if the pool is for ERC20 staking.
     * @param rewardToken The ERC20 token address that will be used to distribute rewards to 
     * stakers.
     * @param totalMax Total max tokens in pool.
     * @param metadata Metadata providing additional information about the pool.
     *
     * @return poolId The ID of the newly created staking pool, which can be used to interact 
     * with the pool in future transactions.
     *
     * @custom:error InvalidStakeToken Indicates that the provided ERC20 or ERC721 token 
     * address is invalid.
     * @custom:error InvalidRewardToken Indicates that the provided reward token address is 
     * invalid.
     * @custom:error OnlyAvailableToStakersInGenesis Indicates that the function is only 
     * callable by users who are stakers in the genesis pool.
     */
    function launchPool(
        IERC20 stakeERC20,
        IERC721 stakeERC721,
        IERC20 rewardToken,
        uint256 totalMax,
        string memory metadata
    ) external virtual returns (
        uint256 poolId
    );
    
    /**
    * @dev Allows a user to stake ERC20 or ERC721 tokens into a specified pool.
    * This function records the user's stake in the pool, updating the pool's total staked 
    * amounts and the user's staking details. Users can stake either ERC20 or ERC721 tokens, 
    * but not both at the same time.
    *
    * Emits a {IStaqeEvents-StakeCreated} event when the stake is successfully created.
    *
    * Requirements:
    * - The pool specified by `poolId` must exist.
    * - At least one of `amount` or `id` must be non-zero, corresponding to the type of token 
    * being staked (ERC20 or ERC721, respectively).
    * - If staking ERC20 tokens, `amount` must be greater than zero and the user must have 
    * enough balance and allowance.
    * - If staking an ERC721 token, `id` must be a valid token ID owned by the caller.
    *
    * @param poolId The ID of the pool where the tokens are being staked.
    * @param amount The amount of ERC20 tokens to stake. Should be zero if staking an ERC721 token.
    * @param id The ID of the ERC721 token to stake. Should be zero if staking ERC20 tokens.
    *
    * @return stakeId The ID of the newly created stake record.
    *
    * @custom:error PoolDoesNotExist Indicates that the specified pool does not exist.
    * @custom:error InvalidAmountOrId Indicates that both `amount` and `id` are zero, or their 
    * values are not consistent with the token type expected by the pool.
    * @custom:error StakeTransferFailed Indicates that the transfer of tokens to the contract 
    * failed, which could be due to insufficient balance or allowance.
    */
    function stake(
        uint256 poolId,
        uint256 amount,
        uint256 id
    ) external virtual returns (
        uint256 stakeId
    );

    /**
    * @dev Adds a reward to a specified pool, enabling stakers to earn additional tokens.
    * This function allows the pool's rewarder to allocate a new reward in the form of ERC20 
    * tokens, which can be claimed by stakers after a certain number of blocks.
    *
    * Emits a {IStaqeEvents-RewardAdded} event when the reward is successfully added to the pool.
    *
    * Requirements:
    * - The caller must be the rewarder of the pool.
    * - The pool specified by `poolId` must exist and have active stakes.
    * - `rewardToken` must be a valid ERC20 token address.
    * - `rewardAmount` must be greater than zero and should be meaningful considering the 
    *   pool's staking context.
    * - `claimAfterBlocks` specifies the number of blocks to wait before the reward can be 
    *   claimed, enforcing a minimum staking period.
    *
    * @param poolId The ID of the pool to which the reward is being added.
    * @param rewardToken The ERC20 token address to be used for the reward.
    * @param rewardAmount The amount of reward tokens to be distributed.
    * @param claimAfterBlocks The number of blocks to wait before the reward becomes claimable.
    * @param isForERC721Stakers A boolean indicating whether the reward is for ERC721 stakers 
    * (true) or ERC20 stakers (false).
    *
    * @return rewardId The ID of the newly added reward in the pool.
    *
    * @custom:error PoolDoesNotExist Indicates that the specified pool does not exist.
    * @custom:error OnlyRewinderHasAccessToAddRewards Indicates that only the designated 
    * rewarder of the pool can add rewards.
    * @custom:error InvalidRewardToken Indicates that the reward token address is invalid.
    * @custom:error RewardIsEmpty Indicates that the reward amount is zero or insufficient.
    * @custom:error PoolDoesNotHaveStakes Indicates that the pool has no active stakes, and 
    * thus adding a reward is not meaningful.
    */
    function addReward(
        uint256 poolId,
        IERC20 rewardToken,
        uint256 rewardAmount,
        uint256 claimAfterBlocks,
        bool isForERC721Stakers
    ) external virtual returns (
        uint256 rewardId
    );

    /**
    * @dev Allows a user to unstake previously staked ERC20 or ERC721 tokens from a specified pool.
    * This function enables users to retrieve their staked tokens, updating the pool's and user's 
    * staking records accordingly.
    *
    * Emits a {IStaqeEvents-StakeWithdrawn} event when the tokens are successfully unstaked.
    *
    * Requirements:
    * - The pool specified by `poolId` must exist.
    * - The caller must have active stakes in the specified pool.
    * - `stakeIds` array should contain valid stake IDs corresponding to the user's stakes.
    * - Users can only unstake after the reward distribution for their stakes has been resolved.
    *
    * @param poolId The ID of the pool from which the tokens are being unstaked.
    * @param stakeIds An array of stake IDs that the user wishes to unstake. These IDs must 
    * correspond to the stakes the user has in the pool.
    *
    * @return amountERC20 The total amount of ERC20 tokens returned to the user as a result of 
    * the unstaking.
    * @return idsERC721 An array of the ERC721 token IDs returned to the user as a result of 
    * the unstaking.
    *
    * @custom:error PoolDoesNotExist Indicates that the specified pool does not exist.
    * @custom:error PoolDoesNotHaveStakes Indicates that the pool does not have any active 
    * stakes, or the user does not have any active stakes in the pool.
    * @custom:error UnstakeTransferFailed Indicates that the transfer of staked tokens back to 
    * the user failed.
    * @custom:error UnstakeOnNextBlockAndGetReward Suggests that the user should wait until the 
    * next block to unstake in order to receive an upcoming reward.
    * @custom:error StakerDoesNotHaveStakesInPool Indicates that the staker does not have the 
    * specified stakes in the pool.
    */
    function unstake(
        uint256 poolId,
        uint256[] calldata stakeIds
    )
        external virtual
        returns (
            uint256 amountERC20,
            uint256[] memory idsERC721
        );

    /**
    * @dev Allows users to claim their pending rewards for a specific pool or multiple pools.
    * This function calculates the claimable rewards based on the user's stakes and the pool's 
    * reward configuration, then transfers the appropriate amount of reward tokens to the user.
    *
    * Emits a {IStaqeEvents-RewardClaimed} event for each reward that is successfully claimed.
    *
    * Requirements:
    * - The caller must have earned rewards in the specified pool(s) that are ready to be claimed.
    * - `poolIds` and `rewardIds` arrays must correspond to each other, specifying which rewards 
    * to claim from which pools.
    * - The `recipient` address must be valid and can be the caller or another address specified 
    * by the caller.
    *
    * @param poolIds An array of pool IDs from which the user is claiming rewards.
    * @param rewardIds A two-dimensional array of reward IDs that the user is claiming, 
    * corresponding to each pool ID in `poolIds`.
    * @param recipient The address that will receive the claimed rewards. It can be the caller's 
    * address or another address specified by the caller.
    *
    * @return tokens A two-dimensional array of ERC20 token addresses for the claimed rewards, 
    * corresponding to each claimed reward ID in `rewardIds`.
    * @return amounts A two-dimensional array of amounts for the claimed rewards, corresponding 
    * to each claimed reward ID in `rewardIds`.
    *
    * @custom:error PoolDoesNotExist Indicates that one of the specified pools does not exist.
    * @custom:error RewardNotFoundInPool Indicates that one of the specified rewards does not 
    * exist in the corresponding pool.
    * @custom:error RewardAlreadyClaimed Indicates that the user has already claimed the 
    * specified reward.
    * @custom:error RewardIsNotYetAvailableForClaim Indicates that the reward is not yet 
    * available for claiming, typically because the claimAfterBlocks period has not yet passed.
    * @custom:error RewardIsEmpty Indicates that there is no reward available to be claimed, 
    * possibly because the user does not have a qualifying stake.
    * @custom:error RewardTransferFailed Indicates that the transfer of the reward tokens to 
    * the recipient address failed.
    */
    function claimRewards(
        uint256[] memory poolIds,
        uint256[][] memory rewardIds,
        address recipient
    ) external virtual returns (
        IERC20[][] memory tokens,
        uint256[][] memory amounts
    );
}
