// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";

import {StaqeDeploy as Staqe, IERC20, IERC721} from "@staqeprotocol/v1-core/contracts/StaqeDeploy.sol";
import {IStaqeStructs} from "@staqeprotocol/v1-core/contracts/interfaces/IStaqeStructs.sol";
import {IStaqeEvents} from "@staqeprotocol/v1-core/contracts/interfaces/IStaqeEvents.sol";
import {IStaqeErrors} from "@staqeprotocol/v1-core/contracts/interfaces/IStaqeErrors.sol";

import {ERC20Mock} from "./mock/ERC20Mock.sol";
import {ERC721Mock, IERC165} from "./mock/ERC721Mock.sol";

contract StaqeTest is Test, IStaqeStructs, IStaqeEvents, IStaqeErrors {
    Staqe public staqe;
    IERC721 private genesisNFT;

    IERC721 private mockStakeERC721TokenA;
    IERC721 private mockStakeERC721TokenB;

    IERC20 private mockStakeERC20TokenA;
    IERC20 private mockStakeERC20TokenB;

    IERC20 private mockRewardERC20TokenA;
    IERC20 private mockRewardERC20TokenB;
    IERC20 private mockRewardERC20TokenC;

    address private testUser1 = address(1);
    address private testUser2 = address(2);
    address private testUser3 = address(3);
    address private testUser4 = address(4);
    address private testUser5 = address(5);

    function setUp() public {
        genesisNFT = IERC721(address(new ERC721Mock()));
        staqe = new Staqe(
            IERC20(address(0)),
            genesisNFT,
            IERC20(address(0)),
            address(0),
            "Genesis"
        );

        address[] memory addresses = new address[](4);
        addresses[0] = testUser1;
        addresses[1] = testUser2;
        addresses[2] = testUser3;
        addresses[3] = testUser4;

        uint96[] memory amounts = new uint96[](4);
        amounts[0] = 10;
        amounts[1] = 10;
        amounts[2] = 10;
        amounts[3] = 10;

        mockStakeERC721TokenA = IERC721(address(new ERC721Mock()));
        mockStakeERC721TokenB = IERC721(address(new ERC721Mock()));

        mockStakeERC20TokenA = IERC20(address(new ERC20Mock()));
        mockStakeERC20TokenB = IERC20(address(new ERC20Mock()));

        mockRewardERC20TokenA = IERC20(address(new ERC20Mock()));
        mockRewardERC20TokenB = IERC20(address(new ERC20Mock()));
        mockRewardERC20TokenC = IERC20(address(new ERC20Mock()));

        address[5] memory testAddresses = [
            address(this),
            testUser1,
            testUser2,
            testUser3,
            testUser4
        ];

        for (uint i = 0; i < testAddresses.length; i++) {
            for (uint j = 0; j < 10; j++) {
                /*
                 * address(this) - 0-9 NFT
                 * testUser1     - 10-19 NFT
                 * testUser2     - 20-29 NFT
                 * testUser3     - 30-39 NFT
                 * testUser4     - 40-49 NFT
                 */
                ERC721Mock(address(mockStakeERC721TokenA)).mint(
                    testAddresses[i]
                );
                ERC721Mock(address(mockStakeERC721TokenB)).mint(
                    testAddresses[i]
                );
            }

            ERC20Mock(address(mockStakeERC20TokenA)).mint(
                testAddresses[i],
                10000 ether
            );
            ERC20Mock(address(mockStakeERC20TokenB)).mint(
                testAddresses[i],
                10000 ether
            );

            ERC20Mock(address(mockRewardERC20TokenA)).mint(
                testAddresses[i],
                10000 ether
            );
            ERC20Mock(address(mockRewardERC20TokenB)).mint(
                testAddresses[i],
                10000 ether
            );
            ERC20Mock(address(mockRewardERC20TokenC)).mint(
                testAddresses[i],
                10000 ether
            );
        }

        for (uint i = 0; i < testAddresses.length; i++) {
            vm.startPrank(testAddresses[i]);
            ERC721Mock(address(mockStakeERC721TokenA)).setApprovalForAll(
                address(staqe),
                true
            );
            ERC721Mock(address(mockStakeERC721TokenB)).setApprovalForAll(
                address(staqe),
                true
            );

            ERC20Mock(address(mockStakeERC20TokenA)).approve(
                address(staqe),
                type(uint256).max
            );
            ERC20Mock(address(mockStakeERC20TokenB)).approve(
                address(staqe),
                type(uint256).max
            );

            ERC20Mock(address(mockRewardERC20TokenA)).approve(
                address(staqe),
                type(uint256).max
            );
            ERC20Mock(address(mockRewardERC20TokenB)).approve(
                address(staqe),
                type(uint256).max
            );
            ERC20Mock(address(mockRewardERC20TokenC)).approve(
                address(staqe),
                type(uint256).max
            );

            uint256 id = ERC721Mock(address(genesisNFT)).mint(testAddresses[i]);
            ERC721Mock(address(genesisNFT)).setApprovalForAll(
                address(staqe),
                true
            );
            staqe.stake(0, 0, id);

            vm.stopPrank();
        }
    }

    function testFuzz_LaunchPool(address rewarder, bytes32 metadata) public {
        vm.assume(metadata != bytes32(0));

        uint256 poolId1 = staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            address(0),
            metadata
        );

        assertEq(poolId1, 1);

        uint256 poolId2 = staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            rewarder,
            "Pool 2"
        );

        assertEq(poolId2, 2);

        Staqe.Pool memory pool1 = staqe.getPool(poolId1);
        Staqe.Pool memory pool2 = staqe.getPool(poolId2);
        Staqe.Pool memory pool3 = staqe.getPool(3);

        assertEq(pool1.metadata, metadata);
        assertEq(pool2.rewarder, rewarder);
        assertEq(address(pool3.rewardToken), address(0));
    }

    function testFuzz_LaunchPool_Errors(address rewarder) public {
        vm.expectRevert();
        staqe.launchPool(
            IERC20(address(0)),
            IERC721(address(1)),
            IERC20(address(0)),
            rewarder,
            "Test"
        );

        vm.expectRevert(InvalidStakeToken.selector);
        staqe.launchPool(
            IERC20(address(0)),
            IERC721(address(0)),
            IERC20(address(0)),
            rewarder,
            bytes32(0)
        );

        vm.expectRevert(InvalidMetadata.selector);
        staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            rewarder,
            bytes32(0)
        );

        vm.expectEmit(true, true, true, true);
        emit PoolLaunched(
            1,
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            rewarder,
            "Pool"
        );
        staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            rewarder,
            "Pool"
        );
    }

    function testFuzz_EditPool(bytes32 metadata) public {
        vm.assume(metadata != bytes32(0));

        uint256 poolId1 = staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            address(0),
            metadata
        );

        assertEq(poolId1, 1);

        uint256 poolId2 = staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            testUser2,
            "Test"
        );

        assertEq(poolId2, 2);

        vm.expectRevert(PoolDoesNotExist.selector);
        staqe.editPool(100, metadata);

        vm.expectRevert(InvalidMetadata.selector);
        staqe.editPool(poolId1, bytes32(0));

        vm.expectRevert(InvalidMetadata.selector);
        staqe.editPool(poolId1, metadata);

        vm.expectRevert(OnlyRewinderHasAccessToEditMetadata.selector);
        staqe.editPool(poolId1, "New Test 1");

        vm.startPrank(testUser1);
        vm.expectRevert(OnlyRewinderHasAccessToEditMetadata.selector);
        staqe.editPool(poolId2, "New Test 2");
        vm.stopPrank();

        vm.startPrank(testUser2);
        staqe.editPool(poolId2, "New Test 3");
        vm.stopPrank();

        Staqe.Pool memory pool1 = staqe.getPool(poolId1);
        Staqe.Pool memory pool2 = staqe.getPool(poolId2);
        Staqe.Pool memory pool3 = staqe.getPool(3);

        assertEq(pool1.metadata, metadata);
        assertEq(pool2.metadata, "New Test 3");
        assertEq(address(pool3.rewardToken), address(0));
    }

    function testFuzz_AddReward(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 100 ether);

        uint256 blockId = 1;

        vm.roll(blockId++);

        uint256 poolId1 = staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            address(0),
            "Pool 1"
        );

        assertEq(poolId1, 1);

        vm.roll(blockId++);

        uint256 poolId2 = staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            testUser1,
            "Pool 2"
        );

        assertEq(poolId2, 2);

        vm.roll(blockId++);

        vm.startPrank(testUser1);
        staqe.stake(poolId1, 100 ether, 0);
        vm.stopPrank();

        vm.roll(blockId++);

        uint256 rewardId1 = staqe.addReward(
            poolId1,
            mockRewardERC20TokenA,
            amount,
            0,
            false
        );

        vm.roll(blockId++);

        uint256 rewardId2 = staqe.addReward(
            poolId1,
            mockRewardERC20TokenB,
            amount,
            0,
            false
        );

        Staqe.Pool memory pool1 = staqe.getPool(poolId1);
        Staqe.Pool memory pool2 = staqe.getPool(poolId2);
        Staqe.Pool memory pool3 = staqe.getPool(3);

        assertEq(pool1.totalStakedERC20, 100 ether);
        assertEq(pool2.totalStakedERC20, 0);
        assertEq(pool3.totalStakedERC20, 0);

        Staqe.Reward[] memory rewards = staqe.getRewards(poolId1);

        assertEq(rewards[rewardId1].rewardAmount, amount);
        assertEq(rewards[rewardId2].totalStaked, 100 ether);
    }

    function testFuzz_AddReward_Errors(bytes32 metadata) public {
        vm.assume(metadata != bytes32(0));

        uint256 poolId1 = staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            address(0),
            metadata
        );

        assertEq(poolId1, 1);

        uint256 poolId2 = staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            testUser1,
            "Pool 2"
        );

        assertEq(poolId2, 2);

        vm.expectRevert(PoolDoesNotExist.selector);
        staqe.addReward(100, mockRewardERC20TokenA, 100 ether, 0, false);

        vm.expectRevert(InvalidRewardToken.selector);
        staqe.addReward(poolId1, IERC20(address(0)), 100 ether, 0, false);

        vm.expectRevert(RewardIsEmpty.selector);
        staqe.addReward(poolId1, mockRewardERC20TokenA, 0, 0, false);

        vm.expectRevert(PoolDoesNotHaveStakes.selector);
        staqe.addReward(poolId1, mockRewardERC20TokenA, 100 ether, 0, true);

        vm.expectRevert(OnlyRewinderHasAccessToAddRewards.selector);
        staqe.addReward(poolId2, mockRewardERC20TokenA, 100 ether, 0, false);

        vm.expectRevert(PoolDoesNotHaveStakes.selector);
        staqe.addReward(poolId1, mockRewardERC20TokenA, 100 ether, 0, false);
    }

    function testFuzz_Stake(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 100 ether);

        uint256 blockId = 1;

        vm.roll(blockId++);

        uint256 poolId1 = staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            address(0),
            "Pool 1"
        );

        assertEq(poolId1, 1);

        vm.roll(blockId++);

        uint256 poolId2 = staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            testUser1,
            "Pool 2"
        );

        assertEq(poolId2, 2);

        vm.roll(blockId++);

        vm.startPrank(testUser1);
        staqe.stake(poolId1, 50 ether, 0); // Add 50 erc20
        staqe.stake(poolId1, 0, 15); // Add 1 erc721 with ID1
        staqe.stake(poolId1, 0, 16); // Add 1 erc721 with ID2
        uint256 stakeId4 = staqe.stake(poolId1, 250 ether, 0); // Add 250 erc20
        vm.stopPrank();

        vm.roll(blockId++);

        uint256 rewardId1 = staqe.addReward(
            poolId1,
            mockRewardERC20TokenA,
            amount,
            0,
            false
        );

        vm.roll(blockId++);

        vm.startPrank(testUser2);
        staqe.stake(poolId1, 200 ether, 0); // Add 200 erc20
        uint256 stakeId6 = staqe.stake(poolId1, 0, 22); // Add 1 erc721 with ID1
        staqe.stake(poolId1, 0, 23); // Add 1 erc721 with ID2
        staqe.stake(poolId1, 150 ether, 0); // Add 150 erc20
        vm.stopPrank();

        vm.roll(blockId++);

        uint256 rewardId2 = staqe.addReward(
            poolId1,
            mockRewardERC20TokenA,
            111 ether,
            0,
            true
        );

        Staqe.Stake[] memory stakesTestUser1 = staqe.getStakes(
            testUser1,
            poolId1
        );
        Staqe.Stake[] memory stakesTestUser2 = staqe.getStakes(
            testUser2,
            poolId1
        );

        assertEq(stakesTestUser1[stakeId4].amountERC20, 250 ether);
        assertEq(stakesTestUser2[stakeId6].idERC721, 22);

        Staqe.Reward[] memory rewards = staqe.getRewards(poolId1);

        assertEq(rewards[rewardId1].totalStaked, 300 ether);
        assertEq(rewards[rewardId2].totalStaked, 4);

        uint256[] memory ids = new uint256[](1);
        ids[0] = poolId1;

        assertEq(staqe.getTotalPools(), 2);
        assertEq(staqe.getRewards(poolId1).length, 2);
        assertEq(staqe.getStakes(testUser2, poolId1).length, 4);
    }

    function testFuzz_Stake_Errors(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 100 ether);

        uint256 poolId1 = staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            address(0),
            "Pool 1"
        );

        assertEq(poolId1, 1);

        uint256 poolId2 = staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            testUser1,
            "Pool 2"
        );

        assertEq(poolId2, 2);

        vm.expectRevert(PoolDoesNotExist.selector);
        staqe.stake(100, 100 ether, 0);

        vm.expectRevert(InvalidAmountOrId.selector);
        staqe.stake(poolId1, 0, 0);
    }

    function test_Unstake() public {
        uint256 blockId = 1;

        assertEq(staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            address(0),
            "Pool 1"
        ), 1);

        assertEq(staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            testUser1,
            "Pool 2"
        ), 2);

        vm.startPrank(testUser1);
        uint256 stakeId1 = staqe.stake(1, 50 ether, 14); // Add 50 erc20 and 1 erc721 ID14
        uint256 stakeId2 = staqe.stake(2, 50 ether, 0); // Add 50 erc20
        uint256 stakeId3 = staqe.stake(2, 0, 15); // Add 1 erc721 ID15
        uint256 stakeId4 = staqe.stake(2, 77 ether, 16); // Add 77 ether erc20 and 1 erc721 ID16
        vm.stopPrank();

        vm.roll(++blockId);

        uint256[] memory stakeIdsPoolId1 = new uint256[](4);
        stakeIdsPoolId1[0] = 100;
        stakeIdsPoolId1[1] = stakeId1;
        stakeIdsPoolId1[2] = stakeId1;
        stakeIdsPoolId1[3] = 200;

        uint256[] memory stakeIdsPoolId2 = new uint256[](7);
        stakeIdsPoolId2[0] = 100;
        stakeIdsPoolId2[1] = stakeId2;
        stakeIdsPoolId2[2] = 200;
        stakeIdsPoolId2[3] = stakeId2;
        stakeIdsPoolId2[4] = stakeId3;
        stakeIdsPoolId2[5] = stakeId4;
        stakeIdsPoolId2[6] = 300;

        uint256 balanceERC20Before = mockStakeERC20TokenA.balanceOf(testUser1);
        uint256 balanceERC721Before = mockStakeERC721TokenA.balanceOf(
            testUser1
        );

        vm.startPrank(testUser1);
        (uint256 amountERC20PoolId2, uint256[] memory idsERC721PoolId2) = staqe
            .unstake(2, stakeIdsPoolId2);
        vm.stopPrank();

        uint256 balanceERC20After = mockStakeERC20TokenA.balanceOf(testUser1);
        uint256 balanceERC721After = mockStakeERC721TokenA.balanceOf(testUser1);

        assertEq(balanceERC20Before, balanceERC20After - 50 ether - 77 ether);
        assertEq(balanceERC721Before, balanceERC721After - 2);

        assertEq(amountERC20PoolId2, 50 ether + 77 ether);
        assertEq(idsERC721PoolId2.length, 2);

        uint256[] memory _idsERC721 = new uint256[](2);
        _idsERC721[0] = 16;
        _idsERC721[1] = 15;

        for (uint256 i = 0; i < idsERC721PoolId2.length; i++) {
            if (idsERC721PoolId2[i] > 0) {
                assertEq(idsERC721PoolId2[i], _idsERC721[i]);
            }
        }

        Stake[] memory stakes = staqe.getStakes(testUser1, 1);

        assertEq(stakes[stakeId1].amountERC20, 50 ether);
        assertEq(stakes[stakeId1].idERC721, 14);
    }

    function testFuzz_Unstake_Errors(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 100 ether);

        uint256 blockId = 1;

        uint256 poolId1 = staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            address(0),
            "Pool 1"
        );

        assertEq(poolId1, 1);

        uint256 poolId2 = staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenA,
            IERC20(address(0)),
            testUser1,
            "Pool 2"
        );

        assertEq(poolId2, 2);

        uint256[] memory stakeIdsMock = new uint256[](3);
        stakeIdsMock[0] = 1;
        stakeIdsMock[1] = 2;
        stakeIdsMock[2] = 3;

        vm.expectRevert(PoolDoesNotHaveStakes.selector);
        staqe.unstake(poolId1, stakeIdsMock);

        vm.expectRevert(PoolDoesNotHaveStakes.selector);
        staqe.unstake(poolId1, new uint256[](0));

        vm.startPrank(testUser1);
        uint256 stakeId1 = staqe.stake(poolId2, amount, 0); // Add amount erc20
        uint256 stakeId2 = staqe.stake(poolId2, 0, 15); // Add 1 erc721 ID15
        uint256 stakeId3 = staqe.stake(poolId2, 111 ether, 16); // Add 111 ether erc20 and 1 erc721 ID16
        vm.stopPrank();

        vm.roll(++blockId);

        uint256[] memory stakeIds = new uint256[](6);
        stakeIds[0] = 100;
        stakeIds[1] = stakeId1;
        stakeIds[2] = 200;
        stakeIds[3] = stakeId2;
        stakeIds[4] = stakeId3;
        stakeIds[5] = 300;

        vm.expectRevert(PoolDoesNotExist.selector);
        staqe.unstake(100, stakeIds);

        vm.startPrank(testUser2);
        vm.expectRevert(PoolDoesNotHaveStakes.selector);
        staqe.unstake(poolId2, stakeIds);
        vm.stopPrank();

        vm.startPrank(testUser1);
        staqe.unstake(poolId2, stakeIds);

        vm.expectRevert(StakerDoesNotHaveStakesInPool.selector);
        staqe.unstake(poolId2, stakeIds);
        vm.stopPrank();
    }

    function test_ClaimRewards() public {
        // Scenarios:
        // 1. Create Pool1
        // 1.1. Stake only ERC721 mockStakeERC721TokenB
        // 1.2. Reward mockRewardERC20TokenC
        // 1.3. Rewarder any users
        // 2. Create Pool2
        // 2.1. Stake only ERC20 mockStakeERC20TokenA
        // 2.2. Reward any tokens
        // 2.3. Rewarder testUser1
        // 3. Create Pool3
        // 3.1. Stake ERC20 mockStakeERC20TokenA and ERC721 mockStakeERC721TokenB
        // 3.2. Reward mockRewardERC20TokenC
        // 3.3. Rewarder testUser2
        // 4. Stake User1
        // 4.1. Stake to Pool1 ERC721:mockStakeERC721TokenB:14
        // 4.2. Stake to Pool1 ERC721:mockStakeERC721TokenB:15
        // 4.3. Stake to Pool2 ERC20:mockStakeERC20TokenA:43
        // 4.4. Stake to Pool2 ERC20:mockStakeERC20TokenA:11
        // 5. Reward Pool1
        // 5.1. Reward mockRewardERC20TokenC:777
        // 5.2. For ERC721 stakers
        // 5.2.1. User1 stake: 4.1. +1
        // 5.2.2. User1 stake: 4.2. +1
        // 5.2.3. User1 reward 2 * mockRewardERC20TokenC:777 / 2
        // 6. Stake User2
        // 6.1. Stake to Pool1 ERC721:mockStakeERC721TokenB:24
        // 6.2. Stake to Pool2 ERC20:mockStakeERC20TokenA:111
        // 6.3. Stake to Pool3 ERC20:mockStakeERC20TokenA:43 ERC721:mockStakeERC721TokenB:26
        // 6.4. Stake to Pool3 ERC20:mockStakeERC20TokenA:22
        // 7. Reward Pool2 (Stake User2 6.2. not calculate, block number Stake == Reward)
        // 7.1. Reward mockRewardERC20TokenA:111
        // 7.2. For ERC20 stakers (after 100 blocks)
        // 7.2.1. User1 stake: 4.3. +43
        // 7.2.2. User1 stake: 4.4. +11
        // 7.2.3. User1 reward (43 + 11) * mockRewardERC20TokenA:111 / (43 + 11)
        // 8. Stake User3
        // 8.1. Stake to Pool2 ERC20:mockStakeERC20TokenA:111
        // 8.2. Stake to Pool2 ERC20:mockStakeERC20TokenA:11
        // 8.3. Stake to Pool3 ERC721:mockStakeERC721TokenB:35
        // 8.4. Stake to Pool3 ERC20:mockStakeERC20TokenA:77 ERC721:mockStakeERC721TokenB:36
        // 9. Stake User4
        // 9.1. Stake to Pool2 ERC20:mockStakeERC20TokenA:55
        // 9.2. Stake to Pool3 ERC721:mockStakeERC721TokenB:45
        // 9.3. Stake to Pool3 ERC20:mockStakeERC20TokenA:44 ERC721:mockStakeERC721TokenB:46
        // 10. Reward Pool3
        // 10.1. Reward mockRewardERC20TokenC:111
        // 10.2. For ERC721 stakers
        // 10.2.1. User2 stake: 6.3. +1
        // 10.2.2. User2 reward 1 * mockRewardERC20TokenC:111 / (1 + 1 + 1 + 1 + 1)
        // 10.2.3. User3 stake: 8.3. +1
        // 10.2.4. User3 stake: 8.4. +1
        // 10.2.5. User3 reward 2 * mockRewardERC20TokenC:111 / (1 + 1 + 1 + 1 + 1)
        // 10.2.6. User4 stake: 9.2. +1
        // 10.2.7. User4 stake: 9.3. +1
        // 10.2.8. User4 reward 2 * mockRewardERC20TokenC:111 / (1 + 1 + 1 + 1 + 1)
        // 11. Stake User4
        // 11.1. Stake to Pool2 ERC20:mockStakeERC20TokenA:44
        // 12. Unstake User3
        // 12.1. Unstake to Pool2 ERC20:mockStakeERC20TokenA:111
        // 12.2. Unstake to Pool2 ERC20:mockStakeERC20TokenA:11
        // 12. Reward Pool2
        // 12.1. Reward mockRewardERC20TokenB:131
        // 12.2. For ERC20 stakers
        // 12.2.1. User1 stake: 4.3. +43
        // 12.2.2. User1 stake: 4.4. +11
        // 10.2.3. User1 reward (43 + 11) * mockRewardERC20TokenB:131 / (43 + 11 + 111 + 55 + 44)
        // 12.2.4. User2 stake: 6.2. +111
        // 10.2.5. User2 reward 111 * mockRewardERC20TokenB:131 / (43 + 11 + 111 + 55 + 44)
        // 12.2.6. User4 stake: 9.1. +55
        // 12.2.7. User4 stake: 11.1. +44
        // 10.2.8. User4 reward (55 + 44) * mockRewardERC20TokenB:131 / (43 + 11 + 111 + 55 + 44)

        uint256 balanceBefore;

        uint256 blockId = 1;

        vm.roll(blockId++);

        assertEq(staqe.launchPool(
            IERC20(address(0)),
            mockStakeERC721TokenB,
            IERC20(mockRewardERC20TokenC),
            address(0),
            "Pool 1"
        ), 1);

        vm.roll(blockId++);

        assertEq(staqe.launchPool(
            mockStakeERC20TokenA,
            IERC721(address(0)),
            IERC20(address(0)),
            testUser1,
            "Pool 2"
        ), 2);

        vm.roll(blockId++);

        assertEq(staqe.launchPool(
            mockStakeERC20TokenA,
            mockStakeERC721TokenB,
            IERC20(mockRewardERC20TokenC),
            testUser2,
            "Pool 3"
        ), 3);

        vm.roll(blockId++);

        vm.startPrank(testUser1);
        staqe.stake(1, 0, 14);
        staqe.stake(1, 0, 15);
        staqe.stake(2, 43 ether, 0);
        staqe.stake(2, 11 ether, 0);
        vm.stopPrank();

        vm.roll(blockId++);

        staqe.addReward(
            1,
            mockRewardERC20TokenC,
            777 ether,
            0,
            true
        );

        vm.roll(blockId++);

        vm.startPrank(testUser2);
        staqe.stake(1, 0, 24);
        staqe.stake(3, 43 ether, 26);
        staqe.stake(3, 22 ether, 0);
        vm.stopPrank();

        vm.startPrank(testUser1);
        staqe.addReward(
            2,
            mockRewardERC20TokenA,
            111 ether,
            100,
            false
        );
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(testUser2);
        staqe.stake(2, 111 ether, 0);
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(testUser3);
        uint256 stakeId9 = staqe.stake(2, 111 ether, 0);
        uint256 stakeId10 = staqe.stake(2, 11 ether, 0);
        staqe.stake(3, 0, 35);
        staqe.stake(3, 77 ether, 36);
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(testUser4);
        staqe.stake(2, 55 ether, 0);
        staqe.stake(3, 0, 45);
        staqe.stake(3, 44 ether, 46);
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(testUser2);
        staqe.addReward(
            3,
            mockRewardERC20TokenC,
            111 ether,
            0,
            true
        );
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(testUser4);
        staqe.stake(2, 44 ether, 0);
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(testUser3);
        uint256[] memory stakeIdsPoolId2 = new uint256[](5);
        stakeIdsPoolId2[0] = 100;
        stakeIdsPoolId2[1] = stakeId9;
        stakeIdsPoolId2[2] = 200;
        stakeIdsPoolId2[3] = stakeId10;
        stakeIdsPoolId2[4] = 300;

        staqe.unstake(2, stakeIdsPoolId2);
        vm.stopPrank();

        vm.roll(blockId++);

        vm.startPrank(testUser1);
        uint256 rewardId4 = staqe.addReward(
            2,
            mockRewardERC20TokenB,
            131 ether,
            0,
            false
        );
        vm.stopPrank();

        vm.roll(blockId++);

        balanceBefore = mockRewardERC20TokenC.balanceOf(testUser5);

        vm.startPrank(testUser1);
        uint256[] memory reward1Pool1 = new uint256[](1);
        reward1Pool1[0] = 1;
        uint256[][] memory reward1Pool1User1 = new uint256[][](1);
        reward1Pool1User1[0] = new uint256[](1);
        reward1Pool1User1[0][0] = 0; // First reward in Pool 1 = Index 0
        staqe.claimRewards(reward1Pool1, reward1Pool1User1, testUser5);
        vm.stopPrank();

        assertEq(
            balanceBefore + 777 ether,
            mockRewardERC20TokenC.balanceOf(testUser5),
            "Reward 1 for User 1"
        );

        vm.roll(blockId + 100);

        balanceBefore = mockRewardERC20TokenA.balanceOf(testUser5) + uint256(
            uint256(uint256(43 ether * 111 ether) / (43 ether + 11 ether)) + 
            uint256(uint256(11 ether * 111 ether) / (43 ether + 11 ether)));

        vm.startPrank(testUser1);
        uint256[] memory reward2Pool2 = new uint256[](1);
        reward2Pool2[0] = 2;
        uint256[][] memory reward2Pool2User1 = new uint256[][](1);
        reward2Pool2User1[0] = new uint256[](1);
        reward2Pool2User1[0][0] = 0; // First reward in Pool 2 = Index 0
        staqe.claimRewards(reward2Pool2, reward2Pool2User1, testUser5);
        vm.stopPrank();

        assertEq(
            balanceBefore,
            mockRewardERC20TokenA.balanceOf(testUser5),
            "Reward 2 for User 1"
        );

        balanceBefore = mockRewardERC20TokenC.balanceOf(testUser5) + (111 ether / 5);

        uint256[] memory pool3 = new uint256[](1);
        pool3[0] = 3;
        uint256[][] memory reward3 = new uint256[][](1);
        reward3[0] = new uint256[](1);
        reward3[0][0] = 0; // First reward in Pool 3 = Index 0

        vm.startPrank(testUser2);
        staqe.claimRewards(pool3, reward3, testUser5);
        vm.stopPrank();

        assertEq(
            balanceBefore,
            mockRewardERC20TokenC.balanceOf(testUser5),
            "Reward 3 for User 2"
        );

        balanceBefore = mockRewardERC20TokenC.balanceOf(testUser5) + (111 ether / 5) + (111 ether / 5);

        vm.startPrank(testUser3);
        staqe.claimRewards(pool3, reward3, testUser5);
        vm.stopPrank();

        assertEq(
            balanceBefore,
            mockRewardERC20TokenC.balanceOf(testUser5),
            "Reward 3 for User 3"
        );

        balanceBefore = mockRewardERC20TokenC.balanceOf(testUser5) + (111 ether / 5) + (111 ether / 5);

        vm.startPrank(testUser4);
        staqe.claimRewards(pool3, reward3, testUser5);
        vm.stopPrank();

        assertEq(
            balanceBefore,
            mockRewardERC20TokenC.balanceOf(testUser5),
            "Reward 3 for User 4"
        );

        uint256[] memory pool2 = new uint256[](1);
        pool2[0] = 2;
        uint256[][] memory reward4 = new uint256[][](1);
        reward4[0] = new uint256[](1);
        reward4[0][0] = rewardId4;

        balanceBefore = mockRewardERC20TokenB.balanceOf(testUser5) + uint256(
            uint256(uint256(43 ether * 131 ether) / (43 ether + 11 ether + 111 ether + 55 ether + 44 ether)) +
            uint256(uint256(11 ether * 131 ether) / (43 ether + 11 ether + 111 ether + 55 ether + 44 ether)));

        vm.startPrank(testUser1);
        staqe.claimRewards(pool2, reward4, testUser5);
        vm.stopPrank();

        assertEq(
            balanceBefore,
            mockRewardERC20TokenB.balanceOf(testUser5),
            "Reward 4 for User 1"
        );

        balanceBefore = mockRewardERC20TokenB.balanceOf(testUser5) + uint256(
            (uint256(111 ether * 131 ether) / (43 ether + 11 ether + 111 ether + 55 ether + 44 ether)));

        vm.startPrank(testUser2);
        staqe.claimRewards(pool2, reward4, testUser5);
        vm.stopPrank();

        assertEq(
            balanceBefore,
            mockRewardERC20TokenB.balanceOf(testUser5),
            "Reward 4 for User 2"
        );

        balanceBefore = mockRewardERC20TokenB.balanceOf(testUser5) + uint256(
            uint256(uint256(55 ether * 131 ether) / (43 ether + 11 ether + 111 ether + 55 ether + 44 ether)) +
            uint256(uint256(44 ether * 131 ether) / (43 ether + 11 ether + 111 ether + 55 ether + 44 ether)));

        vm.startPrank(testUser4);
        staqe.claimRewards(pool2, reward4, testUser5);
        vm.stopPrank();

        assertEq(
            balanceBefore,
            mockRewardERC20TokenB.balanceOf(testUser5),
            "Reward 4 for User 4"
        );
    }
}
