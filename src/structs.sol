// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

struct Prediction {
    address marketAddress;
    address publisherAddress;
    bytes32 ipfsHash;
    bytes32[] txHashes;
    string[] outcomes; // Outcomes in the same order as estimatedProbabilitiesBps
    uint16[] estimatedProbabilitiesBps; // Probabilities for each outcome, in basis points, should sum to 10000
}
