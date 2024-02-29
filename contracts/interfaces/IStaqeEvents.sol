// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 *       _                                          _
 *   ___| |_ __ _  __ _  ___    _____   _____ _ __ | |_ ___
 *  / __| __/ _` |/ _` |/ _ \  / _ \ \ / / _ \ '_ \| __/ __|
 *  \__ \ || (_| | (_| |  __/ |  __/\ V /  __/ | | | |_\__ \
 *  |___/\__\__,_|\__, |\___|  \___| \_/ \___|_| |_|\__|___/
 *                   |_|
 */
interface IStaqeEvents {
    event PoolLaunched(
        uint256 indexed poolId,
        IERC20 indexed stakeERC20,
        IERC721 indexed stakeERC721,
        IERC20 rewardToken,
        address rewarder,
        bytes32 metadata
    );

    event PoolEdited(uint256 indexed poolId, bytes32 metadata);

    event RewardAdded(
        uint256 indexed poolId,
        uint256 indexed rewardId,
        IERC20 indexed rewardToken,
        uint256 rewardAmount,
        uint256 totalStakedERC20,
        uint256 totalStakedERC721,
        bool isForERC721Stakers,
        uint256 claimAfterBlock
    );

    event StakeCreated(
        address indexed staker,
        uint256 indexed poolId,
        uint256 indexed stakeId,
        uint256 stakeAmountERC20,
        uint256 stakeAmountERC721
    );

    event StakeWithdrawn(
        address indexed staker,
        uint256 indexed poolId,
        uint256 stakeAmountERC20,
        uint256 stakeAmountERC721
    );

    event RewardClaimed(
        address indexed claimant,
        uint256 indexed poolId,
        uint256 indexed rewardId,
        IERC20 rewardToken,
        uint256 rewardAmount
    );
}
