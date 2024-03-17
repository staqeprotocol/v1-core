// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721, IERC165} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Mock is ERC721 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId); // NFT #0 not support for staking
    }
}
