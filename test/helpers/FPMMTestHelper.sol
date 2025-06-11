// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "circles-v2-test/groups/groupSetup.sol";
import "circles-v2/errors/Errors.sol";
import "../mocks/MockFixedProductMarketMaker.sol";
import "../../src/crc_prediction_markets/LiquidityVaultToken.sol";
import "../../src/crc_prediction_markets/BetContract.sol";

contract FPMMTestHelper is Test, GroupSetup, IHubErrors {
    // Constants
    uint256 public constant OUTCOME_SLOT_COUNT = 2;
    uint256 public constant CONDITION_ID = 1;
    uint256 public constant MOCK_OUTCOME_INDEX = 0;

    // Public state variables for test contracts to access
    address public group;
    address public fpmmMarketId;
    LiquidityVaultToken public liquidityVaultToken;
    address public erc20Group;

    // Setup function to be called by child contracts
    function _setupFPMMEnvironment() internal {
        // Setup group
        groupSetup();
        group = addresses[35];

        // Register group
        vm.prank(group);
        hub.registerGroup(mintPolicy, "TestGroup", "TG", bytes32(0));

        // Setup trust relationships
        _setupTrustRelationships();

        // Get ERC20 group token
        erc20Group = hub.wrap(address(group), 0, CirclesType.Inflation);

        // Deploy mock FPMM
        MockFixedProductMarketMaker mockFPMM =
            new MockFixedProductMarketMaker(address(erc20Group), OUTCOME_SLOT_COUNT, CONDITION_ID);
        fpmmMarketId = address(mockFPMM);

        // Deploy LiquidityVaultToken
        liquidityVaultToken = new LiquidityVaultToken();
    }

    // Helper to setup trust relationships
    function _setupTrustRelationships() internal {
        // Group trusts first 5 humans and vice versa
        for (uint256 i = 0; i < 5; i++) {
            // Group trusts human
            vm.prank(group);
            hub.trust(addresses[i], INDEFINITE_FUTURE);

            // Human trusts group
            vm.prank(addresses[i]);
            hub.trust(group, INDEFINITE_FUTURE);
        }
    }

    // Helper to create a new BetContract instance
    function deployBetContract(string memory organizationName, bytes32 organizationId) public returns (BetContract) {
        return new BetContract(
            fpmmMarketId,
            group,
            MOCK_OUTCOME_INDEX,
            address(hub),
            1, // tokenId
            organizationName,
            organizationId,
            address(liquidityVaultToken)
        );
    }

    // Helper to mint tokens to a group
    function mintToGroup(address _group, address minter, uint256 amount) public {
        address[] memory avatars = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        avatars[0] = minter;
        amounts[0] = amount;
        vm.prank(minter);
        hub.groupMint(_group, avatars, amounts, "");
    }
}
