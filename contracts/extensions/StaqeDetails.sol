// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

import {Staqe, ERC20, ERC721, IERC20, IERC721} from "@staqeprotocol/v1-core/contracts/Staqe.sol";

/**
 *       _                         _      _        _ _     
 *   ___| |_ __ _  __ _  ___    __| | ___| |_ __ _(_) |___ 
 *  / __| __/ _` |/ _` |/ _ \  / _` |/ _ \ __/ _` | | / __|
 *  \__ \ || (_| | (_| |  __/ | (_| |  __/ || (_| | | \__ \
 *  |___/\__\__,_|\__, |\___|  \__,_|\___|\__\__,_|_|_|___/
 *                   |_|                                   
 */
abstract contract StaqeDetails is Staqe {
    struct Token {
        address tokenAddress;
        string name;
        string symbol;
        uint256 decimals;
        uint256 balance;
        bool isApproved;
    }

    struct PoolDetails {
        Token stakeERC20;
        Token stakeERC721;
        Token rewardToken;
        address owner;
        string tokenURI;
        uint256 totalRewards;
        uint256 totalStakerStakes;
        uint256 totalMax;
        uint256 totalStakedERC20;
        uint256 totalStakedERC721;
        uint256 launchBlock;
    }

    struct RewardDetails {
        Token rewardToken;
        uint256 stakerRewardAmount;
        bool isClaimed;
        bool isForERC721Stakers;
        uint256 rewardAmount;
        uint256 totalStaked;
        uint256 claimAfterBlocks;
        uint256 rewardBlock;
    }

    /**
     * @notice Retrieves information about a specific token for a user, including name, symbol, 
     *         decimals, balance, and approval status.
     * @param user The address of the user to query the token information for.
     * @param ierc20 The address of the ERC20 token contract. If this is the token type being queried, 
     *               `ierc721` should be zero.
     * @param ierc721 The address of the ERC721 token contract. If this is the token type being queried, 
     *                `ierc20` should be zero.
     * @return token A `Token` struct containing details about the token such as its address, name, 
     *               symbol, decimals, user's balance, and approval status.
     */
    function tokenInfo(
        address user,
        IERC20 ierc20,
        IERC721 ierc721
    ) public view virtual returns (Token memory token) {
        if (address(ierc20) != address(0) && address(ierc721) == address(0)) {
            ERC20 erc20 = ERC20(address(ierc20));
            token = Token({
                tokenAddress: address(erc20),
                name: erc20.name(),
                symbol: erc20.symbol(),
                decimals: erc20.decimals(),
                balance: erc20.balanceOf(user),
                isApproved: erc20.allowance(user, address(this)) == type(uint256).max
            });
        }
        if (address(ierc721) != address(0) && address(ierc20) == address(0)) {
            ERC721 erc721 = ERC721(address(ierc721));
            token = Token({
                tokenAddress: address(erc721),
                name: erc721.name(),
                symbol: erc721.symbol(),
                decimals: 0,
                balance: erc721.balanceOf(user),
                isApproved: erc721.isApprovedForAll(user, address(this))
            });
        }
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
        Pool memory p = getPool(poolId);

        poolDetails = PoolDetails({
            stakeERC20: tokenInfo(staker, p.stakeERC20, IERC721(address(0))),
            stakeERC721: tokenInfo(staker, IERC20(address(0)), p.stakeERC721),
            rewardToken: tokenInfo(staker, p.rewardToken, IERC721(address(0))),
            owner: ownerOf(poolId),
            tokenURI: tokenURI(poolId),
            totalMax: p.totalMax,
            totalStakedERC20: p.totalStakedERC20,
            totalStakedERC721: p.totalStakedERC721,
            totalRewards: getRewards(poolId).length,
            totalStakerStakes: getStakes(staker, poolId).length,
            launchBlock: p.launchBlock
        });
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
        bool isClaimed = false;

        try this.calculateReward(staker, poolId, rewardId) returns (IERC20 _token, uint256 _amount) {
            r.rewardToken = _token;
            stakerRewardAmount = _amount;
        } catch {
            uint256 claimedAmount = getClaimedAmount(staker, poolId, rewardId);
            if (claimedAmount > 0) {
                stakerRewardAmount = claimedAmount;
                isClaimed = true;
            }
        }

        rewardDetails = RewardDetails({
            isForERC721Stakers: r.isForERC721Stakers,
            rewardToken: tokenInfo(staker, r.rewardToken, IERC721(address(0))),
            rewardAmount: r.rewardAmount,
            stakerRewardAmount: stakerRewardAmount,
            totalStaked: r.totalStaked,
            claimAfterBlocks: r.claimAfterBlocks,
            rewardBlock: r.rewardBlock,
            isClaimed: isClaimed
        });
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
}
