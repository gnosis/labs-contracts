// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";

/// This contract allows for mapping market addresses to IPFS hashes containing agent results.
contract OmenAgentResultMapping is AccessControlDefaultAdminRules {
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    event AgentResultAdded(address indexed marketAddress, bytes32 ipfsHash, address indexed changer);

    // Mapping of a market address to an array of IPFS hashes (bytes32).
    mapping(address => bytes32[]) private marketToIPFSHashes;

    // We set the deployer as the default admin.
    constructor()
        AccessControlDefaultAdminRules(
            3 days,
            msg.sender // Explicit initial `DEFAULT_ADMIN_ROLE` holder
        )
    {}

    function getHashes(address marketAddress) public view returns (bytes32[] memory) {
        return marketToIPFSHashes[marketAddress];
    }

    function addHash(address marketAddress, bytes32 ipfsHash) public onlyRole(AGENT_ROLE) {
        marketToIPFSHashes[marketAddress].push(ipfsHash);
        emit AgentResultAdded(marketAddress, ipfsHash, msg.sender);
    }

    /// @notice Retrieve a specific IPFS hash by its index for a given market address.
    /// @dev Reverts with "Index out of bounds" if the index is greater than or equal to the number of hashes for the market.
    function getHashByIndex(address marketAddress, uint256 index) public view returns (bytes32) {
        require(index < marketToIPFSHashes[marketAddress].length, "Index out of bounds");
        return marketToIPFSHashes[marketAddress][index];
    }
}
