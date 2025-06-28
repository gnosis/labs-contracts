// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract MockERC20 {
    constructor(string memory, string memory) {}

    function approve(address, uint256) public virtual returns (bool) {
        return true;
    }
}
