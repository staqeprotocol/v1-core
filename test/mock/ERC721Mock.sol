// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Mock is ERC721 {
    uint256 private _tokenIdCounter = 0;

    constructor() ERC721("Test", "TST") {}

    function mint(address to) public returns (uint256) {
        _mint(to, ++_tokenIdCounter);
        return _tokenIdCounter;
    }
}
