// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StaqeProtocol as Staqe, IERC20, IERC721} from "@staqeprotocol/v1-core/contracts/StaqeProtocol.sol";

import {ERC20Mock} from "../test/mock/ERC20Mock.sol";
import {ERC721Mock, IERC165} from "../test/mock/ERC721Mock.sol";

contract StaqeScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        ERC721Mock genesis = new ERC721Mock("Genesis", "GNS");
        console.log("Genesis NFT:", address(genesis));

        Staqe staqe = new Staqe(
            IERC20(address(0)),
            genesis,
            IERC20(address(0)),
            "Genesis Pool"
        );
        console.log("Staqe:", address(staqe));

        vm.stopBroadcast();
    }
}
