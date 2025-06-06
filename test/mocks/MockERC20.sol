// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract MockERC20 {
    constructor(string memory name, string memory symbol) {}

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        return true;
    }
}
