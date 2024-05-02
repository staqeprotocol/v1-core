// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StaqeProtocol as Staqe, IERC20, IERC721} from "@staqeprotocol/v1-core/contracts/StaqeProtocol.sol";
import {Toqen, ERC20Toqen, ERC721Toqen} from "@toqen/contracts/src/Toqen.sol";

/**
nano .env
PRIVATE_KEY=""
ETHERSCAN_API_KEY=""
RPC_URL=https://pre-rpc.bt.io/
VERIFIER_URL=https://api-testnet.bttcscan.com/api
DEPLOYER="$(cast wallet address --private-key $PRIVATE_KEY)"
source .env

forge script script/StaqeBitTorrent.s.sol \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --optimize \
    --optimizer-runs 200 \
    --legacy

forge verify-contract 0x3AE2475877243dD4331c51BABa39832450526597 Toqen \
    --verifier-url $VERIFIER_URL \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args ""

forge verify-contract 0xeA0531fa7A5ccaa2089081e601c431eA61efD91A ERC20Toqen \
    --verifier-url $VERIFIER_URL \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address, string, string, uint256, uint256)" $DEPLOYER "Stake Token" "STK" 18000000000000000000000000 0)

forge verify-contract 0x1799B3184364B99e2C16B93BD9A3C1e1bd444f22 ERC721Toqen \
    --verifier-url $VERIFIER_URL \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address, string, string, uint256, uint256, string)" $DEPLOYER "NFT Token" "NFT" 200 0 "ipfs://bafybeieyb62vnkv46zr5mw3nfqlhcxt7v2frd2tu6k3cwgkqfgwmnyflme/")

forge verify-contract 0x946607Ed13004C87Ccb143Aaa36F8366ee140DE4 ERC20Toqen \
    --verifier-url $VERIFIER_URL \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address, string, string, uint256, uint256)" $DEPLOYER "Reward Token" "RWD" 18000000000000000000000000 0)

forge verify-contract 0xD6c2c72C7e7093D3472f140074AdCA369C06caa7 ERC721Toqen \
    --verifier-url $VERIFIER_URL \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address, string, string, uint256, uint256, string)" $DEPLOYER "Genesis" "GNS" 200 0 "ipfs://bafybeieyb62vnkv46zr5mw3nfqlhcxt7v2frd2tu6k3cwgkqfgwmnyflme/")

forge verify-contract 0x9cbD0A9D9fb8e8c1baA4687E4e8068aDA57a220f StaqeProtocol \
    --verifier-url $VERIFIER_URL \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --optimizer-runs 200 \
    --constructor-args $(cast abi-encode "constructor(address, address, address)" 0x0000000000000000000000000000000000000000 0xD6c2c72C7e7093D3472f140074AdCA369C06caa7 0x0000000000000000000000000000000000000000)

Toqen:          0x3AE2475877243dD4331c51BABa39832450526597
Stake ERC20:    0xeA0531fa7A5ccaa2089081e601c431eA61efD91A
Stake ERC721:   0x1799B3184364B99e2C16B93BD9A3C1e1bd444f22
Reward ERC20:   0x946607Ed13004C87Ccb143Aaa36F8366ee140DE4
Genesis NFT:    0xD6c2c72C7e7093D3472f140074AdCA369C06caa7
Staqe Protocol: 0x9cbD0A9D9fb8e8c1baA4687E4e8068aDA57a220f

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
            0,
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
