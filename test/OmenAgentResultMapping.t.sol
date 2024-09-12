// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {OmenAgentResultMapping} from "../src/OmenAgentResultMapping.sol";

contract OmenAgentResultMappingTest is Test {
    OmenAgentResultMapping public omenAgentResultMapping;

    function setUp() public {
        omenAgentResultMapping = new OmenAgentResultMapping();
    }

    function addMockPrediction(string memory input) internal returns (bytes32) {
        bytes32 ipfsHash = keccak256(abi.encodePacked(input));
        omenAgentResultMapping.set(address(msg.sender), ipfsHash);
        return ipfsHash;
    }

    function testGetPrediction() public {
        bytes32 insertedHash = addMockPrediction("test-input");
        // results
        bytes32[] memory result = omenAgentResultMapping.get(address(msg.sender));
        bytes32 firstHash = result[0];
        assertEq(firstHash, insertedHash);
    }

    function testGetLength() public {
        bytes32 insertedHash = addMockPrediction("test-string");
        uint256 result = omenAgentResultMapping.getHashCount(address(msg.sender));
        assertEq(result, 1);
    }

    function testGetByIndex() public {
        // Add multiple predictions
        bytes32 hash1 = addMockPrediction("test-string-1");
        bytes32 hash2 = addMockPrediction("test-string-2");
        bytes32 hash3 = addMockPrediction("test-string-3");

        // Test retrieval by index
        bytes32 result1 = omenAgentResultMapping.getByIndex(address(msg.sender), 0);
        bytes32 result2 = omenAgentResultMapping.getByIndex(address(msg.sender), 1);
        bytes32 result3 = omenAgentResultMapping.getByIndex(address(msg.sender), 2);

        // Check that the correct hashes are returned
        assertEq(result1, hash1);
        assertEq(result2, hash2);
        assertEq(result3, hash3);

        // Test an invalid index (should revert)
        vm.expectRevert();
        omenAgentResultMapping.getByIndex(address(msg.sender), 3); // Out of bounds
    }
}
