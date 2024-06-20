// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import {IERC20} from "../interfaces/IERC20.sol";

/// @dev Mapping from market's address to image's IPFS hash
contract OmenThumbnailMapping {
    mapping(address => bytes32) private marketAddressToIPFSHash;
    mapping(address => address) private marketAddressToLatestImageChanger;

    /// @dev Get IPFS hash of thumbnail for the given market.
    function get(address marketAddress) public view returns (bytes32) {
        return marketAddressToIPFSHash[marketAddress];
    }

    /// @dev Update IPFS hash of thumbnail for the given market.
    function set(address marketAddress, bytes32 image_hash) public requireThatSenderCanChangeImage(marketAddress) {
        marketAddressToIPFSHash[marketAddress] = image_hash;
        marketAddressToLatestImageChanger[marketAddress] = msg.sender;
    }

    /// @dev Remove IPFS hash of thumbnail for the given market.
    function remove(address marketAddress) public requireThatSenderCanChangeImage(marketAddress) {
        delete marketAddressToIPFSHash[marketAddress];
        marketAddressToLatestImageChanger[marketAddress] = msg.sender;
    }

    /// @dev Verify that sender is allowed to update IPFS hash for the given market.
    modifier requireThatSenderCanChangeImage(address marketAddress) {
        // Omen's FixedProductMarketMaker contract inherits from IERC20: https://gnosisscan.io/address/0x9083a2b699c0a4ad06f63580bde2635d26a3eef0#code.
        IERC20 market = IERC20(marketAddress);
        uint256 fundedBySender = market.balanceOf(msg.sender);
        require(fundedBySender > 0, "Sender has no shares in the market.");

        address latestImageChanger = marketAddressToLatestImageChanger[marketAddress];
        uint256 fundedByLatestImageChanger = market.balanceOf(latestImageChanger);
        require(
            latestImageChanger == address(0) || latestImageChanger == msg.sender
                || fundedBySender >= 2 * fundedByLatestImageChanger,
            "Sender doesn't have at least double the shares than the latest person who updated the image and the sender isn't the latest person who updated it."
        );

        _;
    }
}
