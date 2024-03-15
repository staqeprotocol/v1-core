// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StaqeProtocol as Staqe, IERC20, IERC721} from "@staqeprotocol/v1-core/contracts/StaqeProtocol.sol";

import {ERC20Mock} from "../test/mock/ERC20Mock.sol";
import {ERC721Mock, IERC165} from "../test/mock/ERC721Mock.sol";

 /**
  * @dev Genesis Pool block number > 0
  *      anvil --block-time 10
  *      sleep 10 && forge script script/Staqe.s.sol --fork-url http://localhost:8545 --broadcast
  *
  *      Stake ERC20: 0x5FbDB2315678afecb367f032d93F642f64180aa3
  *      Stake ERC721: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
  *      Reward ERC20: 0x0165878A594ca255338adfa4d48449f69242Eb8F
  *      Genesis NFT: 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6
  *      Staqe: 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e
 */
contract StaqeScript is Script {
    function run() external {
        address userAddress = vm.envAddress("USER_ADDRESS");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        ERC20Mock mockStakeToken = new ERC20Mock();
        mockStakeToken.mint(userAddress, 1000 ether);
        console.log("Stake ERC20:", address(mockStakeToken));

        ERC721Mock mockNFT = new ERC721Mock();
        ERC721Mock(mockNFT).mint(userAddress);
        ERC721Mock(mockNFT).mint(userAddress);
        ERC721Mock(mockNFT).mint(userAddress);
        console.log("Stake ERC721:", address(mockNFT));

        ERC20Mock mockRewardToken = new ERC20Mock();
        mockRewardToken.mint(userAddress, 1000 ether);
        console.log("Reward ERC20:", address(mockRewardToken));

        ERC721Mock genesisNFT = new ERC721Mock();
        uint256 id = ERC721Mock(genesisNFT).mint(userAddress);
        ERC721Mock(genesisNFT).mint(userAddress);
        console.log("Genesis NFT:", address(genesisNFT));

        Staqe staqe = new Staqe(
            IERC20(address(0)),
            genesisNFT,
            IERC20(address(0)),
            address(0),
            "Genesis Pool"
        );
        console.log("Staqe:", address(staqe));

        ERC721Mock(address(genesisNFT)).setApprovalForAll(address(staqe), true);
        
        staqe.stake(0, 0, id);

        vm.stopBroadcast();
    }
}
