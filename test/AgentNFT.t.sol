// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import {AgentNFT} from "../src/NFT/AgentNFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AgentNFTTest is Test {
    AgentNFT public agentNFT;
    uint256 public maxSupply = 5;
    address public owner = address(this);
    address public user = address(0x123);

    function setUp() public {
        agentNFT = new AgentNFT(maxSupply);
    }

    function testOwnerIsDeployer() public {
        assertEq(agentNFT.owner(), owner, "Owner should be deployer");
    }

    function testMintByOwner() public {
        agentNFT.safeMint(user);

        // Check that the token was minted correctly
        assertEq(agentNFT.ownerOf(0), user, "User should own token 0");
    }

    function testMintByNonOwner() public {
        // Expect a revert when a non-owner tries to mint
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(user)));
        agentNFT.safeMint(user);
    }

    function testIncrementTokenId() public {
        // Mint two tokens to ensure tokenId increments
        agentNFT.safeMint(user);
        agentNFT.safeMint(user);

        assertEq(agentNFT.ownerOf(0), user, "User should own token 0");
        assertEq(agentNFT.ownerOf(1), user, "User should own token 1");
    }

    // Test that the max supply is reached
    function testMaxSupplyReached() public {
        // mint 5 times
        agentNFT.safeMint(user);
        agentNFT.safeMint(user);
        agentNFT.safeMint(user);
        agentNFT.safeMint(user);
        agentNFT.safeMint(user);
        // expect a revert
        vm.expectRevert("Max supply reached");
        agentNFT.safeMint(user);
    }
}
