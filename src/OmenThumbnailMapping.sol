// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IFixedProductMarketMaker {
    function balanceOf(address account) external view returns (uint256);
}

contract OmenThumbnailMapping {
    // Mapping from market's address to image's IPFS hash
    mapping(address => string) private marketAddressToIPFSHash;
    mapping(address => address) private marketAddressToLatestImageChanger;

    function get(address marketAddress) public view returns (string memory) {
        // Get IPFS hash of thumbnail for the given market.
        return marketAddressToIPFSHash[marketAddress];
    }

    function set(address marketAddress, string memory image_hash) public {
        // Update IPFS hash of thumbnail for the given market.
        requireThatSenderCanChangeImage(marketAddress);
        marketAddressToIPFSHash[marketAddress] = image_hash;
        marketAddressToLatestImageChanger[marketAddress] = msg.sender;
    }

    function remove(address marketAddress) public {
        // Remove IPFS hash of thumbnail for the given market.
        requireThatSenderCanChangeImage(marketAddress);
        delete marketAddressToIPFSHash[marketAddress];
        marketAddressToLatestImageChanger[marketAddress] = msg.sender;
    }

    function requireThatSenderCanChangeImage(
        address marketAddress
    ) public view {
        // Verify that sender is allowed to update IPFS hash for the given market.
        IFixedProductMarketMaker market = IFixedProductMarketMaker(
            marketAddress
        );
        uint256 fundedBySender = market.balanceOf(msg.sender);
        require(fundedBySender > 0, "Sender has no shares in the market.");

        address latestImageChanger = marketAddressToLatestImageChanger[
            marketAddress
        ];
        uint256 fundedByLatestImageChanger = market.balanceOf(
            latestImageChanger
        );
        require(
            latestImageChanger == address(0) ||
                fundedBySender > 2 * fundedByLatestImageChanger,
            "Sender don't have at least double the shares than the latest person who updated the image."
        );
    }
}