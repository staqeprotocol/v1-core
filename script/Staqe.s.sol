// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StaqeDeploy, IERC20, IERC721} from "@staqeprotocol/v1-core/contracts/StaqeDeploy.sol";

import {ERC20Mock} from "../test/mock/ERC20Mock.sol";
import {ERC721Mock, IERC165} from "../test/mock/ERC721Mock.sol";

contract StaqeDeployScript is Script {
    function setUp() public {}

    function run() external {
        address userAddress = vm.envAddress("USER_ADDRESS");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        ERC20Mock mockStakeToken = new ERC20Mock();
        mockStakeToken.mint(userAddress, 1000 ether);
        console.log("Stake token:", address(mockStakeToken));

        ERC20Mock mockRewardToken = new ERC20Mock();
        mockRewardToken.mint(userAddress, 1000 ether);
        console.log("Reward token:", address(mockRewardToken));

        ERC721Mock mockNFT = new ERC721Mock();
        ERC721Mock(mockNFT).mint(userAddress);
        ERC721Mock(mockNFT).mint(userAddress);
        console.log("Mock NFT:", address(mockNFT));

        ERC721Mock genesisNFT = new ERC721Mock();
        uint256 id = ERC721Mock(genesisNFT).mint(userAddress);
        ERC721Mock(genesisNFT).mint(userAddress);
        console.log("Genesis NFT:", address(genesisNFT));

        StaqeDeploy staqe = new StaqeDeploy(
            IERC20(address(0)),
            genesisNFT,
            IERC20(address(0)),
            address(0),
            "Genesis"
        );
        console.log("Staqe:", address(staqe));

        ERC721Mock(address(genesisNFT)).setApprovalForAll(address(staqe), true);
        staqe.stake(0, 0, id);

        vm.stopBroadcast();
    }
}
