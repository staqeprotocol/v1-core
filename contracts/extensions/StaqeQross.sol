// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

import {Staqe, IERC20} from "@staqeprotocol/v1-core/contracts/Staqe.sol";
import {ERC20Q} from "@qross/v1-core/contracts/ERC20Q.sol";

/**
 *       _
 *   ___| |_ __ _  __ _  ___    __ _ _ __ ___  ___ ___
 *  / __| __/ _` |/ _` |/ _ \  / _` | '__/ _ \/ __/ __|
 *  \__ \ || (_| | (_| |  __/ | (_| | | | (_) \__ \__ \
 *  |___/\__\__,_|\__, |\___|  \__, |_|  \___/|___/___/
 *                   |_|          |_|
 */
abstract contract StaqeQross is Staqe {
    /**
     * @notice Claims rewards from specified pools and distributes them to a recipient address across different chains.
     * @dev The function calculates the rewards for the given pools and reward IDs, then transfers the rewards using ERC20Q's cross-chain transfer.
     * @param poolIds An array of pool IDs from which the user wants to claim rewards. Each pool ID must correspond to a pool where the user has staked tokens and earned rewards.
     * @param rewardIds A two-dimensional array of reward IDs that the user wants to claim, corresponding to each pool ID in the poolIds array. Each inner array of reward IDs is associated with the pool ID at the same index in the poolIds array.
     * @param recipient The address to receive the claimed rewards. If set to the zero address, the rewards will be sent to the caller's address.
     * @param chainSelector The identifier of the target chain for the CCIP cross-chain transfer.
     * @return tokens A two-dimensional array of IERC20 tokens representing the types of rewards claimed from each pool. Each inner array corresponds to the rewards claimed from the pool at the same index in the poolIds array.
     * @return amounts A two-dimensional array of uint256 values representing the amounts of each reward token claimed from each pool. The structure mirrors the tokens array.
     *
     * @custom:error RewardIsEmpty Thrown if the reward amount is zero or has already been claimed.
     * @custom:error RewardTransferFailed Thrown if the transfer of reward tokens to the recipient fails.
     * @custom:error RewardIsNotYetAvailableForClaim Thrown if an attempt is made to claim a reward before the specified waiting period has elapsed since the reward's distribution.
     * @custom:error RewardAlreadyClaimed Thrown if an attempt is made to claim a reward that has already been claimed by the user.
     * @custom:error RewardNotFoundInPool Thrown if any of the provided reward IDs do not correspond to valid rewards in the specified pools.
     * @custom:error StakerDoesNotHaveStakesInPool Thrown if the user does not have stakes in one of the specified pools and is therefore ineligible to claim rewards from that pool.
     */
    function claimRewards(
        uint256[] memory poolIds,
        uint256[][] memory rewardIds,
        address recipient,
        uint64 chainSelector
    )
        external
        nonReentrant
        returns (IERC20[][] memory tokens, uint256[][] memory amounts)
    {
        if (recipient == address(0)) recipient = _msgSender();

        (tokens, amounts) = _calculateRewards(poolIds, rewardIds);

        for (uint256 poolIndex = 0; poolIndex < poolIds.length; poolIndex++) {
            IERC20 rewardToken = getPool(poolIds[poolIndex]).rewardToken;

            if (address(rewardToken) == address(0)) {
                for (
                    uint256 rewardIndex = 0;
                    rewardIndex < rewardIds[poolIndex].length;
                    rewardIndex++
                ) {
                    uint256 amount = amounts[poolIndex][rewardIndex];

                    if (amount <= 0) revert RewardIsEmpty();

                    if (
                        // slither-disable-next-line calls-loop
                        !ERC20Q(
                            payable(address(tokens[poolIndex][rewardIndex]))
                        ).transfer(recipient, amount, chainSelector)
                    ) {
                        revert RewardTransferFailed();
                    }
                }
            } else {
                uint256 totalAmount = 0;
                for (
                    uint256 rewardIndex = 0;
                    rewardIndex < rewardIds[poolIndex].length;
                    rewardIndex++
                ) {
                    totalAmount += amounts[poolIndex][rewardIndex];
                }

                if (totalAmount <= 0) revert RewardIsEmpty();

                if (
                    // slither-disable-next-line calls-loop
                    !ERC20Q(payable(address(rewardToken))).transfer(
                        recipient,
                        totalAmount,
                        chainSelector
                    )
                ) {
                    revert RewardTransferFailed();
                }
            }

            emit Claimed(_msgSender(), poolIds[poolIndex]);
        }
    }
}
