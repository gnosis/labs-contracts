// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/crc_prediction_markets/BetContractFactory.sol";
import "../src/crc_prediction_markets/BetContract.sol";
import "../src/crc_prediction_markets/IFixedProductMarketMaker.sol";
import "../src/crc_prediction_markets/IConditionalTokens.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "circles-v2/lift/IERC20Lift.sol";
import "../test/mocks/MockFixedProductMarketMaker.sol";
import "../test/mocks/MockHubCRCPMs.sol";
import "../test/mocks/MockConditionalTokens.sol";
import "../test/mocks/MockERC20.sol";

contract BetContractFactoryTest is Test {
    BetContractFactory factory;
    MockFixedProductMarketMaker fpmm;
    address groupCRCToken;
    MockHubCRCPMs hub;
    address fpmmAddress;
    address groupTokenAddress;
    address hubAddress;

    uint256 constant TOKEN_ID = 1;
    uint256 constant AMOUNT = 100;
    uint256 constant OUTCOME_SLOT_COUNT = 2;
    uint256 constant CONDITION_ID = 1;

    bytes32[] conditionIds;

    function setUp() public {
        // Deploy mock contracts

        MockERC20 mockToken = new MockERC20("Test Token", "TEST");
        groupCRCToken = address(mockToken);
        hub = new MockHubCRCPMs();
        //fpmm = IFixedProductMarketMaker(address(new MockPartialFixedProductMarketMaker()));
        fpmm = new MockFixedProductMarketMaker(address(groupCRCToken), OUTCOME_SLOT_COUNT, CONDITION_ID);

        // Set addresses
        fpmmAddress = address(fpmm);
        groupTokenAddress = address(groupCRCToken);
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

    function testCreateBetContractsForFpmm() public {
        // Create bet contracts
        uint256[] memory outcomeIndexes = new uint256[](2);
        outcomeIndexes[0] = 0;
        outcomeIndexes[1] = 1;

        // Record events
        vm.recordLogs();
        factory.createBetContractsForFpmm(
            fpmmAddress,
            groupTokenAddress,
            outcomeIndexes,
            conditionIds,
            buildOrganizationNames(),
            buildOrganizationMetadataDigests()
        );
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // Check that we have the expected number of events
        assertEq(entries.length, 2, "Should emit 2 BetContractDeployed events");

        // Get market info
        MarketInfo memory marketInfo = factory.getMarketInfo(fpmmAddress);

        assertEq(marketInfo.fpmmAddress, fpmmAddress, "FPMM address should match");
        assertEq(marketInfo.groupCRCToken, groupTokenAddress, "Group CRC token should match");
        assertEq(marketInfo.outcomeIdxs.length, 2, "Should have 2 outcome indices");
        assertEq(marketInfo.betContracts.length, 2, "Should have 2 bet contracts");

        // Create again to test idempotency
        outcomeIndexes = buildOutcomeIndicesArray(0);

        factory.createBetContractsForFpmm(
            fpmmAddress,
            groupTokenAddress,
            outcomeIndexes,
            conditionIds,
            buildOrganizationNames(),
            buildOrganizationMetadataDigests()
        );
    }

    function testCannotCreateWithZeroAddresses() public {
        // Test with zero FPMM address
        console.log("testCannotCreateWithZeroAddresses");
        vm.expectRevert("Invalid FPMM address");
        uint256[] memory outcomeIndexes = buildOutcomeIndicesArray(0);
        bytes32[] memory organizationMetadataDigests = buildOrganizationMetadataDigests();
        string[] memory organizationNames = buildOrganizationNames();
        factory.createBetContractsForFpmm(
            address(0), groupTokenAddress, outcomeIndexes, conditionIds, organizationNames, organizationMetadataDigests
        );
        console.log("first test passed");
        // Test with zero group CRC token address
        vm.expectRevert("Invalid group CRC token address");

        factory.createBetContractsForFpmm(
            fpmmAddress, address(0), outcomeIndexes, conditionIds, organizationNames, organizationMetadataDigests
        );
    }

    function testBetContractCreation() public {
        // Create bet contracts
        uint256[] memory outcomeIndexes = new uint256[](2);
        outcomeIndexes[0] = 0;
        outcomeIndexes[1] = 1;

        factory.createBetContractsForFpmm(
            fpmmAddress,
            groupTokenAddress,
            outcomeIndexes,
            conditionIds,
            buildOrganizationNames(),
            buildOrganizationMetadataDigests()
        );
        console.log("after fpmm creation");
        // Get market info
        MarketInfo memory marketInfo = factory.getMarketInfo(fpmmAddress);

        console.log("1 testBetContractCreation");

        // Verify bet contracts
        for (uint256 i = 0; i < 2; i++) {
            BetContract betContract = BetContract(marketInfo.betContracts[i]);
            console.log("2");
            assertEq(address(betContract.fpmm()), fpmmAddress, "FPMM address should match");
            assertEq(address(betContract.groupCRCToken()), groupTokenAddress, "Group CRC token should match");
            assertEq(betContract.outcomeIndex(), i, "Outcome index should match");
            assertEq(address(betContract.hub()), hubAddress, "Hub address should match");
        }
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
        factory.createBetContractsForFpmm(
            fpmmAddress, groupTokenAddress, outcomeIndexes, conditionIds, organizationNames, organizationMetadataDigests
        );
        console.log("after create bet contract");

        // Verify FPMM address is tracked
        assertTrue(factory.fpmmAlreadyProcessed(fpmmAddress), "FPMM address should be tracked");
        console.log("after first verify");

        // Create another market
        MockFixedProductMarketMaker mockFpmm =
            new MockFixedProductMarketMaker(address(groupCRCToken), OUTCOME_SLOT_COUNT, CONDITION_ID);

        outcomeIndexes = new uint256[](2);
        outcomeIndexes[0] = uint256(0);
        outcomeIndexes[1] = uint256(1);

        factory.createBetContractsForFpmm(
            address(mockFpmm),
            groupTokenAddress,
            outcomeIndexes,
            conditionIds,
            organizationNames,
            organizationMetadataDigests
        );
        console.log("before assert");
        // Verify both FPMM addresses are tracked
        assertTrue(factory.fpmmAlreadyProcessed(fpmmAddress), "First FPMM address should still be tracked");
        console.log("after first assert");
        assertTrue(factory.fpmmAlreadyProcessed(address(mockFpmm)), "Second FPMM address should be tracked");
    }
}
