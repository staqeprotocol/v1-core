// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

import {Staqe, IERC20, IERC721} from "@staqeprotocol/v1-core/contracts/Staqe.sol";
import {StaqePermit} from "@staqeprotocol/v1-core/contracts/extensions/StaqePermit.sol";

/**
 *       _                                     _                  _
 *   ___| |_ __ _  __ _  ___   _ __  _ __ ___ | |_ ___   ___ ___ | |
 *  / __| __/ _` |/ _` |/ _ \ | '_ \| '__/ _ \| __/ _ \ / __/ _ \| |
 *  \__ \ || (_| | (_| |  __/ | |_) | | | (_) | || (_) | (_| (_) | |
 *  |___/\__\__,_|\__, |\___| | .__/|_|  \___/ \__\___/ \___\___/|_|
 *                   |_|      |_|
 */
contract StaqeProtocol is Staqe, StaqePermit {
    constructor(
        IERC20 stakeERC20,
        IERC721 stakeERC721,
        IERC20 rewardToken,
        string memory metadata
    ) Staqe(stakeERC20, stakeERC721, rewardToken) {}
}
