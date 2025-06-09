// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/crc_prediction_markets/LiquidityAdder.sol";
import "../src/crc_prediction_markets/IFixedProductMarketMaker.sol";
import "./helpers/FPMMTestHelper.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {CirclesType} from "circles-v2/lift/IERC20Lift.sol";

contract LiquidityAdderTest is FPMMTestHelper {
    LiquidityAdder liquidityAdder;

    function setUp() public {
        console.log("setup LiquidityAdder test");
        _setupFPMMEnvironment();
        liquidityAdder = new LiquidityAdder(
            fpmmMarketId, address(hub), address(group), address(liquidityVaultToken), OUTCOME_SLOT_COUNT
        );
        // deposit wxdai
        vm.deal(address(liquidityAdder), 10 ether);
    }

    function test_OnERC1155Received() public {
        console.log("test_OnERC1155Received");

        // send group CRC tokens to liquidityAdder
        // mint to group
        address[] memory avatars = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        avatars[0] = addresses[0];
        amounts[0] = 1 * CRC;
        vm.prank(addresses[0]);
        hub.groupMint(group, avatars, amounts, "");
        console.log("group", group);

        // check balances
        uint256 aliceG1 = hub.balanceOf(addresses[0], uint256(uint160(group)));
        assertEq(aliceG1, 1 * CRC);

        // send group CRC tokens to liquidityAdder
        vm.prank(addresses[0]);
        hub.safeTransferFrom(addresses[0], address(liquidityAdder), uint256(uint160(group)), 1 * CRC, "");
        vm.stopPrank();
    }
}
