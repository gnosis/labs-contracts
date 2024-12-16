// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/Test.sol";
import {AgentCommunication} from "../src/NFT/AgentCommunication.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AgentCommunicationTest is Test {
    AgentCommunication agentComm;
    address owner = address(0x123);
    address agent = address(0x456);

    function setUp() public {
        vm.startPrank(owner);
        agentComm = new AgentCommunication();
        vm.stopPrank();
    }

    function testInitialMinimumValue() public {
        uint256 expectedValue = 10000000000000; // 0.00001 xDAI
        assertEq(agentComm.minimumValueForSendingMessageInWei(), expectedValue);
    }

    function testAdjustMinimumValue() public {
        uint256 newValue = 20000000000000; // 0.00002 xDAI
        vm.startPrank(owner);
        agentComm.adjustMinimumValueForSendingMessage(newValue);
        vm.stopPrank();
        assertEq(agentComm.minimumValueForSendingMessageInWei(), newValue);
    }

    function testOnlyOwnerCanAdjustMinimumValue() public {
        uint256 newValue = 20000000000000; // 0.00002 xDAI
        address nonOwner = address(0x789);

        // Attempt to adjust the minimum value from a non-owner address
        vm.startPrank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(nonOwner)));
        agentComm.adjustMinimumValueForSendingMessage(newValue);
        vm.stopPrank();

        // Verify that the value has not changed
        assertEq(agentComm.minimumValueForSendingMessageInWei(), 10000000000000);
    }

    function testSendMessage() public {
        bytes32 message = "Hello, Agent!";
        vm.deal(agent, 1 ether);
        vm.startPrank(agent);
        agentComm.sendMessage{value: 10000000000000}(agent, message);
        vm.stopPrank();

        bytes32 storedMessage = agentComm.getAtIndex(agent, 0);
        assertEq(storedMessage, message);
    }

    function testSendMessageInsufficientValue() public {
        bytes32 message = "Hello, Agent!";
        vm.deal(agent, 1 ether);
        vm.startPrank(agent);
        vm.expectRevert("Insufficient message value");
        agentComm.sendMessage{value: 5000}(agent, message);
        vm.stopPrank();
    }

    function testPopNextMessage() public {
        bytes32 message = "Hello, Agent!";
        vm.deal(agent, 1 ether);
        vm.startPrank(agent);
        agentComm.sendMessage{value: 10000000000000}(agent, message);
        vm.stopPrank();

        vm.startPrank(agent);
        bytes32 poppedMessage = agentComm.popNextMessage(agent);
        vm.stopPrank();

        assertEq(poppedMessage, message);
    }

    function testPopNextMessageNotByAgent() public {
        bytes32 message = "Hello, Agent!";
        vm.deal(agent, 1 ether);
        vm.startPrank(agent);
        agentComm.sendMessage{value: 10000000000000}(agent, message);
        vm.stopPrank();

        address notAgent = address(0x789);
        vm.startPrank(notAgent);
        vm.expectRevert(AgentCommunication.MessageNotSentByAgent.selector);
        agentComm.popNextMessage(agent);
        vm.stopPrank();
    }
}
