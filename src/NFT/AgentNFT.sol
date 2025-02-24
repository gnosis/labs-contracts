// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AgentNFT is ERC721, Ownable {
    uint256 private _nextTokenId;
    uint256 public immutable MAX_SUPPLY;

    constructor(uint256 maxSupply) ERC721("Gnosis Agents NFT", "GANFT") Ownable(msg.sender) {
        MAX_SUPPLY = maxSupply;
    }

    function safeMint(address to) public onlyOwner {
        if (_nextTokenId >= MAX_SUPPLY) {
            revert("Max supply reached");
        }
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }
}
