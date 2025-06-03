// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Safe} from "safe-contracts/Safe.sol";
import {GuardManager} from "safe-contracts/base/GuardManager.sol";
import {SafeProxyFactory} from "safe-contracts/proxies/SafeProxyFactory.sol";
import {NoExecuteByAgentGuard} from "../../src/safe_guards/NoExecuteByAgentGuard.sol";
import {Enum} from "safe-contracts/common/Enum.sol";
import {SafeTestLib, SafeTestTools, SafeInstance} from "safe-tools/SafeTestTools.sol";
import {getAddr, VM_ADDR} from "safe-tools/Utils.sol";
import {createSignatures} from "../Utils.sol";

contract NoExecuteByAgentGuardTest is Test, SafeTestTools {
    using SafeTestLib for SafeInstance;

    address alice;
    address agent;
    SafeInstance safeInstance;
    NoExecuteByAgentGuard guard;
    uint256 constant threshold = 1;

    function setUp() public {
        uint256[] memory ownerPKs = new uint256[](2);
        ownerPKs[0] = 0x1;
        ownerPKs[1] = 0x2;
        safeInstance = _setupSafe(ownerPKs, threshold);

        // Save one of the owners as alice, another as agent
        alice = getAddr(ownerPKs[0]);
        agent = getAddr(ownerPKs[1]);

        // Deploy guard with agent address
        guard = new NoExecuteByAgentGuard(agent);

        // Set the guard in the safe
        bytes memory setGuardData = abi.encodeWithSelector(GuardManager.setGuard.selector, address(guard));
        safeInstance.execTransaction({to: address(safeInstance.safe), value: 0, data: setGuardData});
    }

    function testAgentCannotExecuteTransaction() public {
        // Agent signs and tries to execute
        uint256[] memory signerIdxs = new uint256[](1);
        signerIdxs[0] = 1;
        bytes memory signatures = createSignatures(
            signerIdxs, safeInstance, agent, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), address(0)
        );
        vm.expectRevert(NoExecuteByAgentGuard.ExecutionByAgentNotAllowed.selector);
        vm.prank(agent);
        safeInstance.safe.execTransaction(
            agent, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), signatures
        );
        assertEq(agent.balance, 0);
    }

    function testNonAgentCanExecuteTransaction() public {
        // Alice signs and executes
        uint256[] memory signerIdxs = new uint256[](1);
        signerIdxs[0] = 0;
        bytes memory signatures = createSignatures(
            signerIdxs, safeInstance, alice, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), address(0)
        );
        vm.prank(alice);
        SafeTestLib.execTransaction(
            safeInstance, alice, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), address(0), signatures
        );
        assertEq(alice.balance, 0.5 ether);
    }

    function testAgentCanSignButNotExecute() public {
        // Agent sign, but alice executes
        uint256[] memory signerIdxs = new uint256[](1);
        signerIdxs[0] = 1;
        bytes memory signatures = createSignatures(
            signerIdxs, safeInstance, alice, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), address(0)
        );
        vm.prank(alice);
        SafeTestLib.execTransaction(
            safeInstance, alice, 0.5 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), address(0), signatures
        );
        assertEq(alice.balance, 0.5 ether);
    }
}
