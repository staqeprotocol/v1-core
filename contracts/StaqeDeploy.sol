// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
pragma abicoder v2;

import {Staqe, IERC20, IERC721} from "@staqeprotocol/v1-core/contracts/Staqe.sol";
import {StaqeViews} from "@staqeprotocol/v1-core/contracts/extensions/StaqeViews.sol";

contract StaqeDeploy is Staqe, StaqeViews {
    constructor(
        IERC20 stakeERC20,
        IERC721 stakeERC721,
        IERC20 rewardToken,
        address rewarder,
        bytes32 metadata
    ) Staqe(stakeERC20, stakeERC721, rewardToken, rewarder, metadata) {}
}
