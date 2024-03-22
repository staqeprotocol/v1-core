// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StaqeProtocol as Staqe, IERC20, IERC721} from "@staqeprotocol/v1-core/contracts/StaqeProtocol.sol";

import {ERC20Mock} from "../test/mock/ERC20Mock.sol";
import {ERC721Mock, IERC165} from "../test/mock/ERC721Mock.sol";

 /**
  * @dev Genesis Pool block number > 0
  *      anvil --block-time 10
  *      sleep 10 && forge script script/StaqeAnvil.s.sol --fork-url http://localhost:8545 --broadcast
  *
  *      Stake ERC20: 0x5FbDB2315678afecb367f032d93F642f64180aa3
  *      Stake ERC721: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
  *      Reward ERC20: 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6
  *      Genesis NFT: 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e
  *      Staqe: 0x9A676e781A523b5d0C0e43731313A708CB607508
 */
contract StaqeAnvilScript is Script {
    function run() external {
        address anvilUser1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        address anvilUser2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

        uint256 privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        string memory ipfs = "ipfs://QmNXi1bErHzBq1MFN4GGZAcXko6iF6B3Rp3A3et1ZuMJtt";

        uint256[] memory poolIds = new uint256[](1);
        poolIds[0] = 3;
        uint256[][] memory rewardIds = new uint256[][](1);
        rewardIds[0] = new uint256[](1);
        rewardIds[0][0] = 0;
        uint256[] memory stakeIds = new uint256[](1);
        stakeIds[0] = 1;
        
        vm.startBroadcast(privateKey);

        ERC20Mock stake = new ERC20Mock("Stake", "STK");
        stake.mint(anvilUser1, 1000 ether);
        stake.mint(anvilUser2, 1000 ether);
        console.log("Stake ERC20:", address(stake));

        ERC721Mock nft = new ERC721Mock("NFT", "NFT");
        ERC721Mock(nft).mint(anvilUser1, 1);
        ERC721Mock(nft).mint(anvilUser1, 2);
        ERC721Mock(nft).mint(anvilUser1, 3);
        ERC721Mock(nft).mint(anvilUser2, 4);
        console.log("Stake ERC721:", address(nft));

        ERC20Mock reward = new ERC20Mock("Reward", "RWD");
        reward.mint(anvilUser1, 1000 ether);
        reward.mint(anvilUser2, 1000 ether);
        console.log("Reward ERC20:", address(reward));

        ERC721Mock genesis = new ERC721Mock("Genesis", "GNS");
        ERC721Mock(genesis).mint(anvilUser1, 1);
        ERC721Mock(genesis).mint(anvilUser2, 2);
        console.log("Genesis NFT:", address(genesis));

        Staqe staqe = new Staqe(
            IERC20(address(0)),
            genesis,
            IERC20(address(0))
        );
        console.log("Staqe:", address(staqe));

        ERC721Mock(address(genesis)).setApprovalForAll(address(staqe), true);
        ERC721Mock(address(nft)).setApprovalForAll(address(staqe), true);
        ERC20Mock(address(stake)).approve(address(staqe), type(uint256).max);
        ERC20Mock(address(reward)).approve(address(staqe), type(uint256).max);
        
        staqe.stake(0, 0, 1);

        staqe.launchPool(stake, IERC721(address(0)), reward, 100 ether, ipfs);
        staqe.launchPool(IERC20(address(0)), nft, stake, 2, ipfs);
        staqe.launchPool(stake, nft, IERC20(address(0)), 0, ipfs);

        staqe.stake(1, 10 ether, 0);
        staqe.stake(2, 0, 1);
        staqe.stake(3, 10 ether, 2);
        staqe.stake(3, 20 ether, 3);

        staqe.addReward(1, reward, 100 ether, 0, false);
        staqe.addReward(2, stake, 50 ether, 0, true);
        staqe.addReward(3, stake, 10 ether, 0, false);

        vm.stopBroadcast();
    }
}
