// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/crc_prediction_markets/LiquidityAdder.sol";
import "../src/crc_prediction_markets/IFixedProductMarketMaker.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {CirclesType} from "circles-v2/lift/IERC20Lift.sol";

contract LiquidityAdderTest is Test {
    function setUp() public {
        console.log("setup LiquidityAdder test");
    }

    function test_OnERC1155Received() public {
        console.log("test_OnERC1155Received");
    }
}
