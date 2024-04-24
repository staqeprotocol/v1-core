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
    error InvalidStakeToken(); // 29d87026
    error InvalidStakeId(); // 9b763f71
    error InvalidERC721Token(); // 66a07777
    error InvalidRewardToken(); // dfde8671
    error InvalidTokenURI(); // 13f04adb
    error InvalidAmountOrId(); // ee46f884
    error PoolDoesNotExist(); // 9c8787c0
    error PoolDoesNotHaveStakes(); // 1def8068
    error RewardIsEmpty(); // becbe2ca
    error RewardTransferFailed(); // 78ecf410
    error RewardNotFoundInPool(); // ecf5f6f6
    error RewardAlreadyClaimed(); // b3f8c0dc
    error RewardIsNotYetAvailableForClaim(); // 03a4fc37
    error OnlyOwnerHasAccessToEditTokenURI(); // 7cefe4d1
    error OnlyOwnerHasAccessToAddRewards(); // 29e07c14
    error StakerDoesNotHaveStakesInPool(); // 19a089c1
    error StakeAlreadyUnstaked(); // f27debd2
    error StakeTransferFailed(); // 48c7b0bc
    error StakeOnNextBlockAfterReward(); // 90b32a20
    error UnstakeTransferFailed(); // 373e0262
    error UnstakeOnNextBlockAndGetReward(); // 71f7dfa5
    error OnlyAvailableToStakersInGenesis(); // b1fa3372
    error TotalMaxForOnlyOneTypeOfToken(); // df9c3d7d
    error MoreThanTheTotalMaxTokens(); // db9c68e6
}
