// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/crc_prediction_markets/BetContractFactory.sol";
import "../src/crc_prediction_markets/BetContract.sol";
import "../src/crc_prediction_markets/IFixedProductMarketMaker.sol";
import "../src/crc_prediction_markets/IConditionalTokens.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "circles-v2/hub/Hub.sol";
import {CirclesType} from "circles-v2/lift/IERC20Lift.sol";

contract BetContractFactoryTest is Test {
    BetContractFactory factory;
    IFixedProductMarketMaker fpmm;
    address groupCRCToken;
    MockHub hub;
    address fpmmAddress;
    address groupTokenAddress;
    address hubAddress;

    function setUp() public {
        // Deploy mock contracts
        fpmm = IFixedProductMarketMaker(address(new MockFixedProductMarketMaker()));
        MockERC20 mockToken = new MockERC20("Test Token", "TEST");
        groupCRCToken = address(mockToken);
        hub = MockHub(address(new MockHub()));

        // Set addresses
        fpmmAddress = address(fpmm);
        groupTokenAddress = address(groupCRCToken);
        hubAddress = address(hub);

        // Deploy factory
        factory = new BetContractFactory(hubAddress);
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
        factory.createBetContractsForFpmm(fpmmAddress, groupTokenAddress, outcomeIndexes);
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
        factory.createBetContractsForFpmm(fpmmAddress, groupTokenAddress, outcomeIndexes);
    }

    function testCannotCreateWithZeroAddresses() public {
        // Test with zero FPMM address
        vm.expectRevert("Invalid FPMM address");
        uint256[] memory outcomeIndexes = buildOutcomeIndicesArray(0);
        factory.createBetContractsForFpmm(address(0), groupTokenAddress, outcomeIndexes);

        // Test with zero group CRC token address
        vm.expectRevert("Invalid group CRC token address");

        factory.createBetContractsForFpmm(fpmmAddress, address(0), outcomeIndexes);
    }

    function testBetContractCreation() public {
        // Create bet contracts
        uint256[] memory outcomeIndexes = new uint256[](2);
        outcomeIndexes[0] = 0;
        outcomeIndexes[1] = 1;

        factory.createBetContractsForFpmm(fpmmAddress, groupTokenAddress, outcomeIndexes);

        // Get market info
        MarketInfo memory marketInfo = factory.getMarketInfo(fpmmAddress);

        // Verify bet contracts
        for (uint256 i = 0; i < 2; i++) {
            BetContract betContract = BetContract(marketInfo.betContracts[i]);
            assertEq(address(betContract.fpmm()), fpmmAddress, "FPMM address should match");
            assertEq(address(betContract.groupCRCToken()), groupTokenAddress, "Group CRC token should match");
            assertEq(betContract.outcomeIndex(), i, "Outcome index should match");
            assertEq(address(betContract.hub()), hubAddress, "Hub address should match");
        }
    }

    function testFpmmAddressTracking() public {
        // Create bet contracts
        uint256[] memory outcomeIndexes = buildOutcomeIndicesArray(0);
        factory.createBetContractsForFpmm(fpmmAddress, groupTokenAddress, outcomeIndexes);

        // Verify FPMM address is tracked
        assertTrue(factory.fpmmAlreadyProcessed(fpmmAddress), "FPMM address should be tracked");

        // Create another market
        address newFpmmAddress = address(2);

        outcomeIndexes = new uint256[](2);
        outcomeIndexes[0] = uint256(0);
        outcomeIndexes[1] = uint256(1);
        factory.createBetContractsForFpmm(newFpmmAddress, groupTokenAddress, outcomeIndexes);

        // Verify both FPMM addresses are tracked
        assertTrue(factory.fpmmAlreadyProcessed(fpmmAddress), "First FPMM address should still be tracked");
        assertTrue(factory.fpmmAlreadyProcessed(newFpmmAddress), "Second FPMM address should be tracked");
    }
}

// Mock contracts
contract MockFixedProductMarketMaker {
    IConditionalTokens public conditionalTokens;

    constructor() {
        conditionalTokens = IConditionalTokens(address(new MockConditionalTokens()));
    }
}

contract MockConditionalTokens {
    function redeemPositions(IERC20, bytes32, bytes32, uint256[] memory) external pure {
        // Mock implementation
    }
}

contract MockHub {
    address public wrappedToken;

    function wrap(address token, uint256 amount, CirclesType _type) external returns (address) {
        require(token != address(0), "Invalid token address");
        //require(amount > 0, "Amount must be greater than 0");

        // For testing purposes, we'll just return the same token address
        wrappedToken = token;
        return token;
    }

    function trust(address _trustReceiver, uint96 _expiry) external {
        // do nothing
    }

    function registerOrganization(string memory, /*orgaName*/ bytes32 /*identifier*/ ) external {
        // No-op for testing
    }
}

// mock ERC20
contract MockERC20 {
    constructor(string memory name, string memory symbol) {}
}
