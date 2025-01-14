// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleTreasury is Ownable {
    IERC721 public nftContract;
    uint256 public requiredNFTBalance = 3;

    function setRequiredNFTBalance(uint256 _newBalance) external onlyOwner {
        requiredNFTBalance = _newBalance;
    }

    event WithdrawnByNFTHolder(address indexed holder, uint256 amount);

    constructor(address _nftContract) Ownable(msg.sender) {
        require(_nftContract != address(0), "Invalid NFT contract address");
        nftContract = IERC721(_nftContract);
    }

    // Function to receive ETH
    receive() external payable {}

    // Withdraw function that checks NFT balance
    function withdraw() external {
        uint256 nftBalance = nftContract.balanceOf(msg.sender);
        require(nftBalance >= requiredNFTBalance, "Insufficient NFT balance");

        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success,) = payable(msg.sender).call{value: balance}("");
        require(success, "Transfer failed");

        emit WithdrawnByNFTHolder(msg.sender, balance);
    }
}
