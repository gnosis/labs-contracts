// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

contract OmenAgentResultMapping {
    event PredictionAdded(address indexed marketAddress, bytes32 image_hash, address indexed changer);

    mapping(address => bytes32[]) private marketAddressToIPFSHashes;

    /// @dev Get IPFS hash of thumbnail for the given market.
    function get(address marketAddress) public view returns (bytes32[] memory) {
        return marketAddressToIPFSHashes[marketAddress];
    }

    function set(address marketAddress, bytes32 image_hash) public {
        marketAddressToIPFSHashes[marketAddress].push(image_hash);
        emit PredictionAdded(marketAddress, image_hash, msg.sender);
    }

    /// @dev Get the total number of hashes for a given market.
    function getHashCount(address marketAddress) public view returns (uint256) {
        return marketAddressToIPFSHashes[marketAddress].length;
    }

    /// @dev Get a specific IPFS hash by index for a given market.
    function getByIndex(address marketAddress, uint256 index) public view returns (bytes32) {
        require(index < marketAddressToIPFSHashes[marketAddress].length, "Index out of bounds");
        return marketAddressToIPFSHashes[marketAddress][index];
    }
}
