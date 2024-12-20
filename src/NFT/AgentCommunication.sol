// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./DoubleEndedStructQueue.sol";

contract AgentCommunication is Ownable {
    error MessageNotSentByAgent();

    mapping(address => DoubleEndedStructQueue.Bytes32Deque) public queues;
    uint256 public minimumValueForSendingMessageInWei;

    event LogMessage(address indexed sender, address indexed agentAddress, bytes message, uint256 value);

    constructor() Ownable(msg.sender) {
        minimumValueForSendingMessageInWei = 10000000000000; // 0.00001 xDAI
    }

    modifier mustPayMoreThanMinimum() {
        require(msg.value >= minimumValueForSendingMessageInWei, "Insufficient message value");
        _;
    }

    function adjustMinimumValueForSendingMessage(uint256 newValue) public onlyOwner {
        minimumValueForSendingMessageInWei = newValue;
    }

    function countMessages(address agentAddress) public view returns (uint256) {
        return DoubleEndedStructQueue.length(queues[agentAddress]);
    }

    function sendMessage(address agentAddress, bytes memory message) public payable mustPayMoreThanMinimum {
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

    function popNextMessage(address agentAddress) public returns (DoubleEndedStructQueue.MessageContainer memory) {
        if (msg.sender != agentAddress) {
            revert MessageNotSentByAgent();
        }
        DoubleEndedStructQueue.MessageContainer memory message = DoubleEndedStructQueue.popFront(queues[agentAddress]);
        emit LogMessage(message.sender, agentAddress, message.message, message.value);
        return message;
    }
}
