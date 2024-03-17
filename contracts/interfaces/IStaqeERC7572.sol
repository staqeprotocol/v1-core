// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

import {ERC721, IERC7572, IERC165} from "@staqeprotocol/v1-core/contracts/interfaces/IERC7572.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 *       _                     _____ ____   ____ _____ ____ _____ ____  
 *   ___| |_ __ _  __ _  ___  | ____|  _ \ / ___|___  | ___|___  |___ \ 
 *  / __| __/ _` |/ _` |/ _ \ |  _| | |_) | |      / /|___ \  / /  __) |
 *  \__ \ || (_| | (_| |  __/ | |___|  _ <| |___  / /  ___) |/ /  / __/ 
 *  |___/\__\__,_|\__, |\___| |_____|_| \_\\____|/_/  |____//_/  |_____|
 *                   |_|                                                
 */
abstract contract IStaqeERC7572 is IERC7572, Ownable {
    string _contractURI = "";

    /**
     * @dev See {IERC7572-contractURI}.
     */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev See https://eips.ethereum.org/EIPS/eip-7572
     */
    function setContractURI(string memory newURI) external onlyOwner {
        _contractURI = newURI;
        emit ContractURIUpdated();
    }
}
