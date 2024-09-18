// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

struct Prediction {
    address publisherAddress;
    bytes32 ipfsHash;
    bytes32 txHash;
}