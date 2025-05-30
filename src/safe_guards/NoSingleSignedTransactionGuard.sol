// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.0;

import {BaseGuard} from "safe-contracts/base/GuardManager.sol";
import {Enum} from "safe-contracts/common/Enum.sol";
import "forge-std/console.sol";

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
        // ToDo - check if agent's signature is involved, if only humans, always allow
        console.log("signatures.length", signatures.length);
        uint256 numberOfSignatures = signatures.length / 65;
        console.log("numberOfSignatures", numberOfSignatures);
        if (numberOfSignatures < 2) {
            console.log("entered revert");
            revert SingleSignedTransactionNotAllowed();
        }
    }

    function dummyReverter() external pure {
        revert SingleSignedTransactionNotAllowed();
    }

    function checkAfterExecution(bytes32 txHash, bool success) external pure {}
}
