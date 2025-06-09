// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {SafeInstance} from "safe-tools/SafeTestTools.sol";
import {Enum} from "safe-contracts/common/Enum.sol";
import {getAddr, VM_ADDR} from "safe-tools/Utils.sol";

function createSignatures(
    uint256[] memory signerIdxs,
    SafeInstance memory safe,
    address to,
    uint256 value,
    bytes memory data,
    Enum.Operation operation,
    uint256 safeTxGas,
    uint256 baseGas,
    uint256 gasPrice,
    address gasToken,
    address refundReceiver
) view returns (bytes memory) {
    bytes32 safeTxHash =
        _getTransactionHash(safe, to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver);
    return _generateSignatures(signerIdxs, safe, safeTxHash);
}

function _getTransactionHash(
    SafeInstance memory safe,
    address to,
    uint256 value,
    bytes memory data,
    Enum.Operation operation,
    uint256 safeTxGas,
    uint256 baseGas,
    uint256 gasPrice,
    address gasToken,
    address refundReceiver
) view returns (bytes32) {
    uint256 _nonce = safe.safe.nonce();
    return safe.safe.getTransactionHash({
        to: to,
        value: value,
        data: data,
        operation: operation,
        safeTxGas: safeTxGas,
        baseGas: baseGas,
        gasPrice: gasPrice,
        gasToken: gasToken,
        refundReceiver: refundReceiver,
        _nonce: _nonce
    });
}

function _generateSignatures(uint256[] memory signerIdxs, SafeInstance memory safe, bytes32 safeTxHash)
    pure
    returns (bytes memory)
{
    bytes memory signatures = "";
    for (uint256 i = 0; i < signerIdxs.length; ++i) {
        uint256 signerIdx = signerIdxs[i];
        uint256 pk = safe.ownerPKs[signerIdx];
        (uint8 v, bytes32 r, bytes32 s) = Vm(VM_ADDR).sign(pk, safeTxHash);
        signatures = bytes.concat(signatures, abi.encodePacked(r, s, v));
    }
    return signatures;
}
