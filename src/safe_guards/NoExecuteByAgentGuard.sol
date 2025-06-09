// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.0;

import {BaseGuard} from "safe-contracts/base/GuardManager.sol";
import {Enum} from "safe-contracts/common/Enum.sol";
import "forge-std/console.sol";

/**
 * @title NoExecuteByAgentGuard
 * @notice Add this guard along with addition of the agent as a co-signer, to prevent him from executing transactions on the contract level, no matter if threshold is met or not.
 */
contract NoExecuteByAgentGuard is BaseGuard {
    error ExecutionByAgentNotAllowed();

    address public immutable agent;

    constructor(address _agent) {
        agent = _agent;
    }

    function checkTransaction(
        address, /*to*/
        uint256, /*value*/
        bytes memory, /*data*/
        Enum.Operation, /*operation*/
        uint256, /*safeTxGas*/
        uint256, /*baseGas*/
        uint256, /*gasPrice*/
        address, /*gasToken*/
        address payable, /*refundReceiver*/
        bytes memory, /*signatures*/
        address msgSender
    ) external view {
        if (msgSender == agent) {
            revert ExecutionByAgentNotAllowed();
        }
    }

    function checkAfterExecution(bytes32, bool) external pure {}
}
