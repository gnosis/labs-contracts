// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IConditionalTokens {
    function redeemPositions(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint256[] calldata indexSets
    ) external;
    function reportPayouts(bytes32 questionId, uint256[] calldata payouts) external;
    function balanceOf(address owner, uint256 id) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;
    function prepareCondition(address oracle, bytes32 questionId, uint256 outcomeSlotCount) external;
}
