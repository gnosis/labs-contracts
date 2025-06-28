// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockConditionalTokens {
    mapping(uint256 => mapping(address => uint256)) public balances;

    function redeemPositions(IERC20, bytes32, bytes32, uint256[] memory) external pure {}

    function balanceOf(address user, uint256 id) public view virtual returns (uint256 result) {
        return balances[id][user];
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory) external {
        // We bypass the transfer logic for simplicity
        balances[id][from] -= amount;
        balances[id][to] += amount;
    }

    function mint(address user, uint256 id, uint256 amount) public {
        balances[id][user] += amount;
    }
}
