// SPDX-License-Identifier: UNLICENSED
pragma solidity ^ 0.8.13;

import "forge-std/Test.sol";
import {Safe} from "safe-contracts/Safe.sol";
import {GuardManager} from "safe-contracts/base/GuardManager.sol";
import {SafeProxyFactory} from "safe-contracts/proxies/SafeProxyFactory.sol";
import {NoSingleSignedTransactionGuard} from "../../src/safe_guards/NoSingleSignedTransactionGuard.sol";
import {Enum} from "safe-contracts/common/Enum.sol";
import {SafeTestLib, SafeTestTools, SafeInstance} from "safe-tools/SafeTestTools.sol";
import {getAddr, VM_ADDR} from "safe-tools/Utils.sol";

contract NoSingleSignedTransactionGuardTest is Test, SafeTestTools {
    using SafeTestLib for SafeInstance;

    address alice;
    SafeInstance safeInstance;
    NoSingleSignedTransactionGuard guard;
    uint256 constant threshold = 1;

    function setUp() public {
        uint256[] memory ownerPKs = new uint256[](3);
        ownerPKs[0] = 0x1;
        ownerPKs[1] = 0x2;
        ownerPKs[2] = 0x3;
        safeInstance = _setupSafe(ownerPKs, threshold);

        // Save one of the owners
        alice = getAddr(ownerPKs[0]);

        // Deploy guard
        guard = new NoSingleSignedTransactionGuard();

        // Set the guard in the safe
        bytes memory setGuardData = abi.encodeWithSelector(GuardManager.setGuard.selector, address(guard));
        safeInstance.execTransaction({to: address(safeInstance.safe), value: 0, data: setGuardData});
    }

    function testCannotExecuteWithSingleSignature() public {
        bytes memory signatures = _createSignatures(
            1, safeInstance, alice, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), address(0)
        );
        vm.expectRevert(NoSingleSignedTransactionGuard.SingleSignedTransactionNotAllowed.selector);
        SafeTestLib.execTransaction(
            safeInstance, alice, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), address(0), signatures
        );
    }

    function testCanExecuteWithTwoSignatures() public {
        bytes memory signatures = _createSignatures(
            2, safeInstance, alice, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), address(0)
        );
        SafeTestLib.execTransaction(
            safeInstance, alice, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), address(0), signatures
        );
        assertEq(alice.balance, 0.5 ether);
    }

    function testCanExecuteWithThreeSignatures() public {
        bytes memory signatures = _createSignatures(
            3, safeInstance, alice, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), address(0)
        );
        SafeTestLib.execTransaction(
            safeInstance, alice, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), address(0), signatures
        );
        assertEq(alice.balance, 0.5 ether);
    }

    function _createSignatures(
        uint256 n,
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
    ) internal returns (bytes memory) {
        bytes memory signatures = "";
        bytes32 safeTxHash;

        uint256 _nonce = safe.safe.nonce();
        safeTxHash = safe.safe.getTransactionHash({
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

        for (uint256 i; i < n; ++i) {
            uint256 pk = safe.ownerPKs[i];
            (uint8 v, bytes32 r, bytes32 s) = Vm(VM_ADDR).sign(pk, safeTxHash);
            signatures = bytes.concat(signatures, abi.encodePacked(r, s, v));
        }

        return signatures;
    }
}
