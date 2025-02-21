// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/Test.sol";
import {IAgentRegistry, AgentRegistry, AgentCommunication} from "../src/NFT/AgentCommunication.sol";
import "../src/NFT/DoubleEndedStructQueue.sol";

contract AgentCommunicationTest is Test {
    AgentRegistry agentReg;
    AgentCommunication agentComm;
    address owner = address(0x123);
    address agent = address(0x456);
    address payable treasury = payable(address(0x789));
    uint256 pctToTreasuryInBasisPoints = 7000;

    function buildMessage(bytes memory customMessage)
        public
        view
        returns (DoubleEndedStructQueue.MessageContainer memory)
    {
        return DoubleEndedStructQueue.MessageContainer({
            sender: agent,
            recipient: address(0x789),
            message: customMessage,
            value: 1000000000000000000
        });
    }

    function setUp() public {
        vm.startPrank(owner);
        agentReg = new AgentRegistry();
        agentComm = new AgentCommunication(IAgentRegistry(agentReg), treasury, pctToTreasuryInBasisPoints);
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

    function testRegisterAsAgent() public {
        vm.startPrank(agent);

        // Expect AgentRegistered event
        vm.expectEmit(true, true, true, true);
        emit IAgentRegistry.AgentRegistered(agent);

        agentReg.registerAsAgent();
        vm.stopPrank();

        assertTrue(agentReg.isRegisteredAgent(agent), "Agent should be registered");
    }

    function testDeregisterAsAgent() public {
        vm.startPrank(agent);
        agentReg.registerAsAgent();

        // Expect AgentDeregistered event
        vm.expectEmit(true, true, true, true);
        emit IAgentRegistry.AgentDeregistered(agent);

        agentReg.deregisterAsAgent();
        vm.stopPrank();

        assertFalse(agentReg.isRegisteredAgent(agent), "Agent should be deregistered");
    }

    function testDeregisterAsAgentWhenNotRegistered() public {
        vm.startPrank(agent);
        vm.expectRevert(IAgentRegistry.AgentNotRegistered.selector);
        agentReg.deregisterAsAgent();
        vm.stopPrank();
    }

    function testSendMessageToRegisteredAgent() public {
        DoubleEndedStructQueue.MessageContainer memory message = buildMessage("Hello!");
        vm.deal(owner, 1 ether);

        // Register the agent first
        vm.prank(agent);
        agentReg.registerAsAgent();

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

        vm.prank(agent);
        DoubleEndedStructQueue.MessageContainer memory storedMessage = agentComm.getAtIndex(0);
        assertEq(storedMessage.message, message.message);
    }

    function testSendMessageToUnregisteredAgent() public {
        DoubleEndedStructQueue.MessageContainer memory message = buildMessage("Hello!");
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        vm.expectRevert(IAgentRegistry.AgentNotRegistered.selector);
        agentComm.sendMessage{value: 10000000000000}(agent, message.message);
        vm.stopPrank();
    }

    function testSendMessageInsufficientValue() public {
        DoubleEndedStructQueue.MessageContainer memory message = buildMessage("Hello!");
        vm.deal(agent, 1 ether);
        vm.startPrank(agent);
        vm.expectRevert("Insufficient message value");
        agentComm.sendMessage{value: 5000}(agent, message.message);
        vm.stopPrank();
    }

    function testNewMessageSentEvent() public {
        DoubleEndedStructQueue.MessageContainer memory message = buildMessage("Hello!");
        vm.deal(agent, 1 ether);

        // Register the recipient
        vm.prank(message.recipient);
        agentReg.registerAsAgent();

        vm.startPrank(agent);

        // Expect the LogMessage event to be emitted
        vm.expectEmit(true, true, true, true);
        emit AgentCommunication.LogMessage(message.sender, message.recipient, message.message, message.value);

        // Send the message
        agentComm.sendMessage{value: message.value}(message.recipient, message.message);
        vm.stopPrank();
    }

    function testPopMessage() public {
        // Create a message containers
        DoubleEndedStructQueue.MessageContainer memory message_1 = buildMessage("Hello 1!");
        DoubleEndedStructQueue.MessageContainer memory message_2 = buildMessage("Hello 2!");
        DoubleEndedStructQueue.MessageContainer memory message_3 = buildMessage("Hello 3!");
        DoubleEndedStructQueue.MessageContainer memory message_4 = buildMessage("Hello 4!");
        DoubleEndedStructQueue.MessageContainer memory message_5 = buildMessage("Hello 5!");

        // Register the recipients
        vm.prank(message_1.recipient);
        agentReg.registerAsAgent();
        vm.prank(message_2.recipient);
        agentReg.registerAsAgent();
        vm.prank(message_3.recipient);
        agentReg.registerAsAgent();
        vm.prank(message_4.recipient);
        agentReg.registerAsAgent();
        vm.prank(message_5.recipient);
        agentReg.registerAsAgent();

        // Fund the agent and start the prank
        vm.deal(agent, 5 ether);
        vm.startPrank(agent);

        // Send the messages
        agentComm.sendMessage{value: message_1.value}(message_1.recipient, message_1.message);
        agentComm.sendMessage{value: message_2.value}(message_2.recipient, message_2.message);
        agentComm.sendMessage{value: message_3.value}(message_3.recipient, message_3.message);
        agentComm.sendMessage{value: message_4.value}(message_4.recipient, message_4.message);
        agentComm.sendMessage{value: message_5.value}(message_5.recipient, message_5.message);
        vm.stopPrank();

        // Start the prank again for popping the message
        vm.startPrank(message_1.recipient);

        // Expect the LogMessage event to be emitted when popping the message
        vm.expectEmit(true, true, true, true);
        emit AgentCommunication.LogMessage(message_1.sender, message_1.recipient, message_1.message, message_1.value);

        // Pop the next message
        DoubleEndedStructQueue.MessageContainer memory poppedMessage_1 = agentComm.popMessageAtIndex(0);
        vm.stopPrank();

        // Assert that the popped message matches the original message
        assertEq(poppedMessage_1.sender, message_1.sender);
        assertEq(poppedMessage_1.recipient, message_1.recipient);
        assertEq(poppedMessage_1.message, message_1.message);
        assertEq(poppedMessage_1.value, message_1.value);

        // Start the prank again for popping another message
        vm.prank(message_1.recipient);
        // Pop the message at specified index
        DoubleEndedStructQueue.MessageContainer memory poppedMessage_2 = agentComm.popMessageAtIndex(2);

        // Assert that the popped message matches the original message
        assertEq(poppedMessage_2.sender, message_4.sender);
        assertEq(poppedMessage_2.recipient, message_4.recipient);
        assertEq(poppedMessage_2.message, message_4.message);
        assertEq(poppedMessage_2.value, message_4.value);
    }

    function testCountMessages() public {
        // Initialize a message
        DoubleEndedStructQueue.MessageContainer memory message1 = buildMessage("Hello!");
        DoubleEndedStructQueue.MessageContainer memory message2 = buildMessage("Hello!");

        // Register agent
        vm.prank(agent);
        agentReg.registerAsAgent();

        // Fund the agent and start the prank
        vm.deal(agent, 1 ether);
        vm.startPrank(agent);

        // Send two messages
        agentComm.sendMessage{value: 10000000000000}(agent, message1.message);
        agentComm.sendMessage{value: 10000000000000}(agent, message2.message);

        // Check the count of messages
        uint256 messageCount = agentComm.countMessages();
        assertEq(messageCount, 2, "The message count should be 2");
    }

    function testSetTreasuryAddress() public {
        address payable newTreasury = payable(address(0xabc));
        vm.startPrank(owner);
        agentComm.setTreasuryAddress(newTreasury);
        vm.stopPrank();
        assertEq(address(agentComm.treasury()), address(newTreasury));
    }

    function testOnlyOwnerCanSetTreasuryAddress() public {
        address payable newTreasury = payable(address(0xabc));
        address nonOwner = address(0xdef);

        // Attempt to set treasury address from a non-owner address
        vm.startPrank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(nonOwner)));
        agentComm.setTreasuryAddress(newTreasury);
        vm.stopPrank();

        // Verify that the treasury address has not changed
        assertEq(address(agentComm.treasury()), address(treasury));
    }

    function testGetAllRegisteredAgents() public {
        // Initially there should be no registered agents
        address[] memory initialAgents = agentReg.getAllRegisteredAgents();
        assertEq(initialAgents.length, 0, "Should start with no registered agents");

        // Register first agent
        vm.prank(agent);
        agentReg.registerAsAgent();

        // Register second agent
        address agent2 = address(0xaaa);
        vm.prank(agent2);
        agentReg.registerAsAgent();

        // Get the list of registered agents
        address[] memory registeredAgents = agentReg.getAllRegisteredAgents();

        // Verify the list contains both agents
        assertEq(registeredAgents.length, 2, "Should have two registered agents");
        assertTrue(
            (registeredAgents[0] == agent && registeredAgents[1] == agent2)
                || (registeredAgents[0] == agent2 && registeredAgents[1] == agent),
            "List should contain both registered agents"
        );

        // Deregister one agent
        vm.prank(agent);
        agentReg.deregisterAsAgent();

        // Verify the list now only contains one agent
        address[] memory remainingAgents = agentReg.getAllRegisteredAgents();
        assertEq(remainingAgents.length, 1, "Should have one registered agent");
        assertEq(remainingAgents[0], agent2, "Should contain the remaining agent");
    }
}
