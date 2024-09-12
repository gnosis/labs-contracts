// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "forge-std/console.sol";
//import {EnumerableMap} from "../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableMap.sol";

contract OmenAgentResultMapping {
    event PredictionAdded(address indexed marketAddress, bytes32 image_hash, address indexed changer);

    mapping(address => bytes32) private marketAddressToIPFSHashes;

    /// @dev Get IPFS hash of thumbnail for the given market.
    function get(address marketAddress) public view returns (bytes32) {
        return marketAddressToIPFSHashes[marketAddress];
    }

    function set(address marketAddress, bytes32 image_hash) public {
        console.log("%s", marketAddress);
        marketAddressToIPFSHashes[marketAddress] = image_hash;
        emit PredictionAdded(marketAddress, image_hash, msg.sender);
    }
}
