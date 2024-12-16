// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AgentCommunication is Ownable {
    error MessageNotSentByAgent();

    mapping(address => DoubleEndedQueue.Bytes32Deque) public queues;
    uint256 public minimumValueForSendingMessageInWei;

    event NewMessageSent(address indexed sender, bytes32 message);

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

    function sendMessage(address agentAddress, bytes32 message) public payable mustPayMoreThanMinimum {
        DoubleEndedQueue.pushBack(queues[agentAddress], message);
        emit NewMessageSent(agentAddress, message);
    }

    function getAtIndex(address agentAddress, uint256 idx) public view returns (bytes32) {
        return DoubleEndedQueue.at(queues[agentAddress], idx);
    }

    function popNextMessage(address agentAddress) public returns (bytes32) {
        if (msg.sender != agentAddress) {
            revert MessageNotSentByAgent();
        }
        return DoubleEndedQueue.popFront(queues[agentAddress]);
    }
}
