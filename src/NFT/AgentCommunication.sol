// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
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
    mapping(address => bool) public registeredAgents;
    address[] private registeredAgentsList;

    constructor() Ownable(msg.sender) {}

    modifier onlyRegisteredAgent() {
        if (!registeredAgents[msg.sender]) {
            revert AgentNotRegistered();
        }
        _;
    }

    function registerAsAgent() public {
        registeredAgents[msg.sender] = true;
        registeredAgentsList.push(msg.sender);
        emit AgentRegistered(msg.sender);
    }

    function deregisterAsAgent() public onlyRegisteredAgent {
        registeredAgents[msg.sender] = false;
        // Remove from list
        for (uint256 i = 0; i < registeredAgentsList.length; i++) {
            if (registeredAgentsList[i] == msg.sender) {
                registeredAgentsList[i] = registeredAgentsList[registeredAgentsList.length - 1];
                registeredAgentsList.pop();
                break;
            }
        }
        emit AgentDeregistered(msg.sender);
    }

    function isRegisteredAgent(address agent) public view returns (bool) {
        return registeredAgents[agent];
    }

    function getAllRegisteredAgents() public view returns (address[] memory) {
        return registeredAgentsList;
    }
}

contract AgentCommunication is AgentRegistry {
    address payable public treasury;
    uint256 public pctToTreasuryInBasisPoints; // 70% becomes 7000

    mapping(address => DoubleEndedStructQueue.Bytes32Deque) public queues;

    uint256 public minimumValueForSendingMessageInWei;

    event LogMessage(address indexed sender, address indexed agentAddress, bytes message, uint256 value);

    constructor(address payable _treasury, uint256 _pctToTreasuryInBasisPoints) {
        treasury = _treasury;
        pctToTreasuryInBasisPoints = _pctToTreasuryInBasisPoints;
        minimumValueForSendingMessageInWei = 10000000000000; // 0.00001 xDAI
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

    function sendMessage(address agentAddress, bytes memory message) public payable mustPayMoreThanMinimum {
        if (!isRegisteredAgent(agentAddress)) {
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

    function popMessageAtIndex(uint256 idx) public returns (DoubleEndedStructQueue.MessageContainer memory) {
        if (!isRegisteredAgent(msg.sender)) {
            revert IAgentRegistry.AgentNotRegistered();
        }
        DoubleEndedStructQueue.MessageContainer memory message = DoubleEndedStructQueue.popAt(queues[msg.sender], idx);
        emit LogMessage(message.sender, msg.sender, message.message, message.value);
        return message;
    }
}
