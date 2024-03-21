// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 *       _                         _                   _
 *   ___| |_ __ _  __ _  ___   ___| |_ _ __ _   _  ___| |_ ___
 *  / __| __/ _` |/ _` |/ _ \ / __| __| '__| | | |/ __| __/ __|
 *  \__ \ || (_| | (_| |  __/ \__ \ |_| |  | |_| | (__| |_\__ \
 *  |___/\__\__,_|\__, |\___| |___/\__|_|   \__,_|\___|\__|___/
 *                   |_|
 */
interface IStaqeStructs {
    struct Pool {
        IERC20 stakeERC20;
        IERC721 stakeERC721;
        IERC20 rewardToken;
        uint256 totalMax;
        uint256 totalStakedERC20;
        uint256 totalStakedERC721;
        uint256 launchBlock;
    }

    struct Reward {
        bool isForERC721Stakers;
        IERC20 rewardToken;
        uint256 rewardAmount;
        uint256 totalStaked;
        uint256 claimAfterBlocks;
        uint256 rewardBlock;
    }

    struct Stake {
        uint256 amountERC20;
        uint256 idERC721;
        uint256 stakeBlock;
        uint256 unstakeBlock;
    }
}
