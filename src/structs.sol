// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

struct Prediction {
    address publisherAddress;
    bytes32 ipfsHash;
    bytes32[] txHashes;
    bytes32[] outcomeHashes; // Identifiers for each outcome (e.g., keccak256("Yes"), keccak256("No"), etc.)
    uint16[] estimatedProbabilitiesBps; // Probabilities for each outcome, in basis points, should sum to 10000
}
