// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 *       _                                         _                              
 *   ___| |_ __ _  __ _  ___   _ __ ___  ___ _ __ | |_ _ __ __ _ _ __   ___ _   _ 
 *  / __| __/ _` |/ _` |/ _ \ | '__/ _ \/ _ \ '_ \| __| '__/ _` | '_ \ / __| | | |
 *  \__ \ || (_| | (_| |  __/ | | |  __/  __/ | | | |_| | | (_| | | | | (__| |_| |
 *  |___/\__\__,_|\__, |\___| |_|  \___|\___|_| |_|\__|_|  \__,_|_| |_|\___|\__, |
 *                   |_|                                                    |___/                                  
 */
abstract contract IStaqeReentrancy is ReentrancyGuard {}