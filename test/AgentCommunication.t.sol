// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/Test.sol";
import {AgentCommunication} from "../src/NFT/AgentCommunication.sol";
import "../src/NFT/DoubleEndedStructQueue.sol";

contract AgentCommunicationTest is Test {
    AgentCommunication agentComm;
    address owner = address(0x123);
    address agent = address(0x456);
    address payable treasury = payable(address(0x789));
    uint256 pctToTreasuryInBasisPoints = 7000;

    function buildMessage() public view returns (DoubleEndedStructQueue.MessageContainer memory) {
        return DoubleEndedStructQueue.MessageContainer({
            sender: agent,
            recipient: address(0x789),
            message: "Hello, Agent!",
            value: 1000000000000000000
        });
    }

    function setUp() public {
        vm.startPrank(owner);
        agentComm = new AgentCommunication(treasury, pctToTreasuryInBasisPoints);
        vm.stopPrank();
    }

    function testInitialMinimumValue() public view {
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
        DoubleEndedStructQueue.MessageContainer memory message = buildMessage();
        vm.deal(owner, 1 ether);

        // Record initial balances
        uint256 initialBalanceTreasury = treasury.balance;
        uint256 initialBalanceAgent = agent.balance;

        assertEq(address(agentComm).balance, 0);

        vm.startPrank(owner);
        uint256 messageValue = 10000000000000;
        agentComm.sendMessage{value: messageValue}(agent, message.message);
        vm.stopPrank();

        // Assert treasuries increased correctly
        uint256 diffBalanceTreasury = treasury.balance - initialBalanceTreasury;
        uint256 diffBalanceAgent = agent.balance - initialBalanceAgent;
        assertEq(messageValue * pctToTreasuryInBasisPoints / 10000, diffBalanceTreasury);
        assertEq(messageValue * (10000 - pctToTreasuryInBasisPoints) / 10000, diffBalanceAgent);
        assertEq(address(agentComm).balance, 0);

        DoubleEndedStructQueue.MessageContainer memory storedMessage = agentComm.getAtIndex(agent, 0);
        assertEq(storedMessage.message, message.message);
    }

    function testSendMessageInsufficientValue() public {
        DoubleEndedStructQueue.MessageContainer memory message = buildMessage();
        vm.deal(agent, 1 ether);
        vm.startPrank(agent);
        vm.expectRevert("Insufficient message value");
        agentComm.sendMessage{value: 5000}(agent, message.message);
        vm.stopPrank();
    }

    function testNewMessageSentEvent() public {
        DoubleEndedStructQueue.MessageContainer memory message = buildMessage();
        vm.deal(agent, 1 ether);
        vm.startPrank(agent);

        // Expect the LogMessage event to be emitted
        vm.expectEmit(true, true, true, true);
        emit AgentCommunication.LogMessage(message.sender, message.recipient, message.message, message.value);

        // Send the message
        agentComm.sendMessage{value: message.value}(address(0x789), message.message);
        vm.stopPrank();
    }

    function testPopNextMessage() public {
        // Create a message container
        DoubleEndedStructQueue.MessageContainer memory message = buildMessage();

        // Fund the agent and start the prank
        vm.deal(agent, 1 ether);
        vm.startPrank(agent);

        // Send the message
        agentComm.sendMessage{value: message.value}(message.recipient, message.message);
        vm.stopPrank();

        // Start the prank again for popping the message
        vm.startPrank(message.recipient);

        // Expect the LogMessage event to be emitted when popping the message
        vm.expectEmit(true, true, true, true);
        emit AgentCommunication.LogMessage(message.sender, message.recipient, message.message, message.value);

        // Pop the next message
        DoubleEndedStructQueue.MessageContainer memory poppedMessage = agentComm.popNextMessage(message.recipient);
        vm.stopPrank();

        // Assert that the popped message matches the original message
        assertEq(poppedMessage.sender, message.sender);
        assertEq(poppedMessage.recipient, message.recipient);
        assertEq(poppedMessage.message, message.message);
        assertEq(poppedMessage.value, message.value);
    }

    function testPopNextMessageNotByAgent() public {
        DoubleEndedStructQueue.MessageContainer memory message = buildMessage();
        vm.deal(agent, 1 ether);
        vm.startPrank(agent);
        agentComm.sendMessage{value: 10000000000000}(agent, message.message);
        vm.stopPrank();

        address notAgent = address(0x789);
        vm.startPrank(notAgent);
        vm.expectRevert(AgentCommunication.MessageNotSentByAgent.selector);
        agentComm.popNextMessage(agent);
        vm.stopPrank();
    }

    function testCountMessages() public {
        // Initialize a message
        DoubleEndedStructQueue.MessageContainer memory message1 = buildMessage();

        DoubleEndedStructQueue.MessageContainer memory message2 = buildMessage();

        // Fund the agent and start the prank
        vm.deal(agent, 1 ether);
        vm.startPrank(agent);

        // Send two messages
        agentComm.sendMessage{value: 10000000000000}(agent, message1.message);
        agentComm.sendMessage{value: 10000000000000}(agent, message2.message);

        // Stop the prank
        vm.stopPrank();

        // Check the count of messages
        uint256 messageCount = agentComm.countMessages(agent);
        assertEq(messageCount, 2, "The message count should be 2");
    }
}
