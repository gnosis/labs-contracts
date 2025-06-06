// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import "forge-std/console.sol";
import "circles-v2-test/groups/groupSetup.sol";
import "circles-v2/errors/Errors.sol";
import "../src/crc_prediction_markets/BetContract.sol";
import "./mocks/MockFixedProductMarketMaker.sol";
import "../src/crc_prediction_markets/LiquidityVaultToken.sol";

contract BetTest is Test, GroupSetup, IHubErrors {
    address group;
    BetContract betContract;
    uint256 constant TOKEN_ID = 1;
    uint256 constant AMOUNT = 100;
    uint256 constant mockOutcomeIndex = 0;
    uint256 constant OUTCOME_SLOT_COUNT = 2;
    uint256 constant CONDITION_ID = 1;
    // market also has a condition_id, outcome_slot_count
    //address constant fpmmMarketId = address(0x011F45E9DC3976159edf0395C0Cd284df91F59Bc);
    address fpmmMarketId;

    LiquidityVaultToken liquidityVaultToken;

    constructor() GroupSetup() {}

    // Setup

    function setUp() public {
        groupSetup();

        // register a group already
        group = addresses[35];
        console.log("inside setup, group", group);
        console.log("inside setup, hub", address(hub));

        vm.prank(group);
        hub.registerGroup(mintPolicy, "Group1", "G1", bytes32(0));

        // G1 trusts first 5 humans
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(group);
            hub.trust(addresses[i], INDEFINITE_FUTURE);

            // and each human trusts the group
            vm.prank(addresses[i]);
            hub.trust(group, INDEFINITE_FUTURE);
        }

        // determine erc20 to use as collateral token
        address erc20Group = hub.wrap(address(group), 0, CirclesType.Inflation);
        console.log("collateral ERC20 group CRC token", address(erc20Group));

        // Deploy mock FPMM
        MockFixedProductMarketMaker mockFPMM = new MockFixedProductMarketMaker(
            //address(mockWXDAI), // Using mockWXDAI as collateral
            address(erc20Group),
            OUTCOME_SLOT_COUNT,
            CONDITION_ID
        );
        fpmmMarketId = address(mockFPMM);
        console.log("before liquidity vault");
        // liquidity vault
        liquidityVaultToken = new LiquidityVaultToken();
        console.log("after liquidity vault");

        // Deploy BetContract with mock FPMM
        betContract = new BetContract(
            fpmmMarketId,
            address(group),
            mockOutcomeIndex,
            address(hub),
            1,
            "Organization1",
            bytes32(0),
            address(liquidityVaultToken)
        );

        // deposit wxdai
        vm.deal(address(betContract), 10 ether);
    }

    function testERC1155Triggered() public {
        console.log("entered testERC1155Triggered");
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
