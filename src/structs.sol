// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

struct Prediction {
    address marketAddress;
    address publisherAddress;
    bytes32 ipfsHash;
    bytes[] txHashes;
    // Both `outcomes` and `estimatedProbabilitiesBps` must be in the same order, as outcomes in the given market.
    string[] outcomes;
    uint16[] estimatedProbabilitiesBps; // Probabilities for each outcome, in basis points, should sum to 10000
}
