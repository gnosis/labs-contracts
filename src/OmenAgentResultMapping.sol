// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import {Prediction} from "./structs.sol";

/// This contract allows for mapping market addresses to IPFS hashes containing agent results.
contract OmenAgentResultMapping {
    event AgentResultAdded(
        address indexed marketAddress, bytes32 indexed ipfsHash, address indexed publisherAddress, bytes32 txHash
    );

    // Mapping of a market address to an array of IPFS hashes (bytes32).
    mapping(address => Prediction[]) private marketToIPFSHashes;

    // We set the deployer as the default admin.
    constructor() {}

    function getHashes(address marketAddress) public view returns (Prediction[] memory) {
        return marketToIPFSHashes[marketAddress];
    }

    // ToDo - Check ConditionalTokens for a >0 address of the sender.
    function addPrediction(address marketAddress, Prediction memory prediction) public {
        require(address(msg.sender) == address(prediction.publisherAddress), "Only publisher can add an IPFS hash");
        marketToIPFSHashes[marketAddress].push(prediction);
        emit AgentResultAdded(marketAddress, prediction.ipfsHash, msg.sender, prediction.txHash);
    }

    /// @notice Retrieve a specific IPFS hash by its index for a given market address.
    /// @dev Reverts with "Index out of bounds" if the index is greater than or equal to the number of hashes for the market.
    function getHashByIndex(address marketAddress, uint256 index) public view returns (Prediction memory) {
        require(index < marketToIPFSHashes[marketAddress].length, "Index out of bounds");
        return marketToIPFSHashes[marketAddress][index];
    }
}
