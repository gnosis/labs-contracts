// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.0;

import {BaseTransactionGuard} from "lib/safe-smart-account/contracts/base/GuardManager.sol";
import {Enum} from "lib/safe-smart-account/contracts/libraries/Enum.sol";

contract NoSingleSignedTransactionGuard is BaseTransactionGuard {
    error SingleSignedTransactionNotAllowed();

    constructor() {}

    // solhint-disable-next-line payable-fallback
    fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
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
        bytes memory signatures,
        address /*msgSender*/
    ) external pure {
        uint256 numberOfSignatures = signatures.length / 65;

        if (numberOfSignatures < 2) {
            revert SingleSignedTransactionNotAllowed();
        }
    }

    function checkAfterExecution(bytes32 txHash, bool success) external pure {}
}
