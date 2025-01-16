// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./DoubleEndedStructQueue.sol";

contract AgentCommunication is Ownable {
    address payable public treasury;
    uint256 public pctToTreasuryInBasisPoints; //70% becomes 7000

    error MessageNotSentByAgent();

    mapping(address => DoubleEndedStructQueue.Bytes32Deque) public queues;

    uint256 public minimumValueForSendingMessageInWei;

    event LogMessage(address indexed sender, address indexed agentAddress, bytes message, uint256 value);

    constructor(address payable _treasury, uint256 _pctToTreasuryInBasisPoints) Ownable(msg.sender) {
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
        // split message value between treasury and agent
        (uint256 amountForTreasury, uint256 amountForAgent) = _calculateAmounts(msg.value);

        // Transfer the amounts
        (bool sentTreasury,) = treasury.call{value: amountForTreasury}("");
        require(sentTreasury, "Failed to send Ether");
        (bool sentAgent,) = payable(agentAddress).call{value: amountForAgent}("");
        require(sentAgent, "Failed to send Ether");

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
