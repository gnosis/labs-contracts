// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
//import "circles-v2/errors/Errors.sol";
//import "circles-v2/interfaces/IHub.sol";
import "../lib/circles-contracts-v2/src/errors/Errors.sol";
import {IHubV2} from "../lib/circles-contracts-v2/src/hub/IHub.sol";

contract SetupTrustRelationships is Script {
    IHubV2 public hub;
    address public group = address(0x896905CCD03780C297db3843bcD61673960C0227);
    uint256 constant INDEFINITE_FUTURE = type(uint256).max;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get the Hub address from the environment
        address hubAddress = vm.envAddress("HUB_ADDRESS");
        hub = IHubV2(hubAddress);

        // Create a dummy group
        //group = vm.addr(35); // Using the same address as in the test

        // Register the group
        //vm.prank(group);
        //hub.registerGroup(address(0), "DummyGroup", "DG", bytes32(0));

        // Set up trust relationships
        for (uint256 i = 0; i < 2; i++) {
            address user = vm.addr(i + 1); // First 2 forge addresses (1 and 2)

            // Group trusts user
            //vm.prank(group);
            //hub.trust(user, INDEFINITE_FUTURE);

            // User trusts group
            vm.prank(user);
            //hub.trust(group, INDEFINITE_FUTURE);
        }

        vm.stopBroadcast();
    }
}
