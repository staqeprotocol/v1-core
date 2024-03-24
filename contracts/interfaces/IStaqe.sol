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

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
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
 * @notice This contract interface a staking platform for ERC20 and ERC721 tokens. Users can stake tokens to 
 * participate in pools, earn rewards, and create their own staking pools if they own a Genesis NFT. The contract
 * supports the creation, management, and interaction with various staking pools, each with its own settings and
 * reward mechanisms. Users can stake and unstake at any time, claim rewards, and transfer pool ownership through
 * ERC721 representation.
 * 
 * @dev The contract includes functionalities to launch new pools, stake and unstake tokens, add rewards, and 
 * claim rewards. It adheres to the IStaqe interface, ensuring compliance with the defined staking and reward 
 * mechanisms. The contract uses OpenZeppelin's ERC20 and ERC721 implementations for token and pool interactions.
 *
 */
abstract contract IStaqe is 
    IStaqeEvents,
    IStaqeErrors,
    IStaqeStructs,
    IStaqeERC721,
    IStaqeERC7572,
    IStaqeReentrancy
{
    /**
    * @dev 
    * Implements the functionality for launching a new staking pool within the Staqe platform.
    * This function allows users who have staked in the Genesis pool to create their own
    * staking pools. Each new pool is an ERC721 token, allowing it to be transferred or sold.
    * Users specify the types of tokens that can be staked (ERC20 and/or ERC721) and the token 
    * for rewards. They also set a maximum limit for the total stakable tokens and a tokenURI
    * for the pool's ERC721 representation. If both ERC20 and ERC721 tokens are accepted for staking,
    * the totalMax parameter applies to only one type, based on which token is not set to the zero address.
    * 
    * @param stakeERC20 The ERC20 token that can be staked in the new pool. If set to the zero
    * address, the pool will only accept ERC721 tokens for staking.
    * @param stakeERC721 The ERC721 token that can be staked in the new pool. If set to the zero
    * address, the pool will only accept ERC20 tokens for staking.
    * @param rewardToken The ERC20 token to be used as a reward in the new pool.
    * @param totalMax The maximum number of tokens (ERC20 or ERC721, but not both) that can be
    * staked in the pool. If set to zero, there is no limit.
    * @param tokenURI The URI for the token metadata of the pool's ERC721 representation. Must be
    * a non-empty string.
    * 
    * @return poolId The ID of the newly launched pool, represented as a uint256.
    * 
    * @custom:error OnlyAvailableToStakersInGenesis Thrown if the caller has not staked in the Genesis pool.
    * @custom:error InvalidERC721Token Thrown if the provided ERC721 token address does not comply
    * with the ERC721 standard.
    * @custom:error InvalidStakeToken Thrown if both stakeERC20 and stakeERC721 are set to the zero address.
    * @custom:error InvalidTokenURI Thrown if the provided tokenURI is an empty string.
    * @custom:error TotalMaxForOnlyOneTypeOfToken Thrown if totalMax is set but both types of tokens
    * are allowed for staking.
    */
    function launchPool(
        IERC20 stakeERC20,
        IERC721 stakeERC721,
        IERC20 rewardToken,
        uint256 totalMax,
        string memory tokenURI
    ) external virtual returns (
        uint256 poolId
    );

    /**
    * @dev 
    * Enables users to stake their tokens in a specified pool. Users can stake either ERC20 or ERC721 tokens, 
    * but not both in a single transaction. The function records the staking action, updating the total 
    * staked amounts for the pool and tracking the individual stakes of the user. Each stake is identified 
    * by a unique stakeId within the pool. The function ensures that the staking aligns with the pool's 
    * requirements and restrictions, such as the token type and the maximum staking limits.
    * 
    * @param poolId The ID of the pool in which the user wants to stake tokens. Must correspond to an 
    * existing pool.
    * @param amount If staking an ERC20 token, this is the amount to stake. If staking an ERC721 token,
    * this should be set to zero.
    * @param id If staking an ERC721 token, this is the token ID to stake. If staking an ERC20 token,
    * this should be set to zero.
    * 
    * @return stakeId A unique identifier for the stake within the pool, represented as a uint256.
    * 
    * @custom:error PoolDoesNotExist Thrown if the specified poolId does not correspond to an existing pool.
    * @custom:error InvalidAmountOrId Thrown if both amount and id are set to zero, indicating no stake.
    * @custom:error StakeOnNextBlockAfterReward Thrown if an attempt is made to stake in a block immediately 
    * following a reward distribution block, to ensure fair reward allocation.
    * @custom:error MoreThanTheTotalMaxTokens Thrown if the staking would exceed the pool's maximum allowed 
    * total stake for the token type being staked.
    * @custom:error StakeTransferFailed Thrown if the token transfer to the pool (for ERC20) or the token 
    * transfer call (for ERC721) fails.
    */
    function stake(
        uint256 poolId,
        uint256 amount,
        uint256 id
    ) external virtual returns (
        uint256 stakeId
    );

    /**
    * @dev 
    * Allows the owner of a pool to add a reward in the form of ERC20 tokens. This function can be used to incentivize 
    * stakers by offering rewards based on their participation in the pool. The rewards can be configured specifically 
    * for ERC20 or ERC721 stakers. The reward amount, along with the block number after which it can be claimed, is 
    * recorded. This function ensures that only the pool owner can add rewards and that the reward settings are valid.
    *
    * @param poolId The ID of the pool to which the reward is being added. The pool must exist and the caller must 
    * be the owner of the pool.
    * @param rewardToken The ERC20 token to be used as the reward. The address must not be the zero address.
    * @param rewardAmount The amount of the rewardToken to be distributed as rewards. Must be greater than zero 
    * and, for ERC721 stakers, not exceed the number of staked ERC721 tokens.
    * @param claimAfterBlocks The number of blocks after which the reward can be claimed. This allows setting a 
    * delay between the reward distribution and when it can be claimed by the stakers.
    * @param isForERC721Stakers Specifies whether the reward is for ERC721 stakers (true) or ERC20 stakers (false).
    *
    * @return rewardId A unique identifier for the reward within the pool, represented as a uint256.
    *
    * @custom:error PoolDoesNotExist Thrown if the poolId does not correspond to an existing pool.
    * @custom:error InvalidRewardToken Thrown if the rewardToken address is the zero address.
    * @custom:error RewardIsEmpty Thrown if rewardAmount is zero or, for ERC721 stakers, exceeds the number 
    * of staked ERC721 tokens.
    * @custom:error OnlyOwnerHasAccessToAddRewards Thrown if the caller is not the owner of the pool.
    * @custom:error PoolDoesNotHaveStakes Thrown if there are no stakers in the pool for the specified staker 
    * type (ERC20 or ERC721).
    * @custom:error RewardTransferFailed Thrown if the transfer of reward tokens to the pool fails.
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
    * @dev 
    * Allows users to unstake their previously staked tokens from a specified pool. The function supports 
    * unstaking both ERC20 and ERC721 tokens. Users specify the pool and the stakes they wish to withdraw 
    * through their unique stake IDs. The function calculates the total amount of ERC20 tokens and the specific 
    * ERC721 token IDs to be returned to the user. It also updates the pool's and the user's staking records to 
    * reflect the unstaking. The unstake operation is subject to checks to prevent it from being executed in the 
    * same block as a reward distribution, ensuring fairness in the reward allocation process.
    * 
    * @param poolId The ID of the pool from which the tokens are to be unstaked. The pool must exist and have 
    * a record of the user's stakes.
    * @param stakeIds An array of stake IDs that the user wants to unstake. Each ID must correspond to an 
    * existing stake made by the caller in the specified pool.
    * 
    * @return amountERC20 The total amount of ERC20 tokens being unstaked and returned to the user.
    * @return idsERC721 An array of token IDs for the ERC721 tokens being unstaked and returned to the user.
    *
    * @custom:error PoolDoesNotExist Thrown if the poolId does not correspond to an existing pool.
    * @custom:error UnstakeOnNextBlockAndGetReward Thrown if an attempt is made to unstake in the same block 
    * as a reward distribution, to ensure that rewards are allocated based on the stakes at the time of 
    * distribution.
    * @custom:error StakerDoesNotHaveStakesInPool Thrown if the user has no stakes in the specified pool or 
    * if the stakeIds array is empty.
    * @custom:error InvalidStakeId Thrown if any of the provided stakeIds do not correspond to valid stakes 
    * made by the user in the pool.
    * @custom:error StakeAlreadyUnstaked Thrown if an attempt is made to unstake a stake that has already been 
    * unstaked.
    * @custom:error UnstakeTransferFailed Thrown if the transfer of staked tokens back to the user fails.
    */
    function unstake(
        uint256 poolId,
        uint256[] calldata stakeIds
    ) external virtual returns (
        uint256 amountERC20,
        uint256[] memory idsERC721
    );

    /**
    * @dev 
    * Allows users to claim their earned rewards from one or more pools. The function supports claiming 
    * multiple rewards from multiple pools in a single transaction. Users specify the pools and the specific 
    * rewards within those pools they wish to claim. The function calculates the reward amounts based on the 
    * user's stakes and the reward distribution rules for each pool. It ensures that rewards are only claimed 
    * once and that the claim is made after the specified waiting period post reward distribution. The rewards 
    * are transferred to a specified recipient address, which can be the user's address or another address 
    * specified by the user.
    * 
    * @param poolIds An array of pool IDs from which the user wants to claim rewards. Each pool ID must 
    * correspond to a pool where the user has staked tokens and earned rewards.
    * @param rewardIds A two-dimensional array of reward IDs that the user wants to claim, corresponding to 
    * each pool ID in the poolIds array. Each inner array of reward IDs is associated with the pool ID at the 
    * same index in the poolIds array.
    * @param recipient The address to receive the claimed rewards. If set to the zero address, the rewards 
    * will be sent to the caller's address.
    * 
    * @return tokens A two-dimensional array of IERC20 tokens representing the types of rewards claimed from 
    * each pool. Each inner array corresponds to the rewards claimed from the pool at the same index in the 
    * poolIds array.
    * @return amounts A two-dimensional array of uint256 values representing the amounts of each reward token 
    * claimed from each pool. The structure mirrors the tokens array.
    *
    * @custom:error RewardIsEmpty Thrown if the reward amount is zero or has already been claimed.
    * @custom:error RewardTransferFailed Thrown if the transfer of reward tokens to the recipient fails.
    * @custom:error RewardIsNotYetAvailableForClaim Thrown if an attempt is made to claim a reward before 
    * the specified waiting period has elapsed since the reward's distribution.
    * @custom:error RewardAlreadyClaimed Thrown if an attempt is made to claim a reward that has already 
    * been claimed by the user.
    * @custom:error RewardNotFoundInPool Thrown if any of the provided reward IDs do not correspond to valid 
    * rewards in the specified pools.
    * @custom:error StakerDoesNotHaveStakesInPool Thrown if the user does not have stakes in one of the 
    * specified pools and is therefore ineligible to claim rewards from that pool.
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
