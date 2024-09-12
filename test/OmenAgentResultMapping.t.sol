// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {OmenAgentResultMapping} from "../src/OmenAgentResultMapping.sol";

contract OmenAgentResultMappingTest is Test {
    OmenAgentResultMapping public omenAgentResultMapping;

    /// @notice Deploys a new instance of the OmenAgentResultMapping contract before each test.
    function setUp() public {
        omenAgentResultMapping = new OmenAgentResultMapping();
        omenAgentResultMapping.grantRole(omenAgentResultMapping.AGENT_ROLE(), address(this));
    }

    /// @notice Helper function to add a mock IPFS hash based on a given input string.
    function addMockPrediction(string memory input) internal returns (bytes32) {
        // Convert the input string to a bytes32 IPFS hash
        bytes32 ipfsHash = keccak256(abi.encodePacked(input));
        omenAgentResultMapping.addHash(address(msg.sender), ipfsHash);
        return ipfsHash;
    }

    function testAddAndGetHashes() public {
        // Add a mock prediction and capture the IPFS hash
        bytes32 expectedHash1 = addMockPrediction("test-input1");
        bytes32 expectedHash2 = addMockPrediction("test-input2");

        // Retrieve the list of IPFS hashes for the sender's address
        bytes32[] memory hashes = omenAgentResultMapping.getHashes(address(msg.sender));
        assertEq(hashes[0], expectedHash1);
        assertEq(hashes[1], expectedHash2);
    }

    function testGetByIndex() public {
        bytes32 hash1 = addMockPrediction("test-string-1");
        bytes32 hash2 = addMockPrediction("test-string-2");
        bytes32 hash3 = addMockPrediction("test-string-3");

        bytes32 retrievedHash1 = omenAgentResultMapping.getHashByIndex(address(msg.sender), 0);
        bytes32 retrievedHash2 = omenAgentResultMapping.getHashByIndex(address(msg.sender), 1);
        bytes32 retrievedHash3 = omenAgentResultMapping.getHashByIndex(address(msg.sender), 2);

        assertEq(retrievedHash1, hash1);
        assertEq(retrievedHash2, hash2);
        assertEq(retrievedHash3, hash3);

        // Expect a revert when trying to access an out-of-bounds index
        vm.expectRevert();
        omenAgentResultMapping.getHashByIndex(address(msg.sender), 3); // Out of bounds
    }
}
