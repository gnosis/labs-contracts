// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {OmenAgentResultMapping} from "../src/OmenAgentResultMapping.sol";
import {Prediction} from "../src/structs.sol";

contract OmenAgentResultMappingTest is Test {
    event AgentResultAdded(
        address indexed marketAddress, bytes32 ipfsHash, address indexed publisherAddress, bytes32 txHash
    );

    OmenAgentResultMapping public omenAgentResultMapping;
    address publisher;
    address marketAddress;

    /// @notice Deploys a new instance of the OmenAgentResultMapping contract before each test.
    function setUp() public {
        omenAgentResultMapping = new OmenAgentResultMapping();
        publisher = vm.addr(1);

        marketAddress = address(this);
    }

    function buildPrediction(string memory input) internal view returns (Prediction memory) {
        // Convert the input string to a bytes32 IPFS hash
        bytes32 ipfsHash = keccak256(abi.encodePacked(input));
        bytes32 dummyTxHash = keccak256(abi.encodePacked("dummy transaction hash"));
        Prediction memory prediction = Prediction(publisher, ipfsHash, dummyTxHash);
        return prediction;
    }

    /// @notice Helper function to add a mock IPFS hash based on a given input string.
    function addMockPrediction(string memory input) internal returns (bytes32) {
        Prediction memory prediction = buildPrediction(input);
        vm.prank(publisher);
        omenAgentResultMapping.addPrediction(marketAddress, prediction);
        return prediction.ipfsHash;
    }

    function testAddAndGetPredictions() public {
        // Add a mock prediction and capture the IPFS hash
        bytes32 expectedHash1 = addMockPrediction("test-input1");
        bytes32 expectedHash2 = addMockPrediction("test-input2");

        // Retrieve the list of IPFS hashes for the sender's address
        Prediction[] memory predictions = omenAgentResultMapping.getPredictions(address(this));
        assertEq(predictions[0].ipfsHash, expectedHash1);
        assertEq(predictions[1].ipfsHash, expectedHash2);
    }

    function testAddPredictionRevertsForNonPublisher() public {
        Prediction memory prediction = buildPrediction("test-input1");

        vm.startPrank(vm.addr(2));
        vm.expectRevert();
        omenAgentResultMapping.addPrediction(marketAddress, prediction);
        vm.stopPrank();
    }

    function testAddPredictionEmitsEvent() public {
        // ToDo - Add Use for Prediction
        Prediction memory prediction = buildPrediction("test-input1");

        vm.expectEmit(true, true, false, true);
        vm.startPrank(publisher);
        emit AgentResultAdded(marketAddress, prediction.ipfsHash, prediction.publisherAddress, prediction.txHash);
        omenAgentResultMapping.addPrediction(marketAddress, prediction);
        vm.stopPrank();
    }

    function testGetByIndex() public {
        bytes32 hash1 = addMockPrediction("test-string-1");
        bytes32 hash2 = addMockPrediction("test-string-2");
        bytes32 hash3 = addMockPrediction("test-string-3");

        Prediction memory prediction1 = omenAgentResultMapping.getPredictionByIndex(marketAddress, 0);
        Prediction memory prediction2 = omenAgentResultMapping.getPredictionByIndex(marketAddress, 1);
        Prediction memory prediction3 = omenAgentResultMapping.getPredictionByIndex(marketAddress, 2);

        assertEq(prediction1.ipfsHash, hash1);
        assertEq(prediction2.ipfsHash, hash2);
        assertEq(prediction3.ipfsHash, hash3);

        // Expect a revert when trying to access an out-of-bounds index
        vm.expectRevert();
        omenAgentResultMapping.getPredictionByIndex(publisher, 3); // Out of bounds
    }
}
