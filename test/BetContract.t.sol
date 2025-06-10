// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import "forge-std/console.sol";
import "./helpers/FPMMTestHelper.sol";
import "../src/crc_prediction_markets/BetContract.sol";

contract BetContractTest is FPMMTestHelper {
    BetContract public betContract;
    uint256 constant TOKEN_ID = 1;
    uint256 constant AMOUNT = 100;

    function setUp() public {
        // Setup FPMM environment using the helper
        _setupFPMMEnvironment();

        // Deploy BetContract with mock FPMM
        betContract = deployBetContract("Organization1", bytes32(0));

        // deposit wxdai
        vm.deal(address(betContract), 10 ether);
    }

    function testERC1155Triggered() public {
        // mint to group
        address[] memory collateral = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        collateral[0] = addresses[0];
        amounts[0] = 1 * CRC;
        vm.prank(addresses[0]);
        hub.groupMint(group, collateral, amounts, "");
        console.log("group", group);

        // check balances
        uint256 aliceG1 = hub.balanceOf(addresses[0], uint256(uint160(group)));
        assertEq(aliceG1, 1 * CRC);

        // Send CRC from Alice to another address
        address recipient = addresses[1]; // Example recipient
        uint256 amount = 1 * CRC; // Amount to send
        vm.prank(addresses[0]); // Prank as Alice
        hub.safeTransferFrom(addresses[0], recipient, uint256(uint160(group)), amount, "");
        uint256 bobG1 = hub.balanceOf(recipient, uint256(uint160(group)));
        assertEq(bobG1, 1 * CRC);

        // Send CRC to contract
        console.log("bet yes contract", address(betContract));
        vm.prank(recipient);
        hub.safeTransferFrom(recipient, address(betContract), uint256(uint160(group)), amount, "");

        // assert balance was updated
        uint256 balance = betContract.balanceOf(recipient);
        assertGt(balance, 0);
    }

    function testGroupMint() public {
        // mint to group
        address[] memory collateral = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        collateral[0] = addresses[0];
        amounts[0] = 1 * CRC;
        vm.prank(addresses[0]);
        hub.groupMint(group, collateral, amounts, "");
        console.log("group", group);

        // check balances
        uint256 aliceG1 = hub.balanceOf(addresses[0], uint256(uint160(group)));
        assertEq(aliceG1, 1 * CRC);

        // check total supply through Standard Vault
        StandardTreasury treasury = mockDeployment.treasury();

        // assert that the vault has been created
        address vault = address(treasury.vaults(group));
        assertTrue(vault != address(0));
        // assert that Vault holds Alice's 1 CRC;
        // todo: total supply is not (yet) implemented in hub erc1155
        assertEq(hub.balanceOf(vault, uint256(uint160(addresses[0]))), 1 * CRC);
    }
}
