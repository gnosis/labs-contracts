// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/crc_prediction_markets/BetContractFactory.sol";
import "../src/crc_prediction_markets/BetContract.sol";
import "../src/crc_prediction_markets/LiquidityVaultToken.sol";
import "../src/crc_prediction_markets/IFixedProductMarketMaker.sol";
import "../src/crc_prediction_markets/IConditionalTokens.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../test/mocks/MockFixedProductMarketMaker.sol";
import "../test/mocks/MockHubCRCPMs.sol";
import "../test/mocks/MockConditionalTokens.sol";
import "../test/mocks/MockERC20.sol";
import "../test/helpers/FPMMTestHelper.sol";
import {console} from "forge-std/console.sol";

contract BetContractFactoryTest is FPMMTestHelper {
    BetContractFactory factory;
    MockFixedProductMarketMaker fpmm;

    //MockHubCRCPMs hub;
    address fpmmAddress;
    address groupTokenAddress;
    address hubAddress;

    uint256 constant TOKEN_ID = 1;
    uint256 constant AMOUNT = 100;

    bytes32[] conditionIds;

    function setUp() public {
        // Deploy mock contracts
        console.log("before setup fpmm betContractFactory");
        _setupFPMMEnvironment();
        console.log("after setup fpmm betContractFactory");
        //MockERC20 mockToken = new MockERC20("Test Token", "TEST");
        //groupCRCToken = address(mockToken);

        //fpmm = new MockFixedProductMarketMaker(group, OUTCOME_SLOT_COUNT, CONDITION_ID);

        // Set addresses
        //fpmmAddress = address(fpmm);
        groupTokenAddress = address(group);
        hubAddress = address(hub);

        conditionIds = buildMockConditionIds();

        // Deploy factory
        factory = new BetContractFactory(hubAddress);
    }

    function buildMockConditionIds() private pure returns (bytes32[] memory) {
        bytes32[] memory _conditionIds = new bytes32[](1);
        _conditionIds[0] = bytes32(0);
        return _conditionIds;
    }

    function buildOutcomeIndicesArray(uint256 value) private pure returns (uint256[] memory) {
        uint256[] memory outcomeIndexes = new uint256[](1);
        outcomeIndexes[0] = value;
        return outcomeIndexes;
    }

    function testFactoryDeployment() public {
        assertEq(address(factory) != address(0), true, "Factory should be deployed");
    }

    function testCreateContractsForFpmm() public {
        // Create bet contracts
        uint256[] memory outcomeIndexes = new uint256[](2);
        outcomeIndexes[0] = 0;
        outcomeIndexes[1] = 1;

        factory.createContractsForFpmm(
            fpmmMarketId,
            groupTokenAddress,
            outcomeIndexes,
            conditionIds,
            buildOrganizationNames(),
            buildOrganizationMetadataDigests()
        );

        // Get market info
        MarketInfo memory marketInfo = factory.getMarketInfo(fpmmMarketId);

        assertEq(marketInfo.fpmmAddress, fpmmMarketId, "FPMM address should match");
        assertEq(marketInfo.groupCRCToken, groupTokenAddress, "Group CRC token should match");
        assertEq(marketInfo.outcomeIdxs.length, 2, "Should have 2 outcome indices");
        assertEq(marketInfo.betContracts.length, 2, "Should have 2 bet contracts");

        // Create again to test idempotency
        outcomeIndexes = buildOutcomeIndicesArray(0);

        factory.createContractsForFpmm(
            fpmmMarketId,
            groupTokenAddress,
            outcomeIndexes,
            conditionIds,
            buildOrganizationNames(),
            buildOrganizationMetadataDigests()
        );
    }

    function testLiquidityInfo() public {
        uint256[] memory outcomeIndexes = new uint256[](2);
        outcomeIndexes[0] = 0;
        outcomeIndexes[1] = 1;

        factory.createContractsForFpmm(
            fpmmMarketId,
            groupTokenAddress,
            outcomeIndexes,
            conditionIds,
            buildOrganizationNames(),
            buildOrganizationMetadataDigests()
        );

        LiquidityInfo memory liquidityInfo = factory.getLiquidityInfo(fpmmMarketId);
        assertTrue(liquidityInfo.liquidityAdder != address(0), "Liquidity adder not empty");
        assertTrue(liquidityInfo.liquidityRemover != address(0), "Liquidity remover not empty");
        assertTrue(liquidityInfo.liquidityVaultToken != address(0), "Liquidity vault token not empty");
    }

    function testCannotCreateWithZeroAddresses() public {
        // Test with zero FPMM address
        console.log("testCannotCreateWithZeroAddresses");
        vm.expectRevert("Invalid FPMM address");
        uint256[] memory outcomeIndexes = buildOutcomeIndicesArray(0);
        bytes32[] memory organizationMetadataDigests = buildOrganizationMetadataDigests();
        string[] memory organizationNames = buildOrganizationNames();
        factory.createContractsForFpmm(
            address(0), groupTokenAddress, outcomeIndexes, conditionIds, organizationNames, organizationMetadataDigests
        );
        console.log("first test passed");
        // Test with zero group CRC token address
        vm.expectRevert("Invalid group CRC token address");

        factory.createContractsForFpmm(
            fpmmMarketId, address(0), outcomeIndexes, conditionIds, organizationNames, organizationMetadataDigests
        );
    }

    function testBetContractCreation() public {
        // Create bet contracts
        uint256[] memory outcomeIndexes = new uint256[](2);
        outcomeIndexes[0] = 0;
        outcomeIndexes[1] = 1;

        factory.createContractsForFpmm(
            fpmmMarketId,
            groupTokenAddress,
            outcomeIndexes,
            conditionIds,
            buildOrganizationNames(),
            buildOrganizationMetadataDigests()
        );
        console.log("after fpmm creation");
        // Get market info
        MarketInfo memory marketInfo = factory.getMarketInfo(fpmmMarketId);

        console.log("1 testBetContractCreation");

        // Verify bet contracts
        for (uint256 i = 0; i < 2; i++) {
            BetContract betContract = BetContract(marketInfo.betContracts[i]);
            console.log("2");
            assertEq(address(betContract.fpmm()), fpmmMarketId, "FPMM address should match");
            assertEq(address(betContract.groupCRCToken()), groupTokenAddress, "Group CRC token should match");
            assertEq(betContract.outcomeIndex(), i, "Outcome index should match");
            assertEq(address(betContract.hub()), hubAddress, "Hub address should match");
        }

        // verify liquidity info
        LiquidityInfo memory liquidityInfo = factory.getLiquidityInfo(fpmmMarketId);
        LiquidityVaultToken liquidityVaultToken = LiquidityVaultToken(liquidityInfo.liquidityVaultToken);
        bytes32 role = liquidityVaultToken.getUpdaterRole(fpmmMarketId);
        assertTrue(liquidityVaultToken.hasRole(role, liquidityInfo.liquidityAdder));
        assertTrue(liquidityVaultToken.hasRole(role, liquidityInfo.liquidityRemover));
    }

    function testAddLiquidity() public {
        // Create bet contracts
        console.log("entered testAddLiquidity");
        uint256[] memory outcomeIndexes = new uint256[](2);
        outcomeIndexes[0] = 0;
        outcomeIndexes[1] = 1;

        factory.createContractsForFpmm(
            fpmmMarketId,
            groupTokenAddress,
            outcomeIndexes,
            conditionIds,
            buildOrganizationNames(),
            buildOrganizationMetadataDigests()
        );
        // verify liquidity info
        LiquidityInfo memory liquidityInfo = factory.getLiquidityInfo(fpmmMarketId);
        LiquidityAdder liquidityAdder = LiquidityAdder(liquidityInfo.liquidityAdder);
        console.logAddress(address(liquidityAdder));

        // mint CRC group tokens
        address alice = addresses[0];
        uint256 amount = 1 * CRC;
        mintToGroup(alice, amount);

        // send group CRC tokens to liquidityAdder
        vm.prank(alice);
        console.log("destination");
        console.logAddress(address(liquidityAdder));
        hub.safeTransferFrom(alice, address(liquidityAdder), uint256(uint160(group)), amount, "");
        vm.stopPrank();

        LiquidityVaultToken liquidityVaultToken = LiquidityVaultToken(liquidityInfo.liquidityVaultToken);
        uint256 lpTokensBalance = liquidityVaultToken.balanceOf(alice, liquidityVaultToken.parseAddress(fpmmMarketId));
        assertTrue(lpTokensBalance > 0);
    }

    function testRemoveLiquidity() public {
        // Create bet contracts
        console.log("entered testRemoveLiquidity");
        uint256[] memory outcomeIndexes = new uint256[](2);
        outcomeIndexes[0] = 0;
        outcomeIndexes[1] = 1;

        factory.createContractsForFpmm(
            fpmmMarketId,
            groupTokenAddress,
            outcomeIndexes,
            conditionIds,
            buildOrganizationNames(),
            buildOrganizationMetadataDigests()
        );
        // verify liquidity info
        LiquidityInfo memory liquidityInfo = factory.getLiquidityInfo(fpmmMarketId);
        address liquidityAdder = liquidityInfo.liquidityAdder;
        address liquidityRemover = liquidityInfo.liquidityRemover;

        // mint CRC group tokens
        address alice = addresses[0];
        uint256 amount = 1 * CRC;
        mintToGroup(alice, 10 * CRC);

        // send group CRC tokens to liquidityAdder
        vm.prank(alice);

        // first we add some lp shares
        console.log("before add, removeLiquidity");
        hub.safeTransferFrom(alice, liquidityAdder, uint256(uint160(group)), amount, "");
        // here Alice should have a balance on LV, and LV should have a balance on fpmm
        uint256 balanceAlice1 = liquidityVaultToken.balanceOf(alice, liquidityVaultToken.parseAddress(fpmmMarketId));
        console.log("balance Alice", balanceAlice1);
        uint256 balanceLV1 = IERC20(fpmmMarketId).balanceOf(address(liquidityVaultToken));
        console.log("balance LV after alice", balanceLV1);

        console.log("after add, removeLiquidity");
        // then we remove the lp shares
        uint256 sharesAfterDeposit =
            liquidityVaultToken.balanceOf(alice, liquidityVaultToken.parseAddress(fpmmMarketId));
        console.log("shares after deposit", sharesAfterDeposit);
        uint256 balanceAdder = IERC20(fpmmMarketId).balanceOf(liquidityAdder);
        uint256 balanceRemover = IERC20(fpmmMarketId).balanceOf(liquidityRemover);
        uint256 balanceLV = IERC20(fpmmMarketId).balanceOf(address(liquidityVaultToken));
        console.log("balance adder", balanceAdder);
        console.log("balance remover", balanceRemover);
        console.log("balance liquidity vault", balanceLV);
        // ToDo - LP tokens must be transferred to LiquidityVault, who should do the handling
        vm.prank(alice);
        hub.safeTransferFrom(alice, liquidityRemover, uint256(uint160(group)), amount, "");

        LiquidityVaultToken liquidityVaultToken = LiquidityVaultToken(liquidityInfo.liquidityVaultToken);
        uint256 lpTokensBalance = liquidityVaultToken.balanceOf(alice, liquidityVaultToken.parseAddress(fpmmMarketId));
        assertTrue(lpTokensBalance == 0);
    }

    function buildOrganizationNames() private pure returns (string[] memory) {
        string[] memory organizationNames = new string[](2);
        organizationNames[0] = "Organization 1";
        organizationNames[1] = "Organization 2";
        return organizationNames;
    }

    function buildOrganizationMetadataDigests() private pure returns (bytes32[] memory) {
        bytes32[] memory organizationMetadataDigests = new bytes32[](2);
        organizationMetadataDigests[0] = bytes32(0);
        organizationMetadataDigests[1] = bytes32(0);
        return organizationMetadataDigests;
    }

    function testFpmmAddressTracking() public {
        // Create bet contracts
        uint256[] memory outcomeIndexes = buildOutcomeIndicesArray(0);
        bytes32[] memory organizationMetadataDigests = buildOrganizationMetadataDigests();
        string[] memory organizationNames = buildOrganizationNames();
        console.log("before create bet contract");
        factory.createContractsForFpmm(
            fpmmMarketId,
            groupTokenAddress,
            outcomeIndexes,
            conditionIds,
            organizationNames,
            organizationMetadataDigests
        );
        console.log("after create bet contract");

        // Verify FPMM address is tracked
        assertTrue(factory.fpmmAlreadyProcessed(fpmmMarketId), "FPMM address should be tracked");
        console.log("after first verify");

        // Create another market
        MockFixedProductMarketMaker mockFpmm = new MockFixedProductMarketMaker(group, OUTCOME_SLOT_COUNT, CONDITION_ID);

        outcomeIndexes = new uint256[](2);
        outcomeIndexes[0] = uint256(0);
        outcomeIndexes[1] = uint256(1);

        factory.createContractsForFpmm(
            address(mockFpmm),
            groupTokenAddress,
            outcomeIndexes,
            conditionIds,
            organizationNames,
            organizationMetadataDigests
        );
        console.log("before assert");
        // Verify both FPMM addresses are tracked
        assertTrue(factory.fpmmAlreadyProcessed(fpmmMarketId), "First FPMM address should still be tracked");
        console.log("after first assert");
        assertTrue(factory.fpmmAlreadyProcessed(address(mockFpmm)), "Second FPMM address should be tracked");
    }
}
