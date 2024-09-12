// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import "forge-std/console.sol";

/// @title OmenAgentResultMapping
/// @notice This contract allows for mapping market addresses to IPFS hashes, storing multiple hashes for each market.
/// @dev Each market address can have multiple associated IPFS hashes, which are used to store the results or data associated with that market.
contract OmenAgentResultMapping is AccessControlDefaultAdminRules {
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    /// @notice Emitted when a new IPFS hash is added to a market.
    /// @param marketAddress The address of the market for which the IPFS hash is added.
    /// @param ipfsHash The IPFS hash that was added.
    /// @param changer The address that added the new hash.
    event PredictionAdded(address indexed marketAddress, bytes32 ipfsHash, address indexed changer);

    // Mapping of a market address to an array of IPFS hashes (bytes32).
    mapping(address => bytes32[]) private marketToIPFSHashes;

    constructor()
        AccessControlDefaultAdminRules(
            3 days,
            msg.sender // Explicit initial `DEFAULT_ADMIN_ROLE` holder
        )
    {}

    /// @notice Retrieve all IPFS hashes associated with a given market address.
    /// @param marketAddress The address of the market whose IPFS hashes are being retrieved.
    /// @return An array of bytes32 values, each representing an IPFS hash.
    function getHashes(address marketAddress) public view returns (bytes32[] memory) {
        return marketToIPFSHashes[marketAddress];
    }

    /// @notice Add a new IPFS hash for a given market.
    /// @param marketAddress The address of the market where the hash will be added.
    /// @param ipfsHash The IPFS hash to be associated with the market.
    /// @dev Emits the `PredictionAdded` event after successfully adding the hash.
    function addHash(address marketAddress, bytes32 ipfsHash) public onlyRole(AGENT_ROLE) {
        marketToIPFSHashes[marketAddress].push(ipfsHash);
        emit PredictionAdded(marketAddress, ipfsHash, msg.sender);
    }

    /// @notice Retrieve a specific IPFS hash by its index for a given market address.
    /// @param marketAddress The address of the market.
    /// @param index The index of the IPFS hash to retrieve.
    /// @return The IPFS hash at the given index.
    /// @dev Reverts with "Index out of bounds" if the index is greater than or equal to the number of hashes for the market.
    function getHashByIndex(address marketAddress, uint256 index) public view returns (bytes32) {
        require(index < marketToIPFSHashes[marketAddress].length, "Index out of bounds");
        return marketToIPFSHashes[marketAddress][index];
    }
}
