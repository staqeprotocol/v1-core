// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StaqeProtocol as Staqe, IERC20, IERC721} from "@staqeprotocol/v1-core/contracts/StaqeProtocol.sol";
import {Toqen, ERC20Toqen, ERC721Toqen} from "@toqen/contracts/src/Toqen.sol";

/**
nano .env
PRIVATE_KEY=""
ETHERSCAN_API_KEY=""
RPC_URL=https://rpc.hekla.taiko.xyz
VERIFIER_URL=https://api-hekla.taikoscan.io/api
DEPLOYER="$(cast wallet address --private-key $PRIVATE_KEY)"
source .env

forge script script/StaqeTaiko.s.sol \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --optimize \
    --optimizer-runs 200

forge verify-contract 0xeDeBF7e35EA8303a7bAeb887579b05f9Bb88Aee4 Toqen \
    --verifier-url $VERIFIER_URL \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args ""

forge verify-contract 0x0d29dE63410CEBed3724225bb76B8BeE33676240 ERC20Toqen \
    --verifier-url $VERIFIER_URL \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address, string, string, uint256, uint256)" $DEPLOYER "Stake Token" "STK" 18000000000000000000000000 0)

forge verify-contract 0x33Ee6c4050736c49496ACb926000Ff4533F01A71 ERC721Toqen \
    --verifier-url $VERIFIER_URL \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address, string, string, uint256, uint256, string)" $DEPLOYER "NFT Token" "NFT" 200 0 "ipfs://bafybeieyb62vnkv46zr5mw3nfqlhcxt7v2frd2tu6k3cwgkqfgwmnyflme/")

forge verify-contract 0xCD25BCcFC2C2ACf53c561f4DaF709601199e8af0 ERC20Toqen \
    --verifier-url $VERIFIER_URL \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address, string, string, uint256, uint256)" $DEPLOYER "Reward Token" "RWD" 18000000000000000000000000 0)

forge verify-contract 0x2Ebf619eC71da95A80865CA748cbCf5fD5690Ce3 ERC721Toqen \
    --verifier-url $VERIFIER_URL \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address, string, string, uint256, uint256, string)" $DEPLOYER "Genesis" "GNS" 200 10000000000000000 "ipfs://bafybeieyb62vnkv46zr5mw3nfqlhcxt7v2frd2tu6k3cwgkqfgwmnyflme/")

forge verify-contract 0xc9b0a1C9AafdF4128549cC80B682832dE5a133a9 StaqeProtocol \
    --verifier-url $VERIFIER_URL \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --optimizer-runs 200 \
    --constructor-args $(cast abi-encode "constructor(address, address, address)" 0x0000000000000000000000000000000000000000 0x2Ebf619eC71da95A80865CA748cbCf5fD5690Ce3 0x0000000000000000000000000000000000000000)

Toqen: 0xeDeBF7e35EA8303a7bAeb887579b05f9Bb88Aee4
Stake ERC20: 0x0d29dE63410CEBed3724225bb76B8BeE33676240
Stake ERC721: 0x33Ee6c4050736c49496ACb926000Ff4533F01A71
Reward ERC20: 0xCD25BCcFC2C2ACf53c561f4DaF709601199e8af0
Genesis NFT: 0x2Ebf619eC71da95A80865CA748cbCf5fD5690Ce3
Staqe Protocol: 0xc9b0a1C9AafdF4128549cC80B682832dE5a133a9

*/
contract StaqeAnvilScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        Toqen toqen = new Toqen();
        console.log("Toqen:", address(toqen));

        ERC20Toqen stake = toqen.createERC20(
            "Stake Token",
            "STK",
            18_000_000 * 10 ** 18,
            0
        );
        console.log("Stake ERC20:", address(stake));

        ERC721Toqen nft = toqen.createERC721(
            "NFT Token",
            "NFT",
            200,
            0,
            "ipfs://bafybeieyb62vnkv46zr5mw3nfqlhcxt7v2frd2tu6k3cwgkqfgwmnyflme/"
        );
        console.log("Stake ERC721:", address(nft));

        ERC20Toqen reward = toqen.createERC20(
            "Reward Token",
            "RWD",
            18_000_000 * 10 ** 18,
            0
        );
        reward.mint(user, 1_000_000 * 10 ** 18);
        console.log("Reward ERC20:", address(reward));

        ERC721Toqen genesis = toqen.createERC721(
            "Genesis",
            "GNS",
            200,
            0.01 ether,
            "ipfs://bafybeieyb62vnkv46zr5mw3nfqlhcxt7v2frd2tu6k3cwgkqfgwmnyflme/"
        );
        console.log("Genesis NFT:", address(genesis));

        Staqe staqe = new Staqe(
            IERC20(address(0)),
            IERC721(address(genesis)),
            IERC20(address(0))
        );
        console.log("Staqe Protocol:", address(staqe));

        vm.stopBroadcast();
    }
}
