// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockConditionalTokens {
    function redeemPositions(IERC20, bytes32, bytes32, uint256[] memory) external pure {
        // Mock implementation
    }

    function balanceOf(address owner, uint256 id) public view virtual returns (uint256 result) {
        return 0;
    }
}
