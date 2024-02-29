// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721, IERC165} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IStaqeEvents} from "@staqeprotocol/v1-core/contracts/interfaces/IStaqeEvents.sol";
import {IStaqeErrors} from "@staqeprotocol/v1-core/contracts/interfaces/IStaqeErrors.sol";
import {IStaqeStructs} from "@staqeprotocol/v1-core/contracts/interfaces/IStaqeStructs.sol";

/**
 *       _                     _       _             __
 *   ___| |_ __ _  __ _  ___  (_)_ __ | |_ ___ _ __ / _| __ _  ___ ___
 *  / __| __/ _` |/ _` |/ _ \ | | '_ \| __/ _ \ '__| |_ / _` |/ __/ _ \
 *  \__ \ || (_| | (_| |  __/ | | | | | ||  __/ |  |  _| (_| | (_|  __/
 *  |___/\__\__,_|\__, |\___| |_|_| |_|\__\___|_|  |_|  \__,_|\___\___|
 *                   |_|
 *
 * @title Staqe
 * @dev This contract offers a robust platform for decentralized finance (DeFi) applications,
 * focusing on staking mechanisms. It facilitates the creation and management of multiple
 * staking pools, each with unique staking criteria, rewards, and durations. Users can engage
 * in staking activities, claim rewards based on their contributions, and manage their stakes
 * across various pools. The contract is designed with flexibility in mind, allowing for the
 * addition, modification, and querying of pools and stakes.
 *
 * Key Features:
 * - **Dynamic Staking Pools**: Supports the creation of multiple staking pools, each with its
 *   own set of rules and rewards, allowing for a diverse range of staking opportunities.
 * - **Stake Management**: Users can stake tokens, unstake tokens, and claim rewards, with the
 *   contract handling the calculation and distribution of rewards based on predefined pool rules.
 * - **Transparency and Security**: Implements secure and transparent staking processes, ensuring
 *   users have clear insights into their staking positions and rewards.
 * - **ERC-721 Support**: Includes compatibility with ERC-721 tokens, enabling staking functionalities
 *   for NFT assets alongside traditional ERC-20 tokens.
 *
 * The contract is structured to provide a comprehensive staking solution for the DeFi sector,
 * catering to both ERC-20 and ERC-721 assets. It aims to offer a user-friendly interface for
 * staking, while ensuring the security and integrity of the staking process.
 */
interface IStaqe is IStaqeEvents, IStaqeErrors, IStaqeStructs {
    /**
     * @notice Launches a new staking pool with specified configurations.
     * @dev This function emits a `PoolLaunched` event upon successful creation of a pool.
     *      It uses a non-reentrant modifier to prevent reentrancy attacks during execution.
     *      The function validates the staking tokens and metadata before creating the pool.
     *      At least one staking token (ERC20 or ERC721) must be specified.
     *      `metadata` is expected to be an IPFS CID encoded in bytes32, representing a JSON object
     *      associated with this pool.
     * @param stakeERC20 The ERC20 token address that will be staked in this pool. If `address(0)`,
     *                   indicates that no ERC20 staking is required, but `stakeERC721` must not be `address(0)`.
     * @param stakeERC721 The ERC721 token address that will be staked in this pool. If `address(0)`,
     *                    indicates that no ERC721 staking is required, but `stakeERC20` must not be `address(0)`.
     * @param rewardToken The ERC20 token address that will be used as a reward in this pool. If `address(0)`,
     *                    rewards can be in any token, allowing for flexible reward schemes.
     * @param rewarder The address responsible for providing rewards to the pool. If `address(0)`,
     *                 any user can add rewards to the pool, enabling a decentralized reward mechanism.
     * @param metadata Arbitrary data to be associated with this pool, encoded in bytes32. This is expected
     *                 to be an IPFS CID representing a JSON object that contains additional information
     *                 about the pool.
     * @return poolId The unique identifier of the newly created staking pool.
     * @custom:error InvalidERC721Token Reverts if the provided ERC721 address is not a valid ERC721 token.
     * @custom:error InvalidStakeToken Reverts if both stakeERC20 and stakeERC721 addresses are zero,
     *               indicating no staking token was provided.
     * @custom:error InvalidMetadata Reverts if the provided metadata is empty (bytes32(0)),
     *               indicating that necessary pool information is missing.
     */
    function launchPool(
        IERC20 stakeERC20,
        IERC721 stakeERC721,
        IERC20 rewardToken,
        address rewarder,
        bytes32 metadata
    ) external returns (uint256 poolId);

    /**
     * @notice Edits the metadata of an existing staking pool.
     * @dev This function allows the pool's rewarder to update the pool's metadata. It emits a `PoolEdited`
     *      event upon success. The function is protected against reentrancy attacks. It requires the caller
     *      to be the rewarder of the pool with a non-zero address and does not allow setting the metadata
     *      to its current value or to an empty value (bytes32(0)). This restriction ensures that changes
     *      are meaningful and prevent accidental erasure of metadata.
     * @param poolId The unique identifier of the pool whose metadata is to be edited.
     * @param metadata The new metadata for the pool, encoded in bytes32. This is expected to be
     *                 an IPFS CID representing a JSON object that contains additional information about
     *                 the pool. The function rejects empty metadata.
     * @custom:error PoolDoesNotExist Reverts if the specified pool ID does not correspond to an existing
     *               pool, indicated by a `launchBlock` of zero.
     * @custom:error InvalidMetadata Reverts if the new metadata is either empty or matches the current
     *               metadata of the pool, indicating no change.
     * @custom:error OnlyRewinderHasAccessToEditMetadata Reverts if the caller is not the rewarder of the
     *               pool or if the rewarder's address is zero. This ensures that only the designated rewarder
     *               can edit pool metadata.
     */
    function editPool(uint256 poolId, bytes32 metadata) external;

    /**
     * @notice Allows users to stake ERC20 tokens or ERC721 tokens into a specified pool.
     * @dev This function enables staking of either ERC20 or ERC721 tokens based on the parameters provided.
     *      It is protected against reentrancy attacks. The function calculates the new stake ID as the length
     *      of the staker's existing stakes in the pool, adjusts the pool's total staked tokens accordingly,
     *      and records the new stake. It requires that the pool exists and that the staked amount (for ERC20)
     *      or the staked token ID (for ERC721) is valid. Transfers the staked tokens from the caller to this
     *      contract. Emits a `StakeCreated` event upon success.
     * @param poolId The unique identifier of the pool in which to stake tokens.
     * @param amount The amount of ERC20 tokens to stake. This parameter is ignored if `id` is specified for
     *               an ERC721 token stake. Must be greater than zero for ERC20 staking.
     * @param id The ID of the ERC721 token to stake. This parameter is ignored if `amount` is specified for
     *           an ERC20 token stake. Must be a valid token ID for ERC721 staking.
     * @return stakeId The unique identifier for the newly created stake within the pool.
     * @custom:error PoolDoesNotExist Reverts if the specified pool ID does not correspond to an existing pool.
     * @custom:error InvalidAmount Reverts if both `amount` and `id` are zero or less,
     *               indicating that no valid stake has been specified.
     * @custom:error StakeTransferFailed Reverts if the transfer of ERC20 tokens from the staker to the contract fails.
     */
    function stake(
        uint256 poolId,
        uint256 amount,
        uint256 id
    ) external returns (uint256 stakeId);

    /**
     * @notice Adds a reward to a specified pool, which can be claimed by stakers after a
     *         set number of blocks.
     * @dev This function allows adding rewards to a pool, with the option to specify whether
     *      the reward is for ERC721 stakers or ERC20 stakers within the pool. It validates
     *      the existence of the pool, the validity of the reward token, and the reward amount.
     *      The function also checks if the caller is authorized as the rewarder for the pool and ensures
     *      there are eligible stakers in the pool. The reward is recorded, and the reward tokens
     *      are transferred from the caller to this contract. Emits a `RewardAdded` event upon successful
     *      addition of the reward.
     * @param poolId The unique identifier of the pool to which the reward is being added.
     * @param rewardToken The ERC20 token used as the reward.
     * @param rewardAmount The amount of reward tokens being added.
     * @param claimAfterBlocks The number of blocks after which the reward can be claimed.
     * @param isForERC721Stakers A boolean flag indicating whether the reward is designated
     *                           for ERC721 stakers (true) or ERC20 stakers (false).
     * @return rewardId The unique identifier for the newly added reward within the pool.
     * @custom:error PoolDoesNotExist Reverts if the specified pool ID does not correspond to an existing pool.
     * @custom:error InvalidRewardToken Reverts if the reward token address is zero.
     * @custom:error RewardIsEmpty Reverts if the reward amount is zero or less.
     * @custom:error OnlyRewinderHasAccessToAddRewards Reverts if the caller is not the designated
     *               rewarder for the pool or if the pool does not have a designated rewarder.
     * @custom:error PoolDoesNotHaveStakes Reverts if the pool has no eligible stakes for the type
     *               of stakers specified by `isForERC721Stakers`.
     * @custom:error RewardTransferFailed Reverts if the transfer of reward tokens from the caller to
     *               the contract fails.
     */
    function addReward(
        uint256 poolId,
        IERC20 rewardToken,
        uint256 rewardAmount,
        uint256 claimAfterBlocks,
        bool isForERC721Stakers
    ) external returns (uint256 rewardId);

    /**
     * @notice Allows a staker to unstake their tokens (ERC20 or ERC721) from a specified pool.
     * @dev This function facilitates the withdrawal of staked assets from the pool by a user.
     *      It calculates the total amount of ERC20 tokens and the count of ERC721 tokens to be
     *      unstaked based on the provided stake IDs, then performs the asset transfer back to
     *      the staker. It utilizes an internal `_unstake` helper function to process the unstaking
     *      logic. The function ensures the pool exists and that the staker has stakes to withdraw.
     *      It reverts on failures related to token transfers or invalid operations. Emits a
     *      `StakeWithdrawn` event upon successful unstaking.
     * @param poolId The unique identifier of the pool from which the staker wishes to withdraw their stakes.
     * @param stakeIds An array of stake identifiers that the staker wishes to withdraw.
     * @return amountERC20 The total amount of ERC20 tokens being unstaked.
     * @return idsERC721 An array containing the IDs of the ERC721 tokens being unstaked.
     * @custom:error UnstakeTransferFailed Reverts if the transfer of staked ERC20 tokens back to the staker fails.
     * @custom:error PoolDoesNotExist Reverts if the specified pool ID does not correspond to an existing pool.
     * @custom:error PoolDoesNotHaveStakes Reverts if the staker does not have any stakes in the specified pool or if the
     *               provided stake IDs array is empty.
     * @custom:error StakerDoesNotHaveStakesInPool Reverts if the staker does not have any active stakes within the pool
     *               corresponding to the provided stake IDs.
     */
    function unstake(
        uint256 poolId,
        uint256[] calldata stakeIds
    )
        external
        returns (
            uint256 amountERC20,
            uint256[] memory idsERC721
        );

    /**
     * @notice Claims rewards for the caller across multiple pools and specific reward IDs,
     *         transferring the rewards to a specified recipient.
     * @dev This function iterates over an array of pool IDs and their corresponding reward IDs
     *      to calculate and claim rewards for the caller. It supports both ERC20 and potentially
     *      other types of rewards, aggregating reward amounts and performing token transfers
     *      in a secure manner to avoid reentrancy issues. The function updates the claimed amounts
     *      internally to prevent double claiming. Emits a `RewardClaimed` event for each successful reward claim.
     * @param poolIds An array of pool IDs from which the caller wishes to claim rewards.
     * @param rewardIds A two-dimensional array corresponding to the `poolIds`, containing arrays of reward IDs
     *                  to be claimed from each pool.
     * @param recipient The address to which the claimed rewards will be transferred.
     * @return tokens A two-dimensional array of tokens corresponding to the claimed rewards for each pool.
     *                This array mirrors the structure of `poolIds` and `rewardIds`.
     * @return amounts A two-dimensional array of amounts corresponding to the claimed rewards for each pool.
     *                 This array mirrors the structure of `poolIds` and `rewardIds`.
     * @custom:error RewardTransferFailed Reverts if the transfer of rewards to the recipient fails.
     * @custom:error RewardAlreadyClaimed Reverts if the reward has already been claimed by the caller.
     * @custom:error RewardIsNotYetAvailableForClaim Reverts if the reward is not yet available for claim
     *               based on the block number.
     * @custom:error RewardNotFoundInPool Reverts if the specified reward ID does not exist within the given pool.
     * @custom:error StakerDoesNotHaveStakesInPool Reverts if the caller does not have any stakes in the specified pool.
     * @custom:error RewardIsEmpty Reverts if the calculated reward amount is zero, indicating there's no reward to claim.
     */
    function claimRewards(
        uint256[] memory poolIds,
        uint256[][] memory rewardIds,
        address recipient
    ) external returns (IERC20[][] memory tokens, uint256[][] memory amounts);
}
