// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

/**
 *       _                                          _
 *   ___| |_ __ _  __ _  ___    _____   _____ _ __ | |_ ___
 *  / __| __/ _` |/ _` |/ _ \  / _ \ \ / / _ \ '_ \| __/ __|
 *  \__ \ || (_| | (_| |  __/ |  __/\ V /  __/ | | | |_\__ \
 *  |___/\__\__,_|\__, |\___|  \___| \_/ \___|_| |_|\__|___/
 *                   |_|
 */
interface IStaqeEvents {
    event Launched(address indexed launcher, uint256 indexed poolId);

    event Staked(
        address indexed staker,
        uint256 indexed poolId,
        uint256 indexed stakeId
    );

    event Rewarded(
        address indexed rewarder,
        uint256 indexed poolId,
        uint256 indexed rewardId
    );

    event Unstaked(address indexed staker, uint256 indexed poolId);

    event Claimed(address indexed staker, uint256 indexed poolId);
}
