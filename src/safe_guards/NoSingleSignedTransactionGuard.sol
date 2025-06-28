// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.0;

import {BaseGuard} from "safe-contracts/base/GuardManager.sol";
import {Enum} from "safe-contracts/common/Enum.sol";
import "forge-std/console.sol";

/**
 * @title NoSingleSignedTransactionGuard
 * @notice Guard that prevents execution of transactions with only a single signature.
 */
contract NoSingleSignedTransactionGuard is BaseGuard {
    error SingleSignedTransactionNotAllowed();

    constructor() {}

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
        bytes memory signatures,
        address /*msgSender*/
    ) external pure {
        uint256 numberOfSignatures = signatures.length / 65;
        if (numberOfSignatures < 2) {
            revert SingleSignedTransactionNotAllowed();
        }
    }

    function checkAfterExecution(bytes32, bool) external pure {}
}
