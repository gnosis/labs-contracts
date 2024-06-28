// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {OmenThumbnailMapping, IERC20} from "../src/OmenThumbnailMapping.sol";

contract OmenThumbnailMappingTest is Test {
    OmenThumbnailMapping public omenThumbnailMapping;
    ERC20Mock public productMarketMaker;

    function setUp() public {
        omenThumbnailMapping = new OmenThumbnailMapping();
        productMarketMaker = new ERC20Mock();
    }

    function testCanNotUpdateImageWithoutProvidedLiquidity() public {
        vm.expectRevert();
        omenThumbnailMapping.set(address(productMarketMaker), "Qm123");
    }

    function testCanUpdateImageWithAnyFundsInMarketIfThisIsFirstUpdater() public {
        productMarketMaker.mint(address(this), 1);
        vm.expectEmit(true, true, true, true);
        emit OmenThumbnailMapping.ImageUpdated(address(productMarketMaker), "Qm123", address(this));
        omenThumbnailMapping.set(address(productMarketMaker), "Qm123");
        assertEq(omenThumbnailMapping.get(address(productMarketMaker)), "Qm123");
    }

    function testCanUpdateImageWithAnyFundsInMarketIfThisIsTheSamePersonAsTheOneWhoChangedTheImageLastTime() public {
        productMarketMaker.mint(address(this), 1);
        omenThumbnailMapping.set(address(productMarketMaker), "Qm123");
        assertEq(omenThumbnailMapping.get(address(productMarketMaker)), "Qm123");
        omenThumbnailMapping.set(address(productMarketMaker), "Qm456");
        assertEq(omenThumbnailMapping.get(address(productMarketMaker)), "Qm456");
    }

    function testAnotherUserCanNotUpdateWithoutDoubleTheFunds() public {
        productMarketMaker.mint(address(this), 1);
        omenThumbnailMapping.set(address(productMarketMaker), "Qm123");
        assertEq(omenThumbnailMapping.get(address(productMarketMaker)), "Qm123");

        address anotherUser = address(0x123);
        productMarketMaker.mint(anotherUser, 1);
        vm.prank(anotherUser);
        vm.expectRevert();
        omenThumbnailMapping.set(address(productMarketMaker), "Qm456");
    }

    function testAnotherUserCaUpdateWithDoubleTheFunds() public {
        productMarketMaker.mint(address(this), 1);
        omenThumbnailMapping.set(address(productMarketMaker), "Qm123");
        assertEq(omenThumbnailMapping.get(address(productMarketMaker)), "Qm123");

        address anotherUser = address(0x123);
        productMarketMaker.mint(anotherUser, 2);
        vm.prank(anotherUser);
        omenThumbnailMapping.set(address(productMarketMaker), "Qm456");
        assertEq(omenThumbnailMapping.get(address(productMarketMaker)), "Qm456");
    }

    function testNonSetImageIsEqualToNullBytes32() public {
        assertEq(omenThumbnailMapping.get(address(productMarketMaker)), bytes32(0));
    }

    function testImageIsNullBytesAfterRemovalAndChangerIsUpdatedCorrectly() public {
        productMarketMaker.mint(address(this), 1);
        vm.expectEmit(true, true, true, true);
        emit OmenThumbnailMapping.ImageUpdated(address(productMarketMaker), "Qm123", address(this));
        omenThumbnailMapping.set(address(productMarketMaker), "Qm123");
        assertEq(omenThumbnailMapping.get(address(productMarketMaker)), "Qm123");
        assertEq(omenThumbnailMapping.getLatestImageChanger(address(productMarketMaker)), address(this));

        address anotherUser = address(0x123);
        productMarketMaker.mint(anotherUser, 2);
        vm.expectEmit(true, true, true, true);
        emit OmenThumbnailMapping.ImageUpdated(address(productMarketMaker), bytes32(0), anotherUser);
        vm.prank(anotherUser);

        omenThumbnailMapping.remove(address(productMarketMaker));
        assertEq(omenThumbnailMapping.get(address(productMarketMaker)), bytes32(0));
        assertEq(omenThumbnailMapping.getLatestImageChanger(address(productMarketMaker)), anotherUser);
    }
}
