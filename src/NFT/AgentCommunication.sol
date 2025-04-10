// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./DoubleEndedStructQueue.sol";

interface IAgentRegistry {
    error AgentNotRegistered();

    event AgentRegistered(address indexed agent);
    event AgentDeregistered(address indexed agent);

    function registerAsAgent() external;
    function deregisterAsAgent() external;
    function isRegisteredAgent(address agent) external view returns (bool);
    function getAllRegisteredAgents() external view returns (address[] memory);
}

contract AgentRegistry is IAgentRegistry, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private registeredAgents;

    constructor() Ownable(msg.sender) {}

    modifier onlyRegisteredAgent() {
        if (!isRegisteredAgent(msg.sender)) {
            revert IAgentRegistry.AgentNotRegistered();
        }
        _;
    }

    function registerAsAgent() public {
        registeredAgents.add(msg.sender);
        emit IAgentRegistry.AgentRegistered(msg.sender);
    }

    function deregisterAsAgent() public onlyRegisteredAgent {
        registeredAgents.remove(msg.sender);
        emit IAgentRegistry.AgentDeregistered(msg.sender);
    }

    function isRegisteredAgent(address agent) public view returns (bool) {
        return registeredAgents.contains(agent);
    }

    function getAllRegisteredAgents() public view returns (address[] memory) {
        return registeredAgents.values();
    }
}

contract AgentCommunication is Ownable {
    IAgentRegistry public agentRegistry;
    address payable public treasury;
    uint256 public pctToTreasuryInBasisPoints; // 70% becomes 7000

    mapping(address => DoubleEndedStructQueue.Bytes32Deque) public queues;

    uint256 public minimumValueForSendingMessageInWei;

    event LogMessage(address indexed sender, address indexed agentAddress, bytes message, uint256 value);
    event MessagesPurged(address indexed agentAddress);
    event AllMessagesPurged();

    constructor(IAgentRegistry _agentRegistry, address payable _treasury, uint256 _pctToTreasuryInBasisPoints)
        Ownable(msg.sender)
    {
        agentRegistry = _agentRegistry;
        treasury = _treasury;
        pctToTreasuryInBasisPoints = _pctToTreasuryInBasisPoints;
        minimumValueForSendingMessageInWei = 10000000000000; // 0.00001 xDAI
    }

    modifier onlyRegisteredAgent() {
        if (!agentRegistry.isRegisteredAgent(msg.sender)) {
            revert IAgentRegistry.AgentNotRegistered();
        }
        _;
    }

    modifier mustPayMoreThanMinimum() {
        require(msg.value >= minimumValueForSendingMessageInWei, "Insufficient message value");
        _;
    }

    function setTreasuryAddress(address payable _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function adjustMinimumValueForSendingMessage(uint256 newValue) public onlyOwner {
        minimumValueForSendingMessageInWei = newValue;
    }

    function countMessages(address agentAddress) public view returns (uint256) {
        return DoubleEndedStructQueue.length(queues[agentAddress]);
    }

    // Private function to calculate the amounts
    function _calculateAmounts(uint256 totalValue) private view returns (uint256, uint256) {
        uint256 amountForTreasury = (totalValue * pctToTreasuryInBasisPoints) / 10000; // 10000 since basis points are used
        uint256 amountForAgent = totalValue - amountForTreasury;
        return (amountForTreasury, amountForAgent);
    }

    // We don't add `onlyRegisteredAgent` modifier here, because anyone should be able to send a message to an agent
    function sendMessage(address agentAddress, bytes memory message) public payable mustPayMoreThanMinimum {
        if (!agentRegistry.isRegisteredAgent(agentAddress)) {
            revert IAgentRegistry.AgentNotRegistered();
        }

        // Split message value between treasury and agent
        (uint256 amountForTreasury, uint256 amountForAgent) = _calculateAmounts(msg.value);

        // Transfer the amounts
        (bool sentTreasury,) = treasury.call{value: amountForTreasury}("");
        require(sentTreasury, "Failed to send Ether to treasury");
        (bool sentAgent,) = payable(agentAddress).call{value: amountForAgent}("");
        require(sentAgent, "Failed to send Ether to agent");

        DoubleEndedStructQueue.MessageContainer memory messageContainer =
            DoubleEndedStructQueue.MessageContainer(msg.sender, agentAddress, message, msg.value);
        DoubleEndedStructQueue.pushBack(queues[agentAddress], messageContainer);
        emit LogMessage(msg.sender, agentAddress, messageContainer.message, msg.value);
    }

    function getAtIndex(address agentAddress, uint256 idx)
        public
        view
        returns (DoubleEndedStructQueue.MessageContainer memory)
    {
        return DoubleEndedStructQueue.at(queues[agentAddress], idx);
    }

    function popMessageAtIndex(uint256 idx)
        public
        onlyRegisteredAgent
        returns (DoubleEndedStructQueue.MessageContainer memory)
    {
        DoubleEndedStructQueue.MessageContainer memory message = DoubleEndedStructQueue.popAt(queues[msg.sender], idx);
        emit LogMessage(message.sender, msg.sender, message.message, message.value);
        return message;
    }

    function purgeMessages(address agentAddress) public onlyOwner {
        delete queues[agentAddress];
        emit MessagesPurged(agentAddress);
    }

    function purgeAllMessages() public onlyOwner {
        address[] memory agents = agentRegistry.getAllRegisteredAgents();
        for (uint256 i = 0; i < agents.length; i++) {
            purgeMessages(agents[i]);
        }
        emit AllMessagesPurged();
    }
}
