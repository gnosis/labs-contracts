// SPDX-License-Identifier: UNLICENSED
pragma solidity ^ 0.8.13;

import "forge-std/Test.sol";
import {Safe} from "lib/safe-smart-account/contracts/Safe.sol";
import {ITransactionGuard, GuardManager} from "lib/safe-smart-account/contracts/base/GuardManager.sol";
import {SafeProxyFactory} from "lib/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {NoSingleSignedTransactionGuard} from "../../src/safe_guards/NoSingleSignedTransactionGuard.sol";
import {Enum} from "lib/safe-smart-account/contracts/libraries/Enum.sol";
import "lib/safe-tools/src/SafeTestTools.sol";

contract NoSingleSignedTransactionGuardTest is Test {
    using SafeTestLib for SafeInstance;

    address alice;
    address bob;
    address tobias;
    Safe masterCopy;
    SafeProxyFactory proxyFactory;
    Safe safe;
    NoSingleSignedTransactionGuard guard;
    uint256 constant threshold = 1;

    function setUp() public {
        SafeInstance memory safe = _setupSafe();

        // Create test accounts
        alice = vm.addr(1);
        bob = vm.addr(2);
        tobias = vm.addr(3);

        // Setup owners
        address[] memory owners = new address[](3);
        owners[0] = alice;
        owners[1] = bob;
        owners[2] = tobias;

        // Deploy guard
        guard = new NoSingleSignedTransactionGuard();

        // Set the guard in the safe
        bytes memory setGuardData = abi.encodeWithSelector(GuardManager.setGuard.selector, address(guard));
        safe.execTransaction({
            data: setGuardData
        })
    }

    // function testCannotExecuteWithSingleSignature() public {
    //     // Prepare transaction data
    //     bytes memory data = "";
    //     bytes memory signatures = _signTransaction(alice, address(safe), 0, data, 0);

    //     // Try to execute with only alice's signature
    //     vm.prank(alice);
    //     vm.expectRevert(NoSingleSignedTransactionGuard.SingleSignedTransactionNotAllowed.selector);
    //     safe.execTransaction(
    //         address(0), 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), signatures
    //     );
    // }

    // function testCanExecuteWithTwoSignatures() public {
    //     bytes memory data = "";
    //     bytes memory signatures = _signTransaction(alice, address(safe), 0, data, 0);
    //     signatures = bytes.concat(signatures, _signTransaction(bob, address(safe), 0, data, 0));

    //     // Should succeed with two signatures
    //     vm.prank(alice);
    //     safe.execTransaction(
    //         address(0), 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), signatures
    //     );
    // }

    // function testCanExecuteWithThreeSignatures() public {
    //     bytes memory data = "";
    //     bytes memory signatures = _signTransaction(alice, address(safe), 0, data, 0);
    //     signatures = bytes.concat(signatures, _signTransaction(bob, address(safe), 0, data, 0));
    //     signatures = bytes.concat(signatures, _signTransaction(tobias, address(safe), 0, data, 0));

    //     // Should succeed with three signatures
    //     vm.prank(alice);
    //     safe.execTransaction(
    //         address(0), 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), signatures
    //     );
    // }

    // Helper to sign a Safe transaction using EIP-712 and prank the signer
    function _signTransaction(address signer, address to, uint256 value, bytes memory data, uint8 operation)
        internal
        returns (bytes memory)
    {
        // Build the Safe transaction hash (EIP-712)
        uint256 _nonce = safe.nonce();

        bytes32 safeTxHash = safe.getTransactionHash(
            to,
            value,
            data,
            Enum.Operation(operation),
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(0), // gasToken
            address(0), // refundReceiver
            _nonce
        );

        // Prank as the signer and sign the hash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(uint160(signer)), safeTxHash);

        // Pack signature as expected by Safe: r (32) | s (32) | v (1)
        bytes memory signature = new bytes(65);
        assembly {
            mstore(add(signature, 32), r)
            mstore(add(signature, 64), s)
            mstore8(add(signature, 96), v)
        }

        return signature;
    }
}
