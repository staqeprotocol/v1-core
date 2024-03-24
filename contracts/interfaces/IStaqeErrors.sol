// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

/**
 *       _
 *   ___| |_ __ _  __ _  ___    ___ _ __ _ __ ___  _ __ ___
 *  / __| __/ _` |/ _` |/ _ \  / _ \ '__| '__/ _ \| '__/ __|
 *  \__ \ || (_| | (_| |  __/ |  __/ |  | | | (_) | |  \__ \
 *  |___/\__\__,_|\__, |\___|  \___|_|  |_|  \___/|_|  |___/
 *                   |_|
 */
interface IStaqeErrors {
    error InvalidStakeToken();
    error InvalidStakeId();
    error InvalidERC721Token();
    error InvalidRewardToken();
    error InvalidTokenURI();
    error InvalidAmountOrId();
    error PoolDoesNotExist();
    error PoolDoesNotHaveStakes();
    error RewardIsEmpty();
    error RewardTransferFailed();
    error RewardNotFoundInPool();
    error RewardAlreadyClaimed();
    error RewardIsNotYetAvailableForClaim();
    error OnlyOwnerHasAccessToEditTokenURI();
    error OnlyOwnerHasAccessToAddRewards();
    error StakerDoesNotHaveStakesInPool();
    error StakeAlreadyUnstaked();
    error StakeTransferFailed();
    error StakeOnNextBlockAfterReward();
    error UnstakeTransferFailed();
    error UnstakeOnNextBlockAndGetReward();
    error OnlyAvailableToStakersInGenesis();
    error TotalMaxForOnlyOneTypeOfToken();
    error MoreThanTheTotalMaxTokens();
}
