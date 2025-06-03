// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Safe} from "safe-contracts/Safe.sol";
import {GuardManager} from "safe-contracts/base/GuardManager.sol";
import {SafeProxyFactory} from "safe-contracts/proxies/SafeProxyFactory.sol";
import {NoSingleSignedTransactionGuard} from "../../src/safe_guards/NoSingleSignedTransactionGuard.sol";
import {Enum} from "safe-contracts/common/Enum.sol";
import {SafeTestLib, SafeTestTools, SafeInstance} from "safe-tools/SafeTestTools.sol";
import {getAddr, VM_ADDR} from "safe-tools/Utils.sol";
import {createSignatures} from "../Utils.sol";

contract NoSingleSignedTransactionGuardTest is Test, SafeTestTools {
    using SafeTestLib for SafeInstance;

    address alice;
    SafeInstance safeInstance;
    NoSingleSignedTransactionGuard guard;
    uint256 constant threshold = 1;

    function setUp() public {
        uint256[] memory ownerPKs = new uint256[](3);
        // Write them in DESC order, because setupSafe will sort them anyways, and then you can not rely on indexing them.
        ownerPKs[0] = 0x3;
        ownerPKs[1] = 0x2;
        ownerPKs[2] = 0x1;
        safeInstance = _setupSafe(ownerPKs, threshold);

        // Save one of the owners
        alice = getAddr(ownerPKs[0]);

        // Deploy guard
        guard = new NoSingleSignedTransactionGuard();

        // Set the guard in the safe
        bytes memory setGuardData = abi.encodeWithSelector(GuardManager.setGuard.selector, address(guard));
        safeInstance.execTransaction({to: address(safeInstance.safe), value: 0, data: setGuardData});
    }

    function testCanNotExecuteWithOnlyOneSignature() public {
        uint256[] memory signerIdxs = new uint256[](1);
        signerIdxs[0] = 0;
        bytes memory signatures = createSignatures(
            signerIdxs, safeInstance, alice, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), address(0)
        );
        vm.expectRevert(NoSingleSignedTransactionGuard.SingleSignedTransactionNotAllowed.selector);
        safeInstance.safe.execTransaction(
            alice, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), signatures
        );
        assertEq(alice.balance, 0);
    }

    function testCanExecuteWithTwoSignatures() public {
        uint256[] memory signerIdxs = new uint256[](2);
        signerIdxs[0] = 0;
        signerIdxs[1] = 1;
        bytes memory signatures = createSignatures(
            signerIdxs, safeInstance, alice, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), address(0)
        );
        SafeTestLib.execTransaction(
            safeInstance, alice, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), address(0), signatures
        );
        assertEq(alice.balance, 0.5 ether);
    }

    function testCanExecuteWithThreeSignatures() public {
        uint256[] memory signerIdxs = new uint256[](3);
        signerIdxs[0] = 0;
        signerIdxs[1] = 1;
        signerIdxs[2] = 2;
        bytes memory signatures = createSignatures(
            signerIdxs, safeInstance, alice, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), address(0)
        );
        SafeTestLib.execTransaction(
            safeInstance, alice, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), address(0), signatures
        );
        assertEq(alice.balance, 0.5 ether);
    }
}
