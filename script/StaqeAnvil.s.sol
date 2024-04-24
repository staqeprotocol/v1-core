// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StaqeProtocol as Staqe, IERC20, IERC721} from "@staqeprotocol/v1-core/contracts/StaqeProtocol.sol";
import {Toqen, ERC20Toqen, ERC721Toqen} from "@toqen/contracts/Toqen.sol";

/**
 * @dev Genesis Pool block number > 0
 *      anvil --block-time 10
 *      sleep 10 && forge script script/StaqeAnvil.s.sol --fork-url http://localhost:8545 --broadcast
 *
 *      IPFS NFTs:     ipfs://bafybeieyb62vnkv46zr5mw3nfqlhcxt7v2frd2tu6k3cwgkqfgwmnyflme/
 *      Pool Metadata: ipfs://bafybeic6soo6e6ztcqpx7cm6d6h23sjf2ib2hammjfc4fncdfugryfr534/
 *
 *      Toqen:          0x5FbDB2315678afecb367f032d93F642f64180aa3
 *      Stake ERC20:    0xa16E02E87b7454126E5E10d957A927A7F5B5d2be
 *      Stake ERC721:   0xB7A5bd0345EF1Cc5E66bf61BdeC17D2461fBd968
 *      Reward ERC20:   0xeEBe00Ac0756308ac4AaBfD76c05c4F3088B8883
 *      Genesis NFT:    0x10C6E9530F1C1AF873a391030a1D9E8ed0630D26
 *      Staqe Protocol: 0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82
 *      Other ERC20:    0x603E1BD79259EbcbAaeD0c83eeC09cA0B89a5bcC
 */
contract StaqeAnvilScript is Script {
    function run() external {
        address anvilUser1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        address anvilUser2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

        uint256 privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        string
            memory poolIpfs = "ipfs://bafybeic6soo6e6ztcqpx7cm6d6h23sjf2ib2hammjfc4fncdfugryfr534/";
        string
            memory nftIpfs = "ipfs://bafybeieyb62vnkv46zr5mw3nfqlhcxt7v2frd2tu6k3cwgkqfgwmnyflme/";

        uint256[] memory poolIds = new uint256[](1);
        poolIds[0] = 3;
        uint256[][] memory rewardIds = new uint256[][](1);
        rewardIds[0] = new uint256[](1);
        rewardIds[0][0] = 0;
        uint256[] memory stakeIds = new uint256[](1);
        stakeIds[0] = 1;

        vm.startBroadcast(privateKey);

        console.log("Pool Metadata:", poolIpfs);
        console.log("IPFS NFTs:", nftIpfs);
        console.log("");

        Toqen toqen = new Toqen();
        console.log("Toqen:", address(toqen));

        ERC20Toqen stake = toqen.createERC20(
            "Stake Token",
            "STK",
            18_000_000 * 10 ** 18,
            0
        );
        stake.mint(anvilUser1, 1_000_000 * 10 ** 18);
        stake.mint(anvilUser2, 1_000_000 * 10 ** 18);
        console.log("Stake ERC20:", address(stake));

        ERC721Toqen nft = toqen.createERC721(
            "NFT Token",
            "NFT",
            200,
            0,
            nftIpfs
        );
        nft.mint(anvilUser1, 3);
        nft.mint(anvilUser2, 1);
        console.log("Stake ERC721:", address(nft));

        ERC20Toqen reward = toqen.createERC20(
            "Reward Token",
            "RWD",
            18_000_000 * 10 ** 18,
            0
        );
        reward.mint(anvilUser1, 1_000_000 * 10 ** 18);
        reward.mint(anvilUser2, 1_000_000 * 10 ** 18);
        console.log("Reward ERC20:", address(reward));

        ERC721Toqen genesis = toqen.createERC721(
            "Genesis",
            "GNS",
            200,
            0,
            nftIpfs
        );
        genesis.mint(anvilUser1, 1);
        genesis.mint(anvilUser2, 1);
        console.log("Genesis NFT:", address(genesis));

        Staqe staqe = new Staqe(
            IERC20(address(0)),
            IERC721(address(genesis)),
            IERC20(address(0))
        );
        console.log("Staqe Protocol:", address(staqe));

        ERC20Toqen other = toqen.createERC20(
            "Approve",
            "APRV",
            18_000_000 * 10 ** 18,
            0
        );
        other.mint(anvilUser1, 1_000_000 * 10 ** 18);
        other.mint(anvilUser2, 1_000_000 * 10 ** 18);
        console.log("Other ERC20:", address(other));

        genesis.setApprovalForAll(address(staqe), true);
        nft.setApprovalForAll(address(staqe), true);
        stake.approve(address(staqe), type(uint256).max);
        reward.approve(address(staqe), type(uint256).max);

        staqe.stake(0, 0, 1);

        staqe.launchPool(
            IERC20(address(stake)),
            IERC721(address(0)),
            IERC20(address(reward)),
            100 ether,
            poolIpfs
        );
        staqe.launchPool(
            IERC20(address(0)),
            IERC721(address(nft)),
            IERC20(address(stake)),
            2,
            poolIpfs
        );
        staqe.launchPool(
            IERC20(address(stake)),
            IERC721(address(nft)),
            IERC20(address(0)),
            0,
            poolIpfs
        );
        staqe.launchPool(
            IERC20(address(stake)),
            IERC721(address(0)),
            IERC20(address(0)),
            0,
            poolIpfs
        );
        staqe.launchPool(
            IERC20(address(0)),
            IERC721(address(nft)),
            IERC20(address(0)),
            0,
            poolIpfs
        );

        staqe.stake(1, 10 ether, 0);
        staqe.stake(2, 0, 1);
        staqe.stake(3, 10 ether, 2);
        staqe.stake(3, 20 ether, 3);

        staqe.addReward(1, IERC20(address(reward)), 100 ether, 0, false);
        staqe.addReward(2, IERC20(address(stake)), 50 ether, 0, true);
        staqe.addReward(2, IERC20(address(stake)), 10 ether, 0, true);
        staqe.addReward(3, IERC20(address(stake)), 11 ether, 0, true);
        staqe.addReward(3, IERC20(address(stake)), 33 ether, 0, false);
        staqe.addReward(3, IERC20(address(stake)), 22 ether, 0, false);

        vm.stopBroadcast();
    }
}
