// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {OmenThumbnailMapping, IFixedProductMarketMaker} from "../src/OmenThumbnailMapping.sol";

contract OmenThumbnailMappingTest is Test {
    OmenThumbnailMapping public omenThumbnailMapping;

    function setUp() public {
        omenThumbnailMapping = new OmenThumbnailMapping();
    }

    function testCanUpdateImageWithAnyFundsInMarketIfThisIsFirstUpdater()
        public
    {
        // I created `omenThumbnailMapping` in `setUp` function above.
        // It implements `set` method which will do IFixedProductMarketMaker(marketAddress).balanceOf(msg.sender)
        // to obtain funds provided by the sender.
        // In this test, I would like to mock that `balanceOf` method to returns N amount of Wei, to test out that it will correctly allow to update the image.
        // Right now this test fails, because market with address `address(this)` doesn't exist, and if I use existing market, there won't be any funds provided by this test.
        omenThumbnailMapping.set(address(this), "Qm123");
    }
}
