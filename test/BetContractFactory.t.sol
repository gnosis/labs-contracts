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

        // Deploy factory
        factory = new BetContractFactory();

        // Set addresses
        fpmmAddress = address(fpmm);
        groupTokenAddress = address(groupCRCToken);
        hubAddress = address(hub);
    }

    function testFactoryDeployment() public {
        assertEq(address(factory) != address(0), true, "Factory should be deployed");
    }

    function testCreateBetContractsForFpmm() public {
        // Set up event expectations first
        vm.expectEmit(false, true, false, false);
        emit BetContractFactory.BetContractDeployed(address(0), 0);
        vm.expectEmit(false, true, false, false);
        emit BetContractFactory.BetContractDeployed(address(0), 1);

        // Create bet contracts
        factory.createBetContractsForFpmm(fpmmAddress, groupTokenAddress, 0, hubAddress);

        // Get market info
        MarketInfo memory marketInfo = factory.getMarketInfo(fpmmAddress);

        assertEq(marketInfo.fpmmAddress, fpmmAddress, "FPMM address should match");
        assertEq(marketInfo.groupCRCToken, groupTokenAddress, "Group CRC token should match");
        assertEq(marketInfo.outcomeIdxs.length, 2, "Should have 2 outcome indices");
        assertEq(marketInfo.betContracts.length, 2, "Should have 2 bet contracts");

        // Create again to test idempotency
        factory.createBetContractsForFpmm(fpmmAddress, groupTokenAddress, 0, hubAddress);
    }

    function testCannotCreateWithZeroAddresses() public {
        // Test with zero FPMM address
        vm.expectRevert("Invalid FPMM address");
        factory.createBetContractsForFpmm(address(0), groupTokenAddress, 0, hubAddress);

        // Test with zero group CRC token address
        vm.expectRevert("Invalid group CRC token address");
        factory.createBetContractsForFpmm(fpmmAddress, address(0), 0, hubAddress);

        // Test with zero hub address
        vm.expectRevert("Invalid hub address");
        factory.createBetContractsForFpmm(fpmmAddress, groupTokenAddress, 0, address(0));
    }

    function testBetContractCreation() public {
        // Create bet contracts
        factory.createBetContractsForFpmm(fpmmAddress, groupTokenAddress, 0, hubAddress);

        // Get market info
        MarketInfo memory marketInfo = factory.getMarketInfo(fpmmAddress);

        // Verify bet contracts
        for (uint8 i = 0; i < 2; i++) {
            BetContract betContract = BetContract(marketInfo.betContracts[i]);
            assertEq(address(betContract.fpmm()), fpmmAddress, "FPMM address should match");
            assertEq(address(betContract.groupCRCToken()), groupTokenAddress, "Group CRC token should match");
            assertEq(betContract.outcomeIndex(), i, "Outcome index should match");
            assertEq(address(betContract.hub()), hubAddress, "Hub address should match");
        }
    }

    function testFpmmAddressTracking() public {
        // Create bet contracts
        factory.createBetContractsForFpmm(fpmmAddress, groupTokenAddress, 0, hubAddress);

        // Verify FPMM address is tracked
        assertTrue(factory.fpmmAlreadyProcessed(fpmmAddress), "FPMM address should be tracked");

        // Create another market
        address newFpmmAddress = address(2);
        factory.createBetContractsForFpmm(newFpmmAddress, groupTokenAddress, 0, hubAddress);

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
        console.log("inside mock wrap");
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
