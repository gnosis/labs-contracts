// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {OmenAgentResultMapping} from "../src/OmenAgentResultMapping.sol";
import "forge-std/console.sol";

contract OmenAgentResultMappingTest is Test {
    OmenAgentResultMapping public omenAgentResultMapping;

    function setUp() public {
        console.log("%s", "setup");
        omenAgentResultMapping = new OmenAgentResultMapping();
    }

    function testAddPrediction() public {
        console.log("%s", address(msg.sender));
        bytes32 ipfsHash = keccak256(abi.encodePacked("test-string"));
        omenAgentResultMapping.set(address(msg.sender), ipfsHash);
        // results
        bytes32 result = omenAgentResultMapping.get(address(msg.sender));
        assertEq(result, ipfsHash);
    }
}
