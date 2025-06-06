// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1155 as OZERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LiquidityVaultToken is OZERC1155, AccessControl {
    using Strings for uint256;

    // Base role for all market-specific updater roles
    bytes32 public constant UPDATER_ROLE_BASE = keccak256("UPDATER_ROLE");

    // Base URI for token metadata
    string private _baseURI;

    constructor() OZERC1155("crc-pm-token-") AccessControl() {
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function parseAddress(address _address) public pure returns (uint256) {
        return uint256(uint160(_address));
    }

    // Get the role for a specific market's updater
    function getUpdaterRole(address marketId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(UPDATER_ROLE_BASE, parseAddress(marketId)));
    }

    // Mint tokens for a specific market
    function mintTo(address to, address marketId, uint256 amount, bytes calldata data)
        external
        onlyRole(getUpdaterRole(marketId))
    {
        _mint(to, parseAddress(marketId), amount, data);
    }

    // Burn tokens from a specific market
    function burnFrom(address from, address marketId, uint256 amount) external onlyRole(getUpdaterRole(marketId)) {
        _burn(from, parseAddress(marketId), amount);
    }

    // Transfer tokens between users for a specific market
    function safeTransferFromUser(address from, address to, address marketId, uint256 amount, bytes calldata data)
        external
        onlyRole(getUpdaterRole(marketId))
    {
        safeTransferFrom(from, to, parseAddress(marketId), amount, data);
    }

    // Add an updater for a specific market
    function addUpdater(address account, address marketId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bytes32 role = getUpdaterRole(marketId);
        grantRole(role, account);
    }

    // Remove an updater from a specific market
    function removeUpdater(address account, address marketId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bytes32 role = getUpdaterRole(marketId);
        revokeRole(role, account);
    }

    // Set the base URI for token metadata
    function setBaseURI(string memory newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseURI = newBaseURI;
    }

    // Override URI to include the base URI
    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    // Required override for ERC1155 and AccessControl
    function supportsInterface(bytes4 interfaceId) public view override(OZERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
