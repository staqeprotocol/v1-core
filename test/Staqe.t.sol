// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";

import {StaqeProtocol as Staqe, IERC20, IERC721} from "@staqeprotocol/v1-core/contracts/StaqeProtocol.sol";
import {IStaqeStructs} from "@staqeprotocol/v1-core/contracts/interfaces/IStaqeStructs.sol";
import {IStaqeEvents} from "@staqeprotocol/v1-core/contracts/interfaces/IStaqeEvents.sol";
import {IStaqeErrors} from "@staqeprotocol/v1-core/contracts/interfaces/IStaqeErrors.sol";

import {ERC20Mock, ERC20Permit} from "./mock/ERC20Mock.sol";
import {ERC721Mock, IERC165} from "./mock/ERC721Mock.sol";

contract StaqeTest is Test, IStaqeStructs, IStaqeEvents, IStaqeErrors {
    Staqe public staqe;
    IERC721 private genesis;

    IERC721 private nftA;
    IERC721 private nftB;

    IERC20 private stakeA;
    IERC20 private stakeB;

    IERC20 private rewardA;
    IERC20 private rewardB;

    uint256 blockId = 1;
    address private zero = address(0);
    IERC20 private erc20 = IERC20(address(0));
    IERC721 private erc721 = IERC721(address(0));

    address private user1 = address(1);
    address private user2 = address(2);
    address private user3 = address(3);
    address private user4 = address(4);
    address private user5 = address(5);
    address private user6 = address(5);

    function setUp() public {
        genesis = IERC721(address(new ERC721Mock("Genesis", "GNS")));
        staqe = new Staqe(erc20, genesis, erc20, "Genesis");

        address[4] memory addresses = [user1, user2, user3, user4];

        nftA = IERC721(address(new ERC721Mock("NFT A", "NFTA")));
        nftB = IERC721(address(new ERC721Mock("NFT B", "NFTB")));

        stakeA = IERC20(address(new ERC20Mock("Stake A", "STKA")));
        stakeB = IERC20(address(new ERC20Mock("Stake B", "STKB")));

        rewardA = IERC20(address(new ERC20Mock("Reward A", "REWA")));
        rewardB = IERC20(address(new ERC20Mock("Reward B", "REWB")));

        for (uint i = 0; i < addresses.length; i++) {
            for (uint j = 0; j < 10; j++) {
                ERC721Mock(address(nftA)).mint(addresses[i], (i + 1) * 10 + j);
                ERC721Mock(address(nftB)).mint(addresses[i], (i + 1) * 10 + j);
            }

            ERC721Mock(address(stakeA)).mint(addresses[i], 10000 ether);
            ERC721Mock(address(stakeB)).mint(addresses[i], 10000 ether);

            ERC721Mock(address(rewardA)).mint(addresses[i], 10000 ether);
            ERC721Mock(address(rewardB)).mint(addresses[i], 10000 ether);

            vm.startPrank(addresses[i]);
                nftA.setApprovalForAll(address(staqe), true);
                nftB.setApprovalForAll(address(staqe), true);

                stakeA.approve(address(staqe), type(uint256).max);
                stakeB.approve(address(staqe), type(uint256).max);

                rewardA.approve(address(staqe), type(uint256).max);
                rewardB.approve(address(staqe), type(uint256).max);

                ERC721Mock(address(genesis)).mint(addresses[i], i + 1);
                genesis.setApprovalForAll(address(staqe), true);
                staqe.stake(0, 0, i + 1);
            vm.stopPrank();
        }
    }

    function test_Pool() public {
        vm.expectRevert(OnlyAvailableToStakersInGenesis.selector);
        staqe.launchPool(erc20, erc721, erc20, 0, "Test");

        staqe.setContractURI("URI");
        assertEq(bytes(staqe.contractURI()).length, bytes("URI").length);

        vm.startPrank(user1);
            vm.expectRevert(InvalidERC721Token.selector);
            staqe.launchPool(stakeA, IERC721(address(stakeB)), erc20, 100 ether, "Test");

            vm.expectRevert(InvalidStakeToken.selector);
            staqe.launchPool(erc20, erc721, erc20, 100 ether, "Test");

            vm.expectRevert(InvalidMetadata.selector);
            staqe.launchPool(stakeA, erc721, erc20, 100 ether, "");

            vm.expectRevert(TotalMaxForOnlyOneTypeOfToken.selector);
            staqe.launchPool(stakeA, nftA, erc20, 100 ether, "Test");

            staqe.launchPool(stakeA, erc721, erc20, 100 ether, "Test");
        vm.stopPrank();

        assertEq(staqe.getTotalPools(), 1);
        assertEq(address(staqe.getPool(1).stakeERC20), address(stakeA));

        vm.expectRevert(OnlyOwnerHasAccessToEditMetadata.selector);
        staqe.editPool(1, 10 ether, "New Metadata");

        vm.startPrank(user1);
            vm.expectRevert(PoolDoesNotExist.selector);
            staqe.editPool(2, 10 ether, "New Metadata");

            vm.expectRevert(InvalidMetadata.selector);
            staqe.editPool(1, 10 ether, "");

            staqe.editPool(1, 10 ether, "New Metadata");
        vm.stopPrank();

        assertEq(bytes(staqe.tokenURI(1)).length, bytes("New Metadata").length);

        vm.roll(blockId++);

        vm.startPrank(user2);
            staqe.stake(1, 100 ether, 0);

            vm.expectRevert(MoreThanTheTotalMaxTokens.selector);
            staqe.stake(1, 1 ether, 0);
        vm.stopPrank();

        vm.startPrank(user1);
            staqe.editPool(1, 101 ether, "Increase the total max");
        vm.stopPrank();

        vm.startPrank(user2);
            staqe.stake(1, 1 ether, 0);
        vm.stopPrank();
    }

    function test_Reward() public {
        vm.startPrank(user1);
            staqe.launchPool(stakeA, erc721, erc20, 0, "Test");

            vm.expectRevert(PoolDoesNotHaveStakes.selector);
            staqe.addReward(1, rewardA, 10 ether, 0, false);
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(user2);
            staqe.stake(1, 100 ether, 0);
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(user1);
            vm.expectRevert(PoolDoesNotExist.selector);
            staqe.addReward(2, rewardA, 10 ether, 0, false);

            vm.expectRevert(InvalidRewardToken.selector);
            staqe.addReward(1, erc20, 10 ether, 0, false);

            vm.expectRevert(RewardIsEmpty.selector);
            staqe.addReward(1, rewardA, 0, 0, false);

            staqe.addReward(1, rewardA, 10 ether, 0, false);
        vm.stopPrank();

        assertEq(staqe.getClaimedAmount(user2, 1, 0), 0);

        vm.roll(blockId++);

        assertEq(staqe.getReward(1, 0).totalStaked, 100 ether);

        Reward[] memory rewards = staqe.getRewards(1);
        assertEq(rewards[0].rewardAmount, 10 ether);

        (IERC20 token, uint256 amount) = staqe.calculateReward(user2, 1, 0);

        assertEq(address(token), address(rewardA));
        assertEq(amount, 10 ether);
    }

    function test_Stake() public {
        vm.startPrank(user1);
            staqe.launchPool(stakeA, erc721, erc20, 0, "Test");
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(user2);
            vm.expectRevert(PoolDoesNotExist.selector);
            staqe.stake(2, 90 ether, 0);

            vm.expectRevert(InvalidAmountOrId.selector);
            staqe.stake(1, 0, 0);

            staqe.stake(1, 90 ether, 0);
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(user3);
            staqe.stake(1, 5 ether, 0);
        vm.stopPrank();

        vm.startPrank(user1);
            staqe.addReward(1, rewardA, 190 ether, 0, false);
        vm.stopPrank();

        vm.startPrank(user3);
            vm.expectRevert(StakeOnNextBlockAfterReward.selector);
            staqe.stake(1, 5 ether, 0);

            vm.roll(blockId++);

            staqe.stake(1, 5 ether, 0);
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(user1);
            staqe.addReward(1, rewardA, 100 ether, 0, false);
        vm.stopPrank();

        vm.roll(blockId++);

        assertEq(staqe.getStake(user2, 1, 0).amountERC20, 90 ether);
        assertEq(staqe.getStake(user3, 1, 0).amountERC20, 5 ether);

        Stake[] memory stakes = staqe.getStakes(user3, 1);
        assertEq(stakes[1].amountERC20, 5 ether);

        assertEq(staqe.getReward(1, 0).rewardAmount, 190 ether);
        assertEq(staqe.getReward(1, 1).rewardAmount, 100 ether);
    }

    function test_Claim() public {
        vm.startPrank(user1);
            staqe.launchPool(stakeA, erc721, erc20, 0, "Test 1");
        vm.stopPrank();

        vm.startPrank(user2);
            staqe.launchPool(erc20, nftA, rewardB, 0, "Test 2");
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(user3);
            staqe.stake(1, 90 ether, 0);
            staqe.stake(2, 0, 33);

            vm.expectRevert();
            staqe.stake(1, 90 ether, 33);
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(user4);
            vm.expectRevert();
            staqe.stake(2, 5 ether, 44);

            staqe.stake(1, 5 ether, 0);
            staqe.stake(2, 0, 44);
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(user1);
            staqe.addReward(1, rewardA, 190 ether, 0, false);
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(user2);
            vm.expectRevert(OnlyOwnerHasAccessToAddRewards.selector);
            staqe.addReward(1, rewardB, 90 ether, 0, true);

            staqe.addReward(2, rewardB, 90 ether, 0, true);
        vm.stopPrank();

        vm.roll(blockId++);

        uint256[] memory poolIds = new uint256[](1);
        uint256[][] memory rewardIds = new uint256[][](1);
        rewardIds[0] = new uint256[](1);
        rewardIds[0][0] = 0;

        vm.startPrank(user3);
            poolIds[0] = 1;
            staqe.claimRewards(poolIds, rewardIds, user5);
        vm.stopPrank();

        vm.startPrank(user4);
            poolIds[0] = 2;
            staqe.claimRewards(poolIds, rewardIds, user6);
        vm.stopPrank();

        uint256 balanceA = rewardA.balanceOf(user5);
        uint256 balanceB = rewardB.balanceOf(user6);

        assertEq(balanceA, 180 ether);
        assertEq(balanceB, 45 ether);

        assertEq(staqe.getClaimedAmount(user3, 1, 0), 180 ether);
        assertEq(staqe.getClaimedAmount(user4, 2, 0), 45 ether);
    }

    function test_Unstake() public {
        vm.startPrank(user1);
            staqe.launchPool(stakeA, erc721, erc20, 0, "Test");
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(user3);
            staqe.stake(1, 5 ether, 0);
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(user2);
            staqe.stake(1, 90 ether, 0);
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(user3);
            staqe.stake(1, 5 ether, 0);
        vm.stopPrank();

        vm.roll(blockId++);

        uint256[] memory stakeIds = new uint256[](2);
        stakeIds[0] = 0;
        stakeIds[1] = 1;

        vm.expectRevert(StakerDoesNotHaveStakesInPool.selector);
        staqe.unstake(1, stakeIds);

        uint256 initialBalance = stakeA.balanceOf(user3);

        vm.startPrank(user3);
            staqe.unstake(1, stakeIds);
        vm.stopPrank();

        assertEq(stakeA.balanceOf(user3), initialBalance + 10 ether);
    }

    function test_StakeWithPermit() public {
        vm.startPrank(user1);
            staqe.launchPool(stakeA, erc721, erc20, 0, "Test");
        vm.stopPrank();

        vm.roll(blockId++);

        uint256 initialBalance = stakeA.balanceOf(user2);

        vm.startPrank(user2);
            staqe.stakeWithPermit(1, 100 ether, block.timestamp + 1 days, 0, 0, 0, false);
        vm.stopPrank();

        assertEq(stakeA.balanceOf(user2), initialBalance - 100 ether);

        Staqe.Stake[] memory userStakes = staqe.getStakes(user2, 1);
        assertEq(userStakes.length, 1);
        assertEq(userStakes[0].amountERC20, 100 ether);
    }

    function test_AddRewardWithPermit() public {
        vm.startPrank(user1);
            staqe.launchPool(stakeA, erc721, erc20, 0, "Test");
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(user2);
            staqe.stake(1, 100 ether, 0);
        vm.stopPrank();

        uint256 initialBalance = rewardA.balanceOf(user1);

        vm.startPrank(user1);
            staqe.addRewardWithPermit(
                1,
                rewardA,
                50 ether,
                10,
                false,
                block.timestamp + 1 days,
                0, 0, 0, false
            );
        vm.stopPrank();

        assertEq(rewardA.balanceOf(user1), initialBalance - 50 ether);

        Staqe.Reward[] memory rewards = staqe.getRewards(1);
        assertEq(rewards.length, 1);
        assertEq(rewards[0].rewardAmount, 50 ether);
    }

    function test_StaqeViews() public {
        vm.startPrank(user1);
            staqe.launchPool(stakeA, erc721, erc20, 0, "Test 1");
        vm.stopPrank();

        vm.startPrank(user2);
            staqe.launchPool(erc20, nftA, rewardB, 2, "Test 2");
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(user3);
            staqe.stake(1, 90 ether, 0);
            staqe.stake(2, 0, 33);
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(user1);
            staqe.addReward(1, rewardA, 190 ether, 0, false);
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(user2);
            staqe.addReward(2, rewardB, 90 ether, 0, true);
        vm.stopPrank();

        vm.roll(blockId++);

        uint256[] memory poolIds = new uint256[](1);
        uint256[][] memory rewardIds = new uint256[][](1);
        rewardIds[0] = new uint256[](1);
        rewardIds[0][0] = 0;

        vm.startPrank(user3);
            poolIds[0] = 1;
            staqe.claimRewards(poolIds, rewardIds, user4);
        vm.stopPrank();

        Staqe.PoolDetails memory pool1 = staqe.getPool(user3, 1);
        Staqe.PoolDetails memory pool2 = staqe.getPool(user3, 2);

        Staqe.RewardDetails memory reward1 = staqe.getReward(user3, 1, 0);
        Staqe.RewardDetails memory reward2 = staqe.getReward(user3, 2, 0);

        (IERC20 token, uint256 amount) = staqe.calculateReward(user3, 2, 0);

        Staqe.Token memory tokenInfo = staqe.tokenInfo(user4, rewardA, IERC721(address(0)));

        assertEq(bytes(pool1.metadata).length, bytes("Test 1").length);
        assertEq(pool1.totalStakedERC20, 90 ether);

        assertEq(pool2.totalMax, 2);
        assertEq(pool2.totalStakedERC721, 1);

        assertEq(reward1.rewardToken.token, address(rewardA));
        assertEq(reward2.rewardToken.token, address(rewardB));

        assertEq(address(token), address(rewardB));
        assertEq(amount, 90 ether);

        assertEq(tokenInfo.balanceOf, 10190 ether);
    }
}