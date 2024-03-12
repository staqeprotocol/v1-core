// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
pragma abicoder v2;

import {Staqe, IERC20, IERC721, IERC165} from "@staqeprotocol/v1-core/contracts/Staqe.sol";

/**
 *       _                           _
 *   ___| |_ __ _  __ _  ___  __   _(_) _____      _____
 *  / __| __/ _` |/ _` |/ _ \ \ \ / / |/ _ \ \ /\ / / __|
 *  \__ \ || (_| | (_| |  __/  \ V /| |  __/\ V  V /\__ \
 *  |___/\__\__,_|\__, |\___|   \_/ |_|\___| \_/\_/ |___/
 *                   |_|
 */
abstract contract StaqeViews is Staqe {
    /**
     * @dev Returns an array of Pool structures for the given array of pool IDs. Only returns details
     *      for valid pool IDs that exist within the contract's state.
     * @param poolIds An array of pool IDs for which details are requested.
     * @return listOfPools An array of Pool structures containing details of each requested pool.
     */
    function pools(
        uint256[] calldata poolIds
    ) external view returns (Pool[] memory listOfPools) {
        listOfPools = new Pool[](poolIds.length);
        for (uint256 i = 0; i < poolIds.length; i++) {
            if (poolIds[i] <= getTotalPools()) {
                listOfPools[i] = getPool(poolIds[i]);
            }
        }
    }

    /**
     * @dev Returns an array of Reward structures for the specified pool ID and reward IDs.
     *      Only includes rewards that exist within the specified pool.
     * @param poolId The ID of the pool from which reward details are being requested.
     * @param rewardIds An array of reward IDs within the specified pool for which details are requested.
     * @return listOfRewards An array of Reward structures containing details of each requested reward.
     */
    function rewards(
        uint256 poolId,
        uint256[] calldata rewardIds
    ) external view returns (Reward[] memory listOfRewards) {
        Reward[] memory r = getRewards(poolId);
        listOfRewards = new Reward[](rewardIds.length);

        for (uint256 i = 0; i < rewardIds.length; i++) {
            if (rewardIds[i] < r.length) {
                listOfRewards[i] = r[rewardIds[i]];
            }
        }
    }

    /**
     * @dev Returns an array of Stake structures for a staker in a specified pool. The function
     *      filters stakes based on an array of stake IDs, returning details only for those that exist.
     * @param staker The address of the staker querying their stakes.
     * @param poolId The ID of the pool from which stake details are being requested.
     * @param stakeIds An array of stake IDs within the specified pool for which details are requested.
     * @return listOfStakes An array of Stake structures containing details of each requested stake.
     */
    function stakes(
        address staker,
        uint256 poolId,
        uint256[] calldata stakeIds
    ) external view returns (Stake[] memory listOfStakes) {
        Stake[] memory s = getStakes(staker, poolId);
        listOfStakes = new Stake[](stakeIds.length);

        for (uint256 i = 0; i < stakeIds.length; i++) {
            if (stakeIds[i] < s.length) {
                listOfStakes[i] = s[stakeIds[i]];
            }
        }
    }

    /**
     * @dev Returns arrays of pools, rewards, and stakes for a given staker, limited and
     *      paginated by `limit` and `offset`.
     * @param staker The address of the staker.
     * @param limit The maximum number of items to return.
     * @param offset The number of items to skip.
     * @return listOfStakerPools Array of pools the staker has participated in.
     * @return listOfRewardsInEachPool Nested array of rewards available in each pool.
     * @return listOfStakerStakesInEachPool Nested array of stakes the staker has in each pool.
     */
    function stakerInfo(
        address staker,
        uint256 limit,
        uint256 offset
    )
        external
        view
        returns (
            Pool[] memory listOfStakerPools,
            Reward[][] memory listOfRewardsInEachPool,
            Stake[][] memory listOfStakerStakesInEachPool
        )
    {
        (uint256[] memory ids, , ) = stakerActivity(staker, limit, offset);
        for (uint256 i = 0; i < ids.length; i++) {
            listOfStakerPools[i] = getPool(ids[i]);
            listOfRewardsInEachPool[i] = getRewards(ids[i]);
            listOfStakerStakesInEachPool[i] = getStakes(staker, ids[i]);
        }
    }

    /**
     * @dev Returns arrays containing pool IDs, count of rewards, and count of stakes for each pool,
     *      with pagination controlled by `limit` and `offset`.
     * @param staker The address of the staker being queried.
     * @param limit The maximum number of pool IDs to include in the response.
     * @param offset The starting index for the query, for pagination purposes.
     * @return listOfStakerPoolIds Array of pool IDs the staker has stakes in.
     * @return numberOfRewardsInEachPool Array of the number of rewards available in each pool.
     * @return numberOfStakerStakesInEachPool Array of the number of stakes the staker has in each pool.
     */
    function stakerActivity(
        address staker,
        uint256 limit,
        uint256 offset
    )
        public
        view
        returns (
            uint256[] memory listOfStakerPoolIds,
            uint256[] memory numberOfRewardsInEachPool,
            uint256[] memory numberOfStakerStakesInEachPool
        )
    {
        uint256[] memory poolIds = stakerPoolIds(staker);
        uint256 totalPools = poolIds.length;

        if (offset >= totalPools) {
            return (new uint256[](0), new uint256[](0), new uint256[](0));
        }

        uint256 effectiveLimit = ((offset + limit) > totalPools)
            ? totalPools - offset
            : limit;

        listOfStakerPoolIds = new uint256[](effectiveLimit);
        numberOfRewardsInEachPool = new uint256[](effectiveLimit);
        numberOfStakerStakesInEachPool = new uint256[](effectiveLimit);

        for (uint256 i = 0; i < effectiveLimit; i++) {
            uint256 poolId = poolIds[offset + i];

            listOfStakerPoolIds[i] = poolId;
            numberOfRewardsInEachPool[i] = getRewards(poolId).length;
            numberOfStakerStakesInEachPool[i] = getStakes(staker, poolId)
                .length;
        }
    }

    /**
     * @dev Lists all pool IDs in which a staker has stakes. !!!Potential limit gas error!!!
     * @param staker The address of the staker being queried.
     * @return listOfStakerPoolIds An array of pool IDs in which the staker has stakes.
     */
    function stakerPoolIds(
        address staker
    ) public view returns (uint256[] memory listOfStakerPoolIds) {
        uint256 count = 0;
        for (uint256 i = 0; i < getTotalPools(); i++) {
            if (getStakes(staker, i + 1).length > 0) {
                count++;
            }
        }
        listOfStakerPoolIds = new uint256[](count);
        for (uint256 i = 0; i < getTotalPools(); i++) {
            if (getStakes(staker, i + 1).length > 0) {
                listOfStakerPoolIds[--count] = i + 1;
            }
        }
    }

    /**
     * @dev Returns the number of rewards defined for a specific pool.
     * @param poolId The ID of the pool being queried.
     * @return _ The count of rewards in the specified pool.
     */
    function numberOfRewardsInPool(
        uint256 poolId
    ) external view returns (uint256) {
        return getRewards(poolId).length;
    }

    /**
     * @dev Determines the number of stakes a staker has in a specific pool.
     * @param staker The address of the staker being queried.
     * @param poolId The ID of the pool being queried.
     * @return _ The count of stakes the specified staker has in the pool.
     */
    function numberOfStakerStakesInPool(
        address staker,
        uint256 poolId
    ) external view returns (uint256) {
        return getStakes(staker, poolId).length;
    }

    /**
     * @dev Returns an array representing the claimed amounts for each reward.
     *      Only includes amounts for rewards that have been claimed.
     * @param staker The address of the staker.
     * @param poolId The ID of the pool.
     * @return amounts An array of claimed amounts for each reward in the pool.
     */
    function claimedAmounts(
        address staker,
        uint256 poolId
    ) external view returns (uint256[] memory amounts) {
        amounts = new uint256[](getRewards(poolId).length);
        for (uint256 i = 0; i < amounts.length; i++) {
            StakerReward memory reward = getReward(staker, poolId, i);
            if (reward.stakerAmount > 0 && reward.claimed) {
                amounts[i] = reward.stakerAmount;
            }
        }
    }

    /**
     * @dev Calculates the share of a staker in a specific pool.
     * @param staker The address of the staker.
     * @param poolId The ID of the pool.
     * @param isStakesERC721 True if the calculation is for ERC721 stakes, false for ERC20 stakes.
     * @return _ The staker's share in the pool, multiplied by 10000 for precision.
     */
    function shareOfPool(
        address staker,
        uint256 poolId,
        bool isStakesERC721
    ) public view returns (uint256) {
        uint256 totalStake = 0;
        uint256 totalStaked = isStakesERC721
            ? getPool(poolId).totalStakedERC721
            : getPool(poolId).totalStakedERC20;

        if (totalStaked <= 0) {
            return 0;
        }

        Stake[] memory s = getStakes(staker, poolId);
        for (uint256 i = 0; i < s.length; i++) {
            if (s[i].unstakeBlock <= 0) {
                totalStake += isStakesERC721 ? 1 : s[i].amountERC20;
            }
        }

        return (totalStake * 10000) / totalStaked;
    }
}
