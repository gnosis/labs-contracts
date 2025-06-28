// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import {Prediction} from "./structs.sol";

contract AgentResultMapping {
    event PredictionAdded(
        address indexed marketAddress,
        address indexed publisherAddress,
        string[] outcomes,
        uint16[] estimatedProbabilitiesBps,
        bytes32[] txHashes,
        bytes32 ipfsHash
    );

    string public marketPlatformName;

    mapping(address => Prediction[]) private marketPredictions;

    constructor(string memory _marketPlatformName) {
        marketPlatformName = _marketPlatformName;
    }

    function getPredictions(address marketAddress) public view returns (Prediction[] memory) {
        return marketPredictions[marketAddress];
    }

    function addPrediction(address marketAddress, Prediction memory prediction) public {
        require(msg.sender == prediction.publisherAddress, "Only publisher can add a prediction");
        require(
            prediction.outcomes.length == prediction.estimatedProbabilitiesBps.length,
            "Outcome/probability length mismatch"
        );
        marketPredictions[marketAddress].push(prediction);
        emit PredictionAdded(
            marketAddress,
            prediction.publisherAddress,
            prediction.outcomes,
            prediction.estimatedProbabilitiesBps,
            prediction.txHashes,
            prediction.ipfsHash
        );
    }

    function getPredictionByIndex(address marketAddress, uint256 index) public view returns (Prediction memory) {
        require(index < marketPredictions[marketAddress].length, "Index out of bounds");
        return marketPredictions[marketAddress][index];
    }
}
