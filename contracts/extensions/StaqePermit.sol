// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
pragma abicoder v2;

import {Staqe, IERC20, ERC20Permit} from "@staqeprotocol/v1-core/contracts/Staqe.sol";

/**
 *       _                                               _ _   
 *   ___| |_ __ _  __ _  ___   _ __   ___ _ __ _ __ ___ (_) |_ 
 *  / __| __/ _` |/ _` |/ _ \ | '_ \ / _ \ '__| '_ ` _ \| | __|
 *  \__ \ || (_| | (_| |  __/ | |_) |  __/ |  | | | | | | | |_ 
 *  |___/\__\__,_|\__, |\___| | .__/ \___|_|  |_| |_| |_|_|\__|
 *                   |_|      |_|                              
 */
abstract contract StaqePermit is Staqe {
    /**
     * @notice Stakes tokens in a pool with a permit, allowing the sender to approve and stake in a single transaction.
     * @param poolId The ID of the pool in which to stake tokens.
     * @param amount The amount of tokens to stake in the pool.
     * @param deadline The time by which the permit must be used before it expires.
     * @param v The recovery byte of the signature.
     * @param r Half of the ECDSA signature pair.
     * @param s Half of the ECDSA signature pair.
     * @param max A boolean to indicate if the maximum amount of tokens should be approved (true) or the specified amount (false).
     */
    function stakeWithPermit(
        uint256 poolId,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool max
    ) external {
        ERC20Permit(address(getPool(poolId).stakeERC20)).permit(
            _msgSender(),
            address(this),
            max ? type(uint256).max : amount,
            deadline,
            v, r, s);
        stake(poolId, amount, 0);
    }

    /**
     * @notice Adds a reward to a pool with a permit, allowing the sender to approve and add a reward in a single transaction.
     * @param poolId The ID of the pool to which the reward will be added.
     * @param rewardToken The token that will be used for the reward.
     * @param rewardAmount The amount of the reward token to be added.
     * @param claimAfterBlocks The number of blocks after which the reward can be claimed.
     * @param isForERC721Stakers A boolean to indicate if the reward is for ERC721 stakers (true) or ERC20 stakers (false).
     * @param deadline The time by which the permit must be used before it expires.
     * @param v The recovery byte of the signature.
     * @param r Half of the ECDSA signature pair.
     * @param s Half of the ECDSA signature pair.
     * @param max A boolean to indicate if the maximum amount of tokens should be approved (true) or the specified amount (false).
     */
    function addRewardWithPermit(
        uint256 poolId,
        IERC20 rewardToken,
        uint256 rewardAmount,
        uint256 claimAfterBlocks,
        bool isForERC721Stakers,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool max
    ) external {
        ERC20Permit(address(rewardToken)).permit(
            _msgSender(),
            address(this),
            max ? type(uint256).max : rewardAmount,
            deadline,
            v, r, s);
        addReward(poolId, rewardToken, rewardAmount, claimAfterBlocks, isForERC721Stakers);
    }
}