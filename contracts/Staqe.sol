// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
pragma abicoder v2;

import "@staqeprotocol/v1-core/contracts/interfaces/IStaqe.sol";

/**
 *       _
 *   ___| |_ __ _  __ _  ___
 *  / __| __/ _` |/ _` |/ _ \
 *  \__ \ || (_| | (_| |  __/
 *  |___/\__\__,_|\__, |\___|
 *                   |_|
 *
 * @dev Implementation of {IStaqe} interface.
 */
contract Staqe is IStaqe {
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
        IERC20 rewardToken
    ) ERC721("Staqe Pools", "STQ") Ownable(msg.sender) {
        // Genesis Pool: Stake on this pool to get access to launch new pools.
        _pools[0] = Pool({
            stakeERC20: stakeERC20,
            stakeERC721: stakeERC721,
            rewardToken: rewardToken,
            totalMax: 0,
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
    ) public view virtual returns (PoolDetails memory poolDetails) {
        Pool memory p = _pools[poolId];

        poolDetails = PoolDetails({
            stakeERC20: p.stakeERC20,
            stakeERC721: p.stakeERC721,
            rewardToken: p.rewardToken,
            rewarder: ownerOf(poolId),
            metadata: tokenURI(poolId),
            totalMax: p.totalMax,
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
    ) public view virtual returns (RewardDetails memory rewardDetails) {
        Reward memory r = getReward(poolId, rewardId);

        uint256 stakerRewardAmount = 0;
        bool claimed = false;

        try this.calculateReward(staker, poolId, rewardId) returns (IERC20 rewardToken, uint256 _amount) {
            r.rewardToken = rewardToken;
            stakerRewardAmount = _amount;
        } catch {
            if (_isClaimed(staker, poolId, rewardId)) {
                stakerRewardAmount = _claimedAmount[staker][poolId][rewardId];
                claimed = true;
            }
        }

        rewardDetails = RewardDetails({
            isForERC721Stakers: r.isForERC721Stakers,
            rewardToken: r.rewardToken,
            rewardAmount: r.rewardAmount,
            stakerRewardAmount: stakerRewardAmount,
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
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev See {IStaqe-launchPool}.
     */
    function launchPool(
        IERC20 stakeERC20,
        IERC721 stakeERC721,
        IERC20 rewardToken,
        uint256 totalMax,
        string memory metadata
    ) external override nonReentrant returns (uint256 poolId) {
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

        if (bytes(metadata).length == 0) {
            revert InvalidMetadata();
        }

        if (
            totalMax > 0 &&
            address(stakeERC20) != address(0) &&
            address(stakeERC721) != address(0)
        ) {
            revert TotalMaxForOnlyOneTypeOfToken();
        }

        poolId = ++_totalPools;

        _pools[poolId] = Pool({
            stakeERC20: stakeERC20,
            stakeERC721: stakeERC721,
            rewardToken: rewardToken,
            totalMax: totalMax,
            totalStakedERC20: 0,
            totalStakedERC721: 0,
            launchBlock: block.number
        });
        
        _setTokenURI(poolId, metadata);
        _safeMint(_msgSender(), poolId);

        emit Launched(_msgSender(), poolId);
    }

    /**
     * @dev See {IStaqe-editPool}.
     */
    function editPool(
        uint256 poolId,
        uint256 totalMax,
        string memory metadata
    ) external nonReentrant {
        Pool storage pool = _pools[poolId];

        if (pool.launchBlock <= 0) {
            revert PoolDoesNotExist();
        }

        if (bytes(metadata).length == 0) {
            revert InvalidMetadata();
        }

        if (ownerOf(poolId) != _msgSender()) {
            revert OnlyOwnerHasAccessToEditMetadata();
        }

        if (totalMax > pool.totalMax) {
            pool.totalMax = totalMax;
        }

        _setTokenURI(poolId, metadata);
    }

    /**
     * @dev See {IStaqe-stake}.
     */
    function stake(
        uint256 poolId,
        uint256 amount,
        uint256 id
    ) public override nonReentrant returns (uint256 stakeId) {
        Pool storage pool = _pools[poolId];

        if (pool.launchBlock <= 0) {
            revert PoolDoesNotExist();
        }

        if (amount <= 0 && id <= 0) {
            revert InvalidAmountOrId();
        }

        if (
            _rewards[poolId].length > 0 &&
            _rewards[poolId][_rewards[poolId].length - 1].rewardBlock >= block.number
        ) {
            revert StakeOnNextBlockAfterReward();
        }

        stakeId = _stakes[_msgSender()][poolId].length;

        if (amount > 0) pool.totalStakedERC20 += amount;
        if (id > 0) pool.totalStakedERC721 += 1;

        if (pool.totalMax > 0) {
            if (amount > 0 && pool.totalStakedERC20 > pool.totalMax) {
                revert MoreThanTheTotalMaxTokens();
            }
            if (id > 0 && pool.totalStakedERC721 > pool.totalMax) {
                revert MoreThanTheTotalMaxTokens();
            }
        }

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

        emit Staked(_msgSender(), poolId, stakeId);
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
    ) public override nonReentrant returns (uint256 rewardId) {
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

        if (ownerOf(poolId) != _msgSender()) {
            revert OnlyOwnerHasAccessToAddRewards();
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

        emit Rewarded(_msgSender(), poolId, rewardId);
    }

    /**
     * @dev See {IStaqe-unstake}.
     */
    function unstake(
        uint256 poolId,
        uint256[] calldata stakeIds
    )
        external
        override
        nonReentrant
        returns (uint256 amountERC20, uint256[] memory idsERC721)
    {
        Pool memory pool = _pools[poolId];

        uint256 countERC721;

        (amountERC20, countERC721, idsERC721) = _unstake(poolId, stakeIds);

        if (
            amountERC20 > 0 &&
            !pool.stakeERC20.transfer(_msgSender(), amountERC20)
        ) {
            revert UnstakeTransferFailed();
        }

        if (countERC721 > 0) {
            for (uint256 i = 0; i < idsERC721.length; i++) {
                if (idsERC721[i] <= 0) continue;

                // slither-disable-next-line calls-loop
                pool.stakeERC721.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    idsERC721[i]
                );
            }
        }

        emit Unstaked(_msgSender(), poolId);
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
        override
        nonReentrant
        returns (IERC20[][] memory tokens, uint256[][] memory amounts)
    {
        if (recipient == address(0)) recipient = _msgSender();

        (tokens, amounts) = _calculateRewards(poolIds, rewardIds);

        _setClaimedAmounts(poolIds, rewardIds, amounts);

        for (uint256 poolIndex = 0; poolIndex < poolIds.length; poolIndex++) {
            IERC20 rewardToken = _pools[poolIds[poolIndex]].rewardToken;

            if (address(rewardToken) == address(0)) {
                for (uint256 rewardIndex = 0; rewardIndex < rewardIds[poolIndex].length; rewardIndex++) {
                    uint256 amount = amounts[poolIndex][rewardIndex];

                    if (amount <= 0) revert RewardIsEmpty();

                    // slither-disable-next-line calls-loop
                    if (!tokens[poolIndex][rewardIndex].transfer(recipient, amount)) {
                        revert RewardTransferFailed();
                    }
                }
            } else {
                uint256 totalAmount = 0;
                for (uint256 rewardIndex = 0; rewardIndex < rewardIds[poolIndex].length; rewardIndex++) {
                    totalAmount += amounts[poolIndex][rewardIndex];
                }

                if (totalAmount <= 0) revert RewardIsEmpty();

                // slither-disable-next-line calls-loop
                if (!rewardToken.transfer(recipient, totalAmount)) {
                    revert RewardTransferFailed();
                }
            }

            emit Claimed(_msgSender(), poolIds[poolIndex]);
        }
    }

    function _unstake(
        uint256 poolId,
        uint256[] calldata stakeIds
    )
        internal
        returns (
            uint256 amountERC20,
            uint256 countERC721,
            uint256[] memory idsERC721
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
            revert StakerDoesNotHaveStakesInPool();
        }

        (amountERC20, countERC721, idsERC721) = _calculateUnstake(poolId, stakeIds);

        if (amountERC20 <= 0 && countERC721 <= 0) {
            revert StakerDoesNotHaveStakesInPool();
        }

        if (amountERC20 > 0) pool.totalStakedERC20 -= amountERC20;
        if (countERC721 > 0) pool.totalStakedERC721 -= countERC721;
    }

    function _calculateUnstake(
        uint256 poolId,
        uint256[] calldata stakeIds
    )
        internal
        returns (
            uint256 amountERC20,
            uint256 countERC721,
            uint256[] memory idsERC721
        )
    {
        idsERC721 = new uint256[](stakeIds.length);

        for (uint256 stakeIndex = 0; stakeIndex < stakeIds.length; stakeIndex++) {
            if (stakeIds[stakeIndex] >= _stakes[_msgSender()][poolId].length) {
                revert InvalidStakeId();
            }

            Stake storage s = _stakes[_msgSender()][poolId][stakeIds[stakeIndex]];

            if (s.unstakeBlock > 0 || s.stakeBlock >= block.number) {
                revert StakeAlreadyUnstaked();
            }

            s.unstakeBlock = block.number;
            amountERC20 += s.amountERC20;

            if (s.idERC721 > 0) {
                idsERC721[stakeIndex] = s.idERC721;
                countERC721++;
            }
        }
    }

    function _calculateRewards(
        uint256[] memory poolIds,
        uint256[][] memory rewardIds
    ) internal view returns (IERC20[][] memory tokens, uint256[][] memory amounts) {
        tokens = new IERC20[][](poolIds.length);
        amounts = new uint256[][](poolIds.length);

        for (uint256 poolIndex = 0; poolIndex < poolIds.length; poolIndex++) {
            tokens[poolIndex] = new IERC20[](rewardIds[poolIndex].length);
            amounts[poolIndex] = new uint256[](rewardIds[poolIndex].length);

            for (uint256 rewardIndex = 0; rewardIndex < rewardIds[poolIndex].length; rewardIndex++) {
                (tokens[poolIndex][rewardIndex], amounts[poolIndex][rewardIndex]) = _calculateReward(
                    _msgSender(),
                    poolIds[poolIndex],
                    rewardIds[poolIndex][rewardIndex]
                );
            }
        }
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

    function _setClaimedAmounts(
        uint256[] memory poolIds,
        uint256[][] memory rewardIds,
        uint256[][] memory amounts
    ) internal {
        for (uint256 poolIndex = 0; poolIndex < poolIds.length; poolIndex++) {
            for (uint256 rewardIndex = 0; rewardIndex < rewardIds[poolIndex].length; rewardIndex++) {
                _claimedAmount[_msgSender()][poolIds[poolIndex]][
                    rewardIds[poolIndex][rewardIndex]
                ] = amounts[poolIndex][rewardIndex];
            }
        }
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
        try IERC165(contractAddress).supportsInterface(0x80ac58cd) returns (bool isERC721) {
            return isERC721;
        } catch {
            return false;
        }
    }
}
