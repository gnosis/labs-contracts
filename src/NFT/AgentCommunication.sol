// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./DoubleEndedStructQueue.sol";

contract AgentCommunication is Ownable {
    error MessageNotSentByAgent();

    mapping(address => DoubleEndedStructQueue.Bytes32Deque) public queues;
    uint256 public minimumValueForSendingMessageInWei;

    event NewMessageSent(address indexed sender, address indexed agentAddress, bytes message);
    event MessagePopped(address indexed agentAddress, bytes message);

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

    function sendMessage(address agentAddress, DoubleEndedStructQueue.MessageContainer memory message)
        public
        payable
        mustPayMoreThanMinimum
    {
        DoubleEndedStructQueue.pushBack(queues[agentAddress], message);
        emit NewMessageSent(msg.sender, agentAddress, message.message);
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
        emit MessagePopped(agentAddress, message.message);
        return message;
    }
}
