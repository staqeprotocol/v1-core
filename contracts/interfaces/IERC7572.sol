// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

import {ERC721, IERC165} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/** 
 * @title IERC7572 Interface
 * @dev Interface for the EIP-7572 standard for defining contract-level metadata.
 *      https://eips.ethereum.org/EIPS/eip-7572
 */
interface IERC7572 {
    /**
     * @notice Retrieves the contract-level metadata URI.
     * @dev Function to get the URI of the contract-level metadata.
     *      This metadata URI can point to a JSON file that conforms to the "Contract Metadata JSON Schema".
     * @return The URI string of the contract metadata.
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Emitted when the contract URI is updated.
     * @dev This event is emitted when the contract's metadata URI is updated.
     */
    event ContractURIUpdated();
}
