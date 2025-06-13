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

contract BetContractFactoryTest is FPMMTestHelper {
    BetContractFactory factory;
    MockFixedProductMarketMaker fpmm;

    address fpmmAddress;
    address groupTokenAddress;
    address hubAddress;

    LiquidityVaultToken liquidityToken;
    LiquidityContractFactory liquidityContractFactory;

    uint256 constant TOKEN_ID = 1;
    uint256 constant AMOUNT = 100;

    bytes32[] conditionIds;

    function setUp() public {
        _setupFPMMEnvironment();

        groupTokenAddress = address(group);
        hubAddress = address(hub);

        conditionIds = buildMockConditionIds();
        liquidityContractFactory = new LiquidityContractFactory();
        factory = new BetContractFactory(hubAddress, address(liquidityContractFactory));
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

    function testFactoryDeployment() public view {
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
            buildBetContractOrganizationNames(),
            buildOrganizationMetadataDigests(),
            buildLiquidityOrganizationNames(),
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
            buildBetContractOrganizationNames(),
            buildOrganizationMetadataDigests(),
            buildLiquidityOrganizationNames(),
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
            buildBetContractOrganizationNames(),
            buildOrganizationMetadataDigests(),
            buildLiquidityOrganizationNames(),
            buildOrganizationMetadataDigests()
        );

        LiquidityInfo memory liquidityInfo = factory.getLiquidityInfo(fpmmMarketId);
        assertTrue(liquidityInfo.liquidityAdder != address(0), "Liquidity adder not empty");
        assertTrue(liquidityInfo.liquidityRemover != address(0), "Liquidity remover not empty");
        assertTrue(liquidityInfo.liquidityVaultToken != address(0), "Liquidity vault token not empty");
    }

    function testCannotCreateWithZeroAddresses() public {
        // Test with zero FPMM address

        vm.expectRevert("Invalid FPMM address");
        uint256[] memory outcomeIndexes = buildOutcomeIndicesArray(0);
        bytes32[] memory organizationMetadataDigests = buildOrganizationMetadataDigests();
        string[] memory organizationNames = buildBetContractOrganizationNames();
        factory.createContractsForFpmm(
            address(0),
            groupTokenAddress,
            outcomeIndexes,
            conditionIds,
            organizationNames,
            organizationMetadataDigests,
            buildLiquidityOrganizationNames(),
            buildOrganizationMetadataDigests()
        );

        // Test with zero group CRC token address
        vm.expectRevert("Invalid group CRC token address");

        factory.createContractsForFpmm(
            fpmmMarketId,
            address(0),
            outcomeIndexes,
            conditionIds,
            organizationNames,
            organizationMetadataDigests,
            buildLiquidityOrganizationNames(),
            buildOrganizationMetadataDigests()
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
            buildBetContractOrganizationNames(),
            buildOrganizationMetadataDigests(),
            buildLiquidityOrganizationNames(),
            buildOrganizationMetadataDigests()
        );

        // Get market info
        MarketInfo memory marketInfo = factory.getMarketInfo(fpmmMarketId);

        // Verify bet contracts
        for (uint256 i = 0; i < 2; i++) {
            BetContract betContract = BetContract(marketInfo.betContracts[i]);
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
        uint256[] memory outcomeIndexes = new uint256[](2);
        outcomeIndexes[0] = 0;
        outcomeIndexes[1] = 1;

        factory.createContractsForFpmm(
            fpmmMarketId,
            groupTokenAddress,
            outcomeIndexes,
            conditionIds,
            buildBetContractOrganizationNames(),
            buildOrganizationMetadataDigests(),
            buildLiquidityOrganizationNames(),
            buildOrganizationMetadataDigests()
        );
        // verify liquidity info
        LiquidityInfo memory liquidityInfo = factory.getLiquidityInfo(fpmmMarketId);
        LiquidityAdder liquidityAdder = LiquidityAdder(liquidityInfo.liquidityAdder);

        // mint CRC group tokens
        address alice = addresses[0];
        uint256 amount = 1 * CRC;
        mintToGroup(group, alice, amount);

        // send group CRC tokens to liquidityAdder
        vm.prank(alice);
        hub.safeTransferFrom(alice, address(liquidityAdder), uint256(uint160(group)), amount, "");
        vm.stopPrank();

        LiquidityVaultToken liquidityVaultToken = LiquidityVaultToken(liquidityInfo.liquidityVaultToken);

        uint256 lpTokensBalance = liquidityVaultToken.balanceOf(alice, liquidityVaultToken.parseAddress(fpmmMarketId));

        assertTrue(lpTokensBalance > 0);
    }

    function testCannotCreateContractsWhenPaused() public {
        // Pause the factory
        vm.prank(factory.owner());
        factory.pause();

        // Prepare test data
        uint256[] memory outcomeIndexes = new uint256[](2);
        outcomeIndexes[0] = 0;
        outcomeIndexes[1] = 1;

        bytes32[] memory _conditionIds = new bytes32[](1);
        _conditionIds[0] = keccak256("test-condition");

        string[] memory orgNames = new string[](2);
        orgNames[0] = "Org1";
        orgNames[1] = "Org2";

        bytes32[] memory orgMetadata = new bytes32[](2);
        orgMetadata[0] = keccak256("metadata1");
        orgMetadata[1] = keccak256("metadata2");

        // Should revert with EnforcedPause error when trying to create contracts
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        factory.createContractsForFpmm(
            fpmmMarketId,
            groupTokenAddress,
            outcomeIndexes,
            _conditionIds,
            orgNames,
            orgMetadata,
            buildLiquidityOrganizationNames(),
            buildOrganizationMetadataDigests()
        );
    }

    function testRemoveLiquidity() public {
        // Create bet contracts
        uint256[] memory outcomeIndexes = new uint256[](2);
        outcomeIndexes[0] = 0;
        outcomeIndexes[1] = 1;

        factory.createContractsForFpmm(
            fpmmMarketId,
            groupTokenAddress,
            outcomeIndexes,
            conditionIds,
            buildBetContractOrganizationNames(),
            buildOrganizationMetadataDigests(),
            buildLiquidityOrganizationNames(),
            buildOrganizationMetadataDigests()
        );
        // verify liquidity info
        LiquidityInfo memory liquidityInfo = factory.getLiquidityInfo(fpmmMarketId);
        address liquidityAdder = liquidityInfo.liquidityAdder;
        address liquidityRemover = liquidityInfo.liquidityRemover;

        // mint CRC group tokens
        address alice = addresses[0];
        uint256 amount = 1 * CRC;

        mintToGroup(groupTokenAddress, alice, amount);

        // send group CRC tokens to liquidityAdder
        vm.prank(alice);

        // first we add some lp shares
        hub.safeTransferFrom(alice, liquidityAdder, uint256(uint160(group)), amount, "");

        // then we remove the lp shares
        mintToGroup(groupTokenAddress, alice, amount);
        vm.prank(alice);
        hub.safeTransferFrom(alice, liquidityRemover, uint256(uint160(group)), amount, "");

        LiquidityVaultToken liquidityVaultToken = LiquidityVaultToken(liquidityInfo.liquidityVaultToken);
        uint256 lpTokensBalance = liquidityVaultToken.balanceOf(alice, liquidityVaultToken.parseAddress(fpmmMarketId));

        assertTrue(lpTokensBalance == 0);
    }

    function buildBetContractOrganizationNames() private pure returns (string[] memory) {
        string[] memory organizationNames = new string[](2);
        organizationNames[0] = "Organization 1";
        organizationNames[1] = "Organization 2";
        return organizationNames;
    }

    function buildLiquidityOrganizationNames() private pure returns (string[] memory) {
        string[] memory organizationNames = new string[](2);
        organizationNames[0] = "LiquidityAdder";
        organizationNames[1] = "LiquidityRemover";
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
        string[] memory organizationNames = buildBetContractOrganizationNames();
        factory.createContractsForFpmm(
            fpmmMarketId,
            groupTokenAddress,
            outcomeIndexes,
            conditionIds,
            organizationNames,
            organizationMetadataDigests,
            buildLiquidityOrganizationNames(),
            buildOrganizationMetadataDigests()
        );

        // Verify FPMM address is tracked
        assertTrue(factory.fpmmAlreadyProcessed(fpmmMarketId), "FPMM address should be tracked");

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
            organizationMetadataDigests,
            buildLiquidityOrganizationNames(),
            buildOrganizationMetadataDigests()
        );
        // Verify both FPMM addresses are tracked
        assertTrue(factory.fpmmAlreadyProcessed(fpmmMarketId), "First FPMM address should still be tracked");
        assertTrue(factory.fpmmAlreadyProcessed(address(mockFpmm)), "Second FPMM address should be tracked");
    }

    function testCRCRedemption() public {
        // Create bet contracts
        uint256[] memory outcomeIndexes = new uint256[](2);
        outcomeIndexes[0] = 0;
        outcomeIndexes[1] = 1;

        factory.createContractsForFpmm(
            fpmmMarketId,
            groupTokenAddress,
            outcomeIndexes,
            conditionIds,
            buildBetContractOrganizationNames(),
            buildOrganizationMetadataDigests(),
            buildLiquidityOrganizationNames(),
            buildOrganizationMetadataDigests()
        );
        // verify liquidity info
        LiquidityInfo memory liquidityInfo = factory.getLiquidityInfo(fpmmMarketId);

        address liquidityRemover = liquidityInfo.liquidityRemover;

        // mint CRC group tokens
        address alice = addresses[0];
        uint256 amount = 1 * CRC;

        mintToGroup(groupTokenAddress, alice, amount);

        // send group CRC tokens to liquidityAdder
        vm.prank(alice);

        // first we add some lp shares
        uint256 aliceBalanceOfAlice = hub.balanceOf(alice, uint256(uint160(alice)));
        hub.safeTransferFrom(alice, liquidityRemover, uint256(uint160(alice)), amount, "");

        assertTrue(lpTokensBalance == 0);
    }
}
