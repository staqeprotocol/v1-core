// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
pragma abicoder v2;

import {IStaqe, IERC20, IERC721, IERC165} from "@staqeprotocol/v1-core/contracts/interfaces/IStaqe.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/**
 *       _                                     _                  _
 *   ___| |_ __ _  __ _  ___   _ __  _ __ ___ | |_ ___   ___ ___ | |
 *  / __| __/ _` |/ _` |/ _ \ | '_ \| '__/ _ \| __/ _ \ / __/ _ \| |
 *  \__ \ || (_| | (_| |  __/ | |_) | | | (_) | || (_) | (_| (_) | |
 *  |___/\__\__,_|\__, |\___| | .__/|_|  \___/ \__\___/ \___\___/|_|
 *                   |_|      |_|
 *
 * @dev Implementation of the {IStaqe} interface.
 */
contract Staqe is IStaqe, Context, ReentrancyGuard {
    uint256 private _totalPools;

    /// @dev Associates pool IDs with `Pool` structs for staking pool configuration and state.
    mapping(uint256 => Pool) private _pools;

    /// @dev Links pool IDs to `Reward` structs arrays, detailing each pool's rewards.
    mapping(uint256 => Reward[]) private _rewards;

    /// @dev Connects stakers and pool IDs to `Stake` structs arrays, showing staker's pool stakes.
    mapping(address => mapping(uint256 => Stake[])) private _stakes;

    /// @dev Indicates claimed rewards by a staker in a pool, keyed by pool and reward indices, to avoid double claims.
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        private _claimedAmount;

    constructor(
        IERC20 stakeERC20,
        IERC721 stakeERC721,
        IERC20 rewardToken,
        address rewarder,
        bytes32 metadata
    ) {
        // Genesis Pool: Stake on this pool to get access to launch new pools.
        _pools[0] = Pool({
            stakeERC20: stakeERC20,
            stakeERC721: stakeERC721,
            rewardToken: rewardToken,
            rewarder: rewarder,
            metadata: metadata,
            totalStakedERC20: 0,
            totalStakedERC721: 0,
            launchBlock: block.number
        });
    }

    /**
     * @notice Retrieves the total number of pools.
     * @return _ The total number of pools.
     */
    function getTotalPools() public view virtual returns (uint256) {
        return _totalPools;
    }

    /**
     * @notice Retrieves details of a specific pool by its ID.
     * @param poolId The ID of the pool to retrieve.
     * @return poolDetails The details of the specified pool.
     */
    function getPool(
        uint256 poolId
    ) public view virtual returns (Pool memory poolDetails) {
        poolDetails = _pools[poolId];
    }

    /**
     * @notice Retrieves pool details for a specific staker by pool ID.
     * @param staker The address of the staker.
     * @param poolId The ID of the pool to retrieve information for.
     * @return poolDetails Detailed information about the pool specific to the staker.
     */
    function getPool(
        address staker,
        uint256 poolId
    ) public view virtual returns (StakerPool memory poolDetails) {
        Pool memory p = _pools[poolId];

        poolDetails = StakerPool({
            stakeERC20: p.stakeERC20,
            stakeERC721: p.stakeERC721,
            rewardToken: p.rewardToken,
            rewarder: p.rewarder,
            metadata: p.metadata,
            totalStakedERC20: p.totalStakedERC20,
            totalStakedERC721: p.totalStakedERC721,
            totalRewards: _rewards[poolId].length,
            totalStakerStakes: _stakes[staker][poolId].length,
            launchBlock: p.launchBlock
        });
    }

    /**
     * @notice Retrieves details of a specific reward in a pool.
     * @param poolId The ID of the pool containing the reward.
     * @param rewardId The ID of the reward within the specified pool.
     * @return rewardDetails The details of the specified reward.
     */
    function getReward(
        uint256 poolId,
        uint256 rewardId
    ) public view virtual returns (Reward memory rewardDetails) {
        if (rewardId < _rewards[poolId].length)
            rewardDetails = _rewards[poolId][rewardId];
    }

    /**
     * @notice Retrieves reward details for a specific staker in a given pool.
     * @param staker The address of the staker.
     * @param poolId The ID of the pool containing the reward.
     * @param rewardId The ID of the reward within the pool.
     * @return rewardDetails Detailed information about the reward specific to the staker.
     */
    function getReward(
        address staker,
        uint256 poolId,
        uint256 rewardId
    ) public view virtual returns (StakerReward memory rewardDetails) {
        Reward memory r = getReward(poolId, rewardId);

        uint256 stakerAmount = 0;
        bool claimed = false;

        try this.calculateReward(staker, poolId, rewardId) returns (IERC20, uint256 _amount) {
            stakerAmount = _amount;
        } catch {
            if (_isClaimed(staker, poolId, rewardId)) {
                stakerAmount = _claimedAmount[staker][poolId][rewardId];
                claimed = true;
            }
        }

        rewardDetails = StakerReward({
            isForERC721Stakers: r.isForERC721Stakers,
            rewardToken: r.rewardToken,
            rewardAmount: r.rewardAmount,
            stakerAmount: stakerAmount,
            totalStaked: r.totalStaked,
            claimAfterBlocks: r.claimAfterBlocks,
            rewardBlock: r.rewardBlock,
            claimed: claimed
        });
    }

    /**
     * @notice Retrieves rewards associated with a specific pool.
     * @param poolId The ID of the pool.
     * @return _ An array of rewards for the specified pool.
     */
    function getRewards(
        uint256 poolId
    ) public view virtual returns (Reward[] memory) {
        return _rewards[poolId];
    }

    /**
     * @notice Retrieves details of a specific stake a user has in a pool.
     * @param staker The address of the staker.
     * @param poolId The ID of the pool.
     * @param stakeId The ID of the specific stake within the pool.
     * @return stakeDetails The stake details.
     */
    function getStake(
        address staker,
        uint256 poolId,
        uint256 stakeId
    ) public view virtual returns (Stake memory stakeDetails) {
        if (stakeId < _stakes[staker][poolId].length) {
            stakeDetails = _stakes[staker][poolId][stakeId];
        }
    }

    /**
     * @notice Fetches stakes for a given staker in a specific pool.
     * @param staker The address of the staker.
     * @param poolId The ID of the pool.
     * @return _ An array of stakes by the staker in the pool.
     */
    function getStakes(
        address staker,
        uint256 poolId
    ) public view virtual returns (Stake[] memory) {
        return _stakes[staker][poolId];
    }

    /**
     * @notice Calculates the reward for a staker in a given pool.
     * @dev This function is an external wrapper around `_calculateReward`,
     *      necessary for try/catch in `getReward`.
     * @param staker The address of the staker.
     * @param poolId The ID of the pool.
     * @param rewardId The ID of the reward within the pool.
     * @return token The ERC20 token in which the reward is denominated.
     * @return amount The amount of reward the staker is eligible to claim.
     */
    function calculateReward(
        address staker,
        uint256 poolId,
        uint256 rewardId
    ) external view returns (IERC20, uint256) {
        return _calculateReward(staker, poolId, rewardId);
    }

    /**
     * @dev See {IStaqe-launchPool}.
     */
    function launchPool(
        IERC20 stakeERC20,
        IERC721 stakeERC721,
        IERC20 rewardToken,
        address rewarder,
        bytes32 metadata
    ) external nonReentrant returns (uint256 poolId) {
        if (!_isActiveStaker(_msgSender(), 0)) {
            revert OnlyAvailableToStakersInGenesis();
        }

        if (
            address(stakeERC721) != address(0) &&
            !_isERC721(address(stakeERC721))
        ) {
            revert InvalidERC721Token();
        }

        if (
            address(stakeERC20) == address(0) &&
            address(stakeERC721) == address(0)
        ) {
            revert InvalidStakeToken();
        }

        if (metadata == bytes32(0)) {
            revert InvalidMetadata();
        }

        poolId = ++_totalPools;

        _pools[poolId] = Pool({
            stakeERC20: stakeERC20,
            stakeERC721: stakeERC721,
            rewardToken: rewardToken,
            rewarder: rewarder,
            metadata: metadata,
            totalStakedERC20: 0,
            totalStakedERC721: 0,
            launchBlock: block.number
        });

        emit PoolLaunched(
            poolId,
            stakeERC20,
            stakeERC721,
            rewardToken,
            rewarder,
            metadata
        );
    }

    /**
     * @dev See {IStaqe-editPool}.
     */
    function editPool(uint256 poolId, bytes32 metadata) external nonReentrant {
        Pool storage pool = _pools[poolId];

        if (pool.launchBlock <= 0) {
            revert PoolDoesNotExist();
        }

        if (pool.metadata == metadata || metadata == bytes32(0)) {
            revert InvalidMetadata();
        }

        if (pool.rewarder == address(0) || pool.rewarder != _msgSender()) {
            revert OnlyRewinderHasAccessToEditMetadata();
        }

        pool.metadata = metadata;

        emit PoolEdited(poolId, metadata);
    }

    /**
     * @dev See {IStaqe-stake}.
     */
    function stake(
        uint256 poolId,
        uint256 amount,
        uint256 id
    ) public nonReentrant returns (uint256 stakeId) {
        Pool storage pool = _pools[poolId];

        if (pool.launchBlock <= 0) {
            revert PoolDoesNotExist();
        }

        if (amount <= 0 && id <= 0) {
            revert InvalidAmountOrId();
        }

        stakeId = _stakes[_msgSender()][poolId].length;

        if (amount > 0) pool.totalStakedERC20 += amount;
        if (id > 0) pool.totalStakedERC721 += 1;

        _stakes[_msgSender()][poolId].push(
            Stake({
                amountERC20: amount,
                idERC721: id,
                stakeBlock: block.number,
                unstakeBlock: 0
            })
        );

        if (
            amount > 0 &&
            !pool.stakeERC20.transferFrom(_msgSender(), address(this), amount)
        ) {
            revert StakeTransferFailed();
        }

        if (id > 0) {
            pool.stakeERC721.transferFrom(_msgSender(), address(this), id);
        }

        emit StakeCreated(_msgSender(), poolId, stakeId, amount, id);
    }

    /**
     * @dev See {IStaqe-addReward}.
     */
    function addReward(
        uint256 poolId,
        IERC20 rewardToken,
        uint256 rewardAmount,
        uint256 claimAfterBlocks,
        bool isForERC721Stakers
    ) public nonReentrant returns (uint256 rewardId) {
        Pool memory pool = _pools[poolId];

        if (pool.launchBlock <= 0) {
            revert PoolDoesNotExist();
        }

        if (address(rewardToken) == address(0)) {
            revert InvalidRewardToken();
        }

        if (
            rewardAmount <= 0 ||
            (isForERC721Stakers && rewardAmount <= pool.totalStakedERC721)
        ) {
            revert RewardIsEmpty();
        }

        if (pool.rewarder != address(0) && pool.rewarder != _msgSender()) {
            revert OnlyRewinderHasAccessToAddRewards();
        }

        if (
            (isForERC721Stakers && pool.totalStakedERC721 <= 0) ||
            (!isForERC721Stakers && pool.totalStakedERC20 <= 0)
        ) {
            revert PoolDoesNotHaveStakes();
        }

        if (address(pool.rewardToken) != address(0)) {
            rewardToken = pool.rewardToken;
        }

        rewardId = _rewards[poolId].length;

        _rewards[poolId].push(
            Reward({
                isForERC721Stakers: isForERC721Stakers,
                rewardToken: rewardToken,
                rewardAmount: rewardAmount,
                totalStaked: isForERC721Stakers
                    ? pool.totalStakedERC721
                    : pool.totalStakedERC20,
                claimAfterBlocks: claimAfterBlocks,
                rewardBlock: block.number
            })
        );

        if (
            !rewardToken.transferFrom(_msgSender(), address(this), rewardAmount)
        ) {
            revert RewardTransferFailed();
        }

        emit RewardAdded(
            poolId,
            rewardId,
            rewardToken,
            rewardAmount,
            pool.totalStakedERC20,
            pool.totalStakedERC721,
            isForERC721Stakers,
            block.number + claimAfterBlocks
        );
    }

    /**
     * @dev See {IStaqe-unstake}.
     */
    function unstake(
        uint256 poolId,
        uint256[] calldata stakeIds
    )
        external
        nonReentrant
        returns (uint256 amountERC20, uint256[] memory idsERC721)
    {
        Pool memory pool = _pools[poolId];

        uint256 countERC721;
        uint256[] memory allERC721;

        (amountERC20, countERC721, allERC721) = _calculateUnstake(
            poolId,
            stakeIds
        );

        if (
            amountERC20 > 0 &&
            !pool.stakeERC20.transfer(_msgSender(), amountERC20)
        ) {
            revert UnstakeTransferFailed();
        }

        if (countERC721 > 0) {
            idsERC721 = new uint256[](countERC721);
            for (uint256 i = 0; i < allERC721.length; i++) {
                if (allERC721[i] <= 0) continue;
                idsERC721[--countERC721] = allERC721[i];
                pool.stakeERC721.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    allERC721[i]
                );
            }
        }

        emit StakeWithdrawn(_msgSender(), poolId, amountERC20, countERC721);
    }

    /**
     * @dev See {IStaqe-claimRewards}.
     */
    function claimRewards(
        uint256[] memory poolIds,
        uint256[][] memory rewardIds,
        address recipient
    )
        external
        nonReentrant
        returns (IERC20[][] memory tokens, uint256[][] memory amounts)
    {
        if (recipient == address(0)) {
            recipient = _msgSender();
        }

        tokens = new IERC20[][](poolIds.length);
        amounts = new uint256[][](poolIds.length);

        for (uint256 p = 0; p < poolIds.length; p++) {
            tokens[p] = new IERC20[](rewardIds[p].length);
            amounts[p] = new uint256[](rewardIds[p].length);
            for (uint256 r = 0; r < rewardIds[p].length; r++) {
                (tokens[p][r], amounts[p][r]) = _calculateReward(
                    _msgSender(),
                    poolIds[p],
                    rewardIds[p][r]
                );
                _claimedAmount[_msgSender()][poolIds[p]][
                    rewardIds[p][r]
                ] = amounts[p][r];
            }
        }

        for (uint256 i = 0; i < poolIds.length; i++) {
            IERC20 t = _pools[poolIds[i]].rewardToken;

            if (address(t) != address(0)) {
                uint256 total = 0;
                for (uint256 j = 0; j < amounts[i].length; j++) {
                    total += amounts[i][j];
                }
                if (total <= 0) revert RewardIsEmpty();
                if (!t.transfer(recipient, total)) {
                    revert RewardTransferFailed();
                }
                emit RewardClaimed(_msgSender(), poolIds[i], 0, t, total);
            } else {
                for (uint256 j = 0; j < tokens[i].length; j++) {
                    if (amounts[i][j] <= 0) revert RewardIsEmpty();
                    if (!tokens[i][j].transfer(recipient, amounts[i][j])) {
                        revert RewardTransferFailed();
                    }
                    emit RewardClaimed(
                        _msgSender(),
                        poolIds[i],
                        rewardIds[i][j],
                        tokens[i][j],
                        amounts[i][j]
                    );
                }
            }
        }
    }

    function _calculateUnstake(
        uint256 poolId,
        uint256[] calldata stakeIds
    )
        internal
        returns (
            uint256 amountERC20,
            uint256 countERC721,
            uint256[] memory allERC721
        )
    {
        Reward[] memory rewards = _rewards[poolId];

        if (
            rewards.length > 0 &&
            rewards[rewards.length - 1].rewardBlock >= block.number
        ) {
            revert UnstakeOnNextBlockAndGetReward();
        }

        Pool storage pool = _pools[poolId];

        if (pool.launchBlock <= 0) {
            revert PoolDoesNotExist();
        }

        Stake[] storage stakes = _stakes[_msgSender()][poolId];

        if (stakeIds.length <= 0 || stakes.length <= 0) {
            revert PoolDoesNotHaveStakes();
        }

        allERC721 = new uint256[](stakeIds.length);

        for (uint256 i = 0; i < stakeIds.length; i++) {
            if (stakeIds[i] >= stakes.length) continue;

            Stake storage s = stakes[stakeIds[i]];

            if (s.unstakeBlock > 0 || s.stakeBlock >= block.number) continue;

            s.unstakeBlock = block.number;
            amountERC20 += s.amountERC20;

            if (s.idERC721 > 0) {
                allERC721[i] = s.idERC721;
                countERC721++;
            }
        }

        if (amountERC20 <= 0 && countERC721 <= 0) {
            revert StakerDoesNotHaveStakesInPool();
        }

        if (amountERC20 > 0) pool.totalStakedERC20 -= amountERC20;
        if (countERC721 > 0) pool.totalStakedERC721 -= countERC721;
    }

    function _calculateReward(
        address staker,
        uint256 poolId,
        uint256 rewardId
    ) internal view returns (IERC20 token, uint256 amount) {
        if (_isClaimed(staker, poolId, rewardId)) {
            revert RewardAlreadyClaimed();
        }

        Reward[] memory rewards = _rewards[poolId];

        if (rewards.length <= rewardId) {
            revert RewardNotFoundInPool();
        }

        Stake[] memory stakes = _stakes[staker][poolId];

        if (stakes.length <= 0) {
            revert StakerDoesNotHaveStakesInPool();
        }

        Reward memory reward = rewards[rewardId];

        if ((reward.rewardBlock + reward.claimAfterBlocks) >= block.number) {
            revert RewardIsNotYetAvailableForClaim();
        }

        for (uint256 i = 0; i < stakes.length; i++) {
            Stake memory s = stakes[i];
            /**
             * If `>=` a potential attack scenario in the same block:
             * - User1 Stake 100 TKN
             * - Total Stake 200 TKN
             * - User1 Unstake 100 TKN
             * - Total Stake 100 TKN
             * - Add Reward 10 RWD
             * - User1 claim 100 TKN / 100 TKN * 10 RWD = 10 RWD
             */
            bool isUnstakedAfterReward = s.unstakeBlock <= 0 ||
                s.unstakeBlock > reward.rewardBlock;
            /**
             * If `<=` is not a problem in the same block:
             * - User1 Stake 100 TKN
             * - Total Stake 200 TKN
             * - User1 Unstake 100 TKN (REVERT stakeBlock == unstakeBlock)
             * - Add Reward 10 RWD
             * - User1 claim 100 TKN / 200 TKN * 10 RWD = 5 RWD
             */
            bool isStakedBeforeReward = s.stakeBlock <= reward.rewardBlock;
            bool isStakeERC20 = !reward.isForERC721Stakers && s.amountERC20 > 0;
            bool isStakeERC721 = reward.isForERC721Stakers && s.idERC721 > 0;

            if (
                isUnstakedAfterReward &&
                isStakedBeforeReward &&
                (isStakeERC20 || isStakeERC721)
            ) {
                amount += isStakeERC20
                    ? (s.amountERC20 * reward.rewardAmount) / reward.totalStaked
                    : reward.rewardAmount / reward.totalStaked;
            }
        }

        if (amount <= 0) revert RewardIsEmpty();

        token = reward.rewardToken;
    }

    function _isClaimed(
        address staker,
        uint256 poolId,
        uint256 rewardId
    ) internal view returns (bool) {
        return _claimedAmount[staker][poolId][rewardId] > 0;
    }

    function _isActiveStaker(
        address staker,
        uint256 poolId
    ) internal view returns (bool) {
        if (
            _pools[poolId].totalStakedERC721 <= 0 &&
            _pools[poolId].totalStakedERC20 <= 0
        ) {
            return false;
        }

        for (uint256 i = 0; i < _stakes[staker][poolId].length; i++) {
            if (_stakes[staker][poolId][i].unstakeBlock <= 0) {
                return true;
            }
        }

        return false;
    }

    function _isERC721(address contractAddress) internal view returns (bool) {
        return IERC165(contractAddress).supportsInterface(0x80ac58cd);
    }
}
