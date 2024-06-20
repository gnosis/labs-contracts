// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {OmenThumbnailMapping, IFixedProductMarketMaker} from "../src/OmenThumbnailMapping.sol";

contract FixedProductMarketMaker is IFixedProductMarketMaker {
    // Mocked product maker that allows us to easily change balances (liquidity provided by the user).
    mapping(address => uint256) private balances;

    function setBalance(address account, uint256 balance) public {
        balances[account] = balance;
    }

    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return balances[account];
    }
}

contract OmenThumbnailMappingTest is Test {
    OmenThumbnailMapping public omenThumbnailMapping;
    FixedProductMarketMaker public productMarketMaker;

    function setUp() public {
        omenThumbnailMapping = new OmenThumbnailMapping();
        productMarketMaker = new FixedProductMarketMaker();
    }

    function testCanNotUpdateImageWithoutProvidedLiquidity() public {
        productMarketMaker.setBalance(address(this), 0);
        vm.expectRevert();
        omenThumbnailMapping.set(address(productMarketMaker), "Qm123");
    }

    function testCanUpdateImageWithAnyFundsInMarketIfThisIsFirstUpdater()
        public
    {
        productMarketMaker.setBalance(address(this), 1);
        omenThumbnailMapping.set(address(productMarketMaker), "Qm123");
        assertEq(
            omenThumbnailMapping.get(address(productMarketMaker)),
            "Qm123"
        );
    }

    function testCanUpdateImageWithAnyFundsInMarketIfThisIsTheSamePersonAsTheOneWhoChangedTheImageLastTime()
        public
    {
        productMarketMaker.setBalance(address(this), 1);
        omenThumbnailMapping.set(address(productMarketMaker), "Qm123");
        assertEq(
            omenThumbnailMapping.get(address(productMarketMaker)),
            "Qm123"
        );
        omenThumbnailMapping.set(address(productMarketMaker), "Qm456");
        assertEq(
            omenThumbnailMapping.get(address(productMarketMaker)),
            "Qm456"
        );
    }

    function testAnotherUserCanNotUpdateWithoutDoubleTheFunds() public {
        productMarketMaker.setBalance(address(this), 1);
        omenThumbnailMapping.set(address(productMarketMaker), "Qm123");
        assertEq(
            omenThumbnailMapping.get(address(productMarketMaker)),
            "Qm123"
        );

        address anotherUser = address(0x123);
        productMarketMaker.setBalance(anotherUser, 1);
        vm.prank(anotherUser);
        vm.expectRevert();
        omenThumbnailMapping.set(address(productMarketMaker), "Qm456");
    }

    function testAnotherUserCaUpdateWithDoubleTheFunds() public {
        productMarketMaker.setBalance(address(this), 1);
        omenThumbnailMapping.set(address(productMarketMaker), "Qm123");
        assertEq(
            omenThumbnailMapping.get(address(productMarketMaker)),
            "Qm123"
        );

        address anotherUser = address(0x123);
        productMarketMaker.setBalance(anotherUser, 2);
        vm.prank(anotherUser);
        omenThumbnailMapping.set(address(productMarketMaker), "Qm456");
        assertEq(
            omenThumbnailMapping.get(address(productMarketMaker)),
            "Qm456"
        );
    }
}
