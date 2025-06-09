// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.0;

import {BaseGuard} from "safe-contracts/base/GuardManager.sol";
import {Enum} from "safe-contracts/common/Enum.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title AgentSignatureMandatoryGuard
 * @notice Add this guard along with addition of the agent as a co-signer, to have him as a mandatory signer of your transactions. Warning: This can lock you out of your Safe, if anything goes wrong with your Safe Watch agent.
 */
contract AgentSignatureMandatoryGuard is BaseGuard {
    error AgentSignatureNeeded();

    address public immutable agent;

    constructor(address _agent) {
        agent = _agent;
    }

    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address /*msgSender*/
    ) external view {
        address safe = msg.sender;
        bytes32 safeTxHash =
            _getSafeTxHash(safe, to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver);
        if (!_hasAgentSignature(signatures, safeTxHash)) {
            revert AgentSignatureNeeded();
        }
    }

    function _getSafeTxHash(
        address safe,
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver
    ) internal view returns (bytes32) {
        // Without -1, the recovered address in `_hasAgentSignature` is different and tests don't pass.
        // The theory is that at this point, nonce in the Safe is already incremented, and we need to retrieve nonce that was used for this transaction.
        uint256 nonce = _getSafeNonce(safe) - 1;
        (bool ok, bytes memory result) = safe.staticcall(
            abi.encodeWithSignature(
                "getTransactionHash(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,uint256)",
                to,
                value,
                data,
                uint8(operation),
                safeTxGas,
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver,
                nonce
            )
        );
        require(ok && result.length == 32, "AgentSignatureMandatoryGuard: failed to get SafeTxHash");
        return abi.decode(result, (bytes32));
    }

    function _hasAgentSignature(bytes memory signatures, bytes32 safeTxHash) internal view returns (bool) {
        uint256 signaturesCount = signatures.length / 65;
        for (uint256 i = 0; i < signaturesCount; i++) {
            bytes memory sig = new bytes(65);
            for (uint256 j = 0; j < 65; j++) {
                sig[j] = signatures[i * 65 + j];
            }
            address signer = ECDSA.recover(safeTxHash, sig);
            if (signer == agent) {
                return true;
            }
        }
        return false;
    }

    function _domainSeparator(address safe) internal view returns (bytes32 separator) {
        (bool ok, bytes memory result) = safe.staticcall(abi.encodeWithSignature("domainSeparator()"));
        require(ok && result.length == 32, "AgentSignatureMandatoryGuard: failed to get domainSeparator");
        separator = abi.decode(result, (bytes32));
    }

    function _getSafeNonce(address safe) internal view returns (uint256 nonce) {
        (bool ok, bytes memory result) = safe.staticcall(abi.encodeWithSignature("nonce()"));
        require(ok && result.length == 32, "AgentSignatureMandatoryGuard: failed to get nonce");
        nonce = abi.decode(result, (uint256));
    }

    function checkAfterExecution(bytes32, bool) external pure {}
}
