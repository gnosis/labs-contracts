// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {OmenAgentResultMapping} from "../src/OmenAgentResultMapping.sol";

/// @title OmenAgentResultMappingTest
/// @notice This contract contains tests for the OmenAgentResultMapping contract.
/// @dev It verifies the functionality of adding IPFS hashes, retrieving them, and checking retrieval by index.
contract OmenAgentResultMappingTest is Test {
    OmenAgentResultMapping public omenAgentResultMapping;

    /// @notice Deploys a new instance of the OmenAgentResultMapping contract before each test.
    function setUp() public {
        omenAgentResultMapping = new OmenAgentResultMapping();
        omenAgentResultMapping.grantRole(omenAgentResultMapping.AGENT_ROLE(), address(this));
    }

    /// @notice Helper function to add a mock IPFS hash based on a given input string.
    /// @param input The input string to be hashed and added as an IPFS hash.
    /// @return The generated IPFS hash (bytes32) associated with the input string.
    function addMockPrediction(string memory input) internal returns (bytes32) {
        // Convert the input string to a bytes32 IPFS hash
        bytes32 ipfsHash = keccak256(abi.encodePacked(input));
        // Add the IPFS hash to the contract using the sender's address
        omenAgentResultMapping.addHash(address(msg.sender), ipfsHash);
        // Return the generated IPFS hash
        return ipfsHash;
    }

    /// @notice Test case to verify that a prediction can be added and retrieved correctly.
    function testGetPrediction() public {
        // Add a mock prediction and capture the IPFS hash
        bytes32 expectedHash = addMockPrediction("test-input");

        // Retrieve the list of IPFS hashes for the sender's address
        bytes32[] memory hashes = omenAgentResultMapping.getHashes(address(msg.sender));

        // Check that the first hash in the list matches the expected hash
        bytes32 retrievedHash = hashes[0];
        assertEq(retrievedHash, expectedHash);
    }

    /// @notice Test case to verify that IPFS hashes can be retrieved by index.
    function testGetByIndex() public {
        // Add multiple predictions and capture their IPFS hashes
        bytes32 hash1 = addMockPrediction("test-string-1");
        bytes32 hash2 = addMockPrediction("test-string-2");
        bytes32 hash3 = addMockPrediction("test-string-3");

        // Retrieve the IPFS hashes by their indices
        bytes32 retrievedHash1 = omenAgentResultMapping.getHashByIndex(address(msg.sender), 0);
        bytes32 retrievedHash2 = omenAgentResultMapping.getHashByIndex(address(msg.sender), 1);
        bytes32 retrievedHash3 = omenAgentResultMapping.getHashByIndex(address(msg.sender), 2);

        // Verify that the retrieved hashes match the expected hashes
        assertEq(retrievedHash1, hash1);
        assertEq(retrievedHash2, hash2);
        assertEq(retrievedHash3, hash3);

        // Expect a revert when trying to access an out-of-bounds index
        vm.expectRevert();
        omenAgentResultMapping.getHashByIndex(address(msg.sender), 3); // Out of bounds
    }
}
