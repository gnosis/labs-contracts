// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import {Prediction} from "./structs.sol";

contract OmenAgentResultMapping {
    event PredictionAdded(
        address indexed marketAddress,
        uint16 estimatedProbabilityBps,
        address indexed publisherAddress,
        bytes32 txHash,
        bytes32 ipfsHash
    );

    mapping(address => Prediction[]) private marketPredictions;

    constructor() {}

    function getPredictions(address marketAddress) public view returns (Prediction[] memory) {
        return marketPredictions[marketAddress];
    }

    function addPrediction(address marketAddress, Prediction memory prediction) public {
        require(address(msg.sender) == address(prediction.publisherAddress), "Only publisher can add a prediction");
        marketPredictions[marketAddress].push(prediction);
        emit PredictionAdded(
            marketAddress, prediction.estimatedProbabilityBps, msg.sender, prediction.txHash, prediction.ipfsHash
        );
    }

    function getPredictionByIndex(address marketAddress, uint256 index) public view returns (Prediction memory) {
        require(index < marketPredictions[marketAddress].length, "Index out of bounds");
        return marketPredictions[marketAddress][index];
    }
}
