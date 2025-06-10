// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {AgentResultMapping} from "../src/AgentResultMapping.sol";
import {Prediction} from "../src/structs.sol";

contract AgentResultMappingTest is Test {
    AgentResultMapping public agentResultMapping;
    address publisher;
    address marketAddress;

    // Example categorical outcomes
    bytes32 constant OUTCOME_YES = keccak256("Yes");
    bytes32 constant OUTCOME_NO = keccak256("No");

    function setUp() public {
        agentResultMapping = new AgentResultMapping("TestingPlatform");
        publisher = vm.addr(1);
        // We mock the market address value as being the address of this test contract.
        marketAddress = address(this);
    }

    function buildPrediction(string memory input) internal view returns (Prediction memory) {
        // Convert the input string to a bytes32 IPFS hash
        bytes32 ipfsHash = keccak256(abi.encodePacked(input));
        bytes32 dummyTxHash = keccak256(abi.encodePacked("dummy transaction hash"));

        // Categorical outcomes: Yes/No
        bytes32[] memory outcomeHashes = new bytes32[](2);
        outcomeHashes[0] = OUTCOME_YES;
        outcomeHashes[1] = OUTCOME_NO;

        // Probabilities for each outcome, must sum to 10000 (basis points)
        uint16[] memory estimatedProbabilitiesBps = new uint16[](2);
        estimatedProbabilitiesBps[0] = 6556; // 65.56% for "Yes"
        estimatedProbabilitiesBps[1] = 3444; // 34.44% for "No"

        // Transaction hashes
        bytes32[] memory txHashes = new bytes32[](2);
        txHashes[0] = dummyTxHash;
        txHashes[1] = dummyTxHash;

        Prediction memory prediction = Prediction({
            publisherAddress: publisher,
            ipfsHash: ipfsHash,
            txHashes: txHashes,
            outcomeHashes: outcomeHashes,
            estimatedProbabilitiesBps: estimatedProbabilitiesBps
        });
        return prediction;
    }

    function addMockPrediction(string memory input) internal returns (bytes32) {
        Prediction memory prediction = buildPrediction(input);
        vm.prank(publisher);
        agentResultMapping.addPrediction(marketAddress, prediction);
        return prediction.ipfsHash;
    }

    function testAddAndGetPredictions() public {
        // Add a mock prediction and capture the IPFS hash
        bytes32 expectedHash1 = addMockPrediction("test-input1");
        bytes32 expectedHash2 = addMockPrediction("test-input2");

        Prediction[] memory predictions = agentResultMapping.getPredictions(address(this));
        assertEq(predictions[0].ipfsHash, expectedHash1);
        assertEq(predictions[1].ipfsHash, expectedHash2);

        // Also check categorical outcomes and probabilities
        assertEq(predictions[0].outcomeHashes.length, 2);
        assertEq(predictions[0].outcomeHashes[0], OUTCOME_YES);
        assertEq(predictions[0].outcomeHashes[1], OUTCOME_NO);
        assertEq(predictions[0].estimatedProbabilitiesBps[0], 6556);
        assertEq(predictions[0].estimatedProbabilitiesBps[1], 3444);
    }

    function testAddPredictionRevertsForNonPublisher() public {
        Prediction memory prediction = buildPrediction("test-input1");

        vm.startPrank(vm.addr(2));
        vm.expectRevert();
        agentResultMapping.addPrediction(marketAddress, prediction);
        vm.stopPrank();
    }

    function testAddPredictionEmitsEvent() public {
        Prediction memory prediction = buildPrediction("test-input1");

        vm.expectEmit(true, true, false, true);
        vm.startPrank(publisher);
        emit AgentResultMapping.PredictionAdded(
            marketAddress,
            prediction.publisherAddress,
            prediction.outcomeHashes,
            prediction.estimatedProbabilitiesBps,
            prediction.txHashes,
            prediction.ipfsHash
        );
        agentResultMapping.addPrediction(marketAddress, prediction);
        vm.stopPrank();
    }

    function testGetByIndex() public {
        bytes32 hash1 = addMockPrediction("test-string-1");
        bytes32 hash2 = addMockPrediction("test-string-2");
        bytes32 hash3 = addMockPrediction("test-string-3");

        Prediction memory prediction1 = agentResultMapping.getPredictionByIndex(marketAddress, 0);
        Prediction memory prediction2 = agentResultMapping.getPredictionByIndex(marketAddress, 1);
        Prediction memory prediction3 = agentResultMapping.getPredictionByIndex(marketAddress, 2);

        assertEq(prediction1.ipfsHash, hash1);
        assertEq(prediction2.ipfsHash, hash2);
        assertEq(prediction3.ipfsHash, hash3);

        // Check categorical outcomes and probabilities for one of the predictions
        assertEq(prediction1.outcomeHashes.length, 2);
        assertEq(prediction1.outcomeHashes[0], OUTCOME_YES);
        assertEq(prediction1.outcomeHashes[1], OUTCOME_NO);
        assertEq(prediction1.estimatedProbabilitiesBps[0], 6556);
        assertEq(prediction1.estimatedProbabilitiesBps[1], 3444);

        // Expect a revert when trying to access an out-of-bounds index
        vm.expectRevert();
        agentResultMapping.getPredictionByIndex(publisher, 3); // Out of bounds
    }
}
