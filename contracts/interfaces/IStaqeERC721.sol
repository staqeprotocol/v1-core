// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/**
 *       _                    _____ ____   ____ _____ ____  _
 *   ___| |_ __ _  __ _  ___  | ____|  _ \ / ___|___  |___ \/ |
 *  / __| __/ _` |/ _` |/ _ \ |  _| | |_) | |      / /  __) | |
 *  \__ \ || (_| | (_| |  __/ | |___|  _ <| |___  / /  / __/| |
 *  |___/\__\__,_|\__, |\___| |_____|_| \_\\____|/_/  |_____|_|
 *                   |_|
 */
abstract contract IStaqeERC721 is ERC721URIStorage {}
