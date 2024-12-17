// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

//import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/Test.sol";
import {AgentCommunication} from "../src/NFT/AgentCommunication.sol";
import "../src/NFT/DoubleEndedStructQueue.sol";

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
        DoubleEndedStructQueue.MessageContainer memory message = DoubleEndedStructQueue.MessageContainer({
            sender: agent, // or any appropriate address
            recipient: address(0x789), // or any appropriate address
            message: "Hello, Agent!" // Ensure this is a bytes32 type
        });
        vm.deal(agent, 1 ether);
        vm.startPrank(agent);
        agentComm.sendMessage{value: 10000000000000}(agent, message);
        vm.stopPrank();

        DoubleEndedStructQueue.MessageContainer memory storedMessage = agentComm.getAtIndex(agent, 0);
        assertEq(storedMessage.message, message.message);
    }

    function testSendMessageInsufficientValue() public {
        DoubleEndedStructQueue.MessageContainer memory message = DoubleEndedStructQueue.MessageContainer({
            sender: agent,
            recipient: address(0x789), // or any appropriate address
            message: bytes32("Hello, Agent!") // Ensure this is a bytes32 type
        });
        vm.deal(agent, 1 ether);
        vm.startPrank(agent);
        vm.expectRevert("Insufficient message value");
        agentComm.sendMessage{value: 5000}(agent, message);
        vm.stopPrank();
    }

    function testNewMessageSentEvent() public {
        address recipient = address(0x789);
        DoubleEndedStructQueue.MessageContainer memory message = DoubleEndedStructQueue.MessageContainer({
            sender: agent,
            recipient: recipient,
            message: bytes32("Hello, Agent!") // Ensure this is a bytes32 type
        });
        vm.deal(agent, 1 ether);
        vm.startPrank(agent);

        // Expect the NewMessageSent event to be emitted
        vm.expectEmit(true, true, false, true);
        emit AgentCommunication.NewMessageSent(agent, message.recipient, message.message);

        // Send the message
        agentComm.sendMessage{value: 0.2 ether}(recipient, message);
        vm.stopPrank();
    }

    function testPopNextMessage() public {
        DoubleEndedStructQueue.MessageContainer memory message = DoubleEndedStructQueue.MessageContainer({
            sender: agent,
            recipient: address(0x789), // or any appropriate address
            message: bytes32("Hello, Agent!") // Ensure this is a bytes32 type
        });
        vm.deal(agent, 1 ether);
        vm.startPrank(agent);
        agentComm.sendMessage{value: 10000000000000}(agent, message);
        vm.stopPrank();

        // Expect the MessagePopped event to be emitted
        vm.expectEmit(true, true, false, true);
        emit AgentCommunication.MessagePopped(agent, message.message);
        vm.startPrank(agent);
        DoubleEndedStructQueue.MessageContainer memory poppedMessage = agentComm.popNextMessage(agent);
        vm.stopPrank();

        assertEq(poppedMessage.message, message.message);
        uint256 numMessages = agentComm.countMessages(agent);
        assertEq(numMessages, 0);
    }

    // ToDo - reset name
    function testPopNextMessageNotByAgent() public {
        DoubleEndedStructQueue.MessageContainer memory message = DoubleEndedStructQueue.MessageContainer({
            sender: agent,
            recipient: address(0x789), // or any appropriate address
            message: bytes32("Hello, Agent!") // Ensure this is a bytes32 type
        });
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

    function testCountMessages() public {
        // Initialize a message
        DoubleEndedStructQueue.MessageContainer memory message1 = DoubleEndedStructQueue.MessageContainer({
            sender: agent,
            recipient: address(0x789),
            message: bytes32("Hello, Agent 1!") // Ensure this is a bytes32 type
        });

        DoubleEndedStructQueue.MessageContainer memory message2 = DoubleEndedStructQueue.MessageContainer({
            sender: agent,
            recipient: address(0x789),
            message: bytes32("Hello, Agent 2!") // Ensure this is a bytes32 type
        });

        // Fund the agent and start the prank
        vm.deal(agent, 1 ether);
        vm.startPrank(agent);

        // Send two messages
        agentComm.sendMessage{value: 10000000000000}(agent, message1);
        agentComm.sendMessage{value: 10000000000000}(agent, message2);

        // Stop the prank
        vm.stopPrank();

        // Check the count of messages
        uint256 messageCount = agentComm.countMessages(agent);
        assertEq(messageCount, 2, "The message count should be 2");
    }
}
