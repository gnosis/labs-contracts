// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {
    uint256 private _tokenIdCounter;

    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to) external returns (uint256) {
        uint256 tokenId = _tokenIdCounter++;
        _mint(to, tokenId);
        return tokenId;
    }
}
