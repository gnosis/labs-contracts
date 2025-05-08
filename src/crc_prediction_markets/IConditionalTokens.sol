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
    function prepareCondition(address oracle, bytes32 questionId, uint256 outcomeSlotCount) external;
}
