// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/NFT/SimpleTreasury.sol";
import "./mocks/MockNFT.sol";

contract SimpleTreasuryTest is Test {
    SimpleTreasury public treasury;
    MockNFT public nft;

    address public owner;
    address public user;
    uint256 public constant INITIAL_BALANCE = 10 ether;

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");

        vm.startPrank(owner);
        nft = new MockNFT();
        treasury = new SimpleTreasury(address(nft));
        vm.stopPrank();

        // Fund treasury
        vm.deal(address(treasury), INITIAL_BALANCE);
    }

    function test_WithdrawWithSufficientNFTs() public {
        // Mint 3 NFTs to user
        vm.startPrank(owner);
        for (uint256 i = 0; i < treasury.requiredNFTBalance(); ++i) {
            nft.mint(user);
        }
        vm.stopPrank();

        // Try to withdraw as user
        vm.prank(user);
        uint256 userBalanceBefore = user.balance;
        treasury.withdraw();

        assertEq(user.balance - userBalanceBefore, INITIAL_BALANCE, "User should receive all treasury balance");
        assertEq(address(treasury).balance, 0, "Treasury should be empty");
    }

    function test_WithdrawWithInsufficientNFTs() public {
        // Mint only 2 NFTs to user
        vm.startPrank(owner);
        nft.mint(user);
        nft.mint(user);
        vm.stopPrank();

        // Try to withdraw as user
        vm.prank(user);
        vm.expectRevert("Insufficient NFT balance");
        treasury.withdraw();
    }

    function test_SetRequiredNFTBalance() public {
        uint256 newRequiredBalance = 5;

        vm.prank(owner);
        treasury.setRequiredNFTBalance(newRequiredBalance);

        assertEq(treasury.requiredNFTBalance(), newRequiredBalance, "Required NFT balance should be updated");
    }

    function test_SetRequiredNFTBalanceNotOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(user)));
        treasury.setRequiredNFTBalance(5);
    }

    function test_ReceiveEther() public {
        uint256 amount = 1 ether;
        vm.deal(user, amount);

        vm.prank(user);
        (bool success,) = address(treasury).call{value: amount}("");

        assertTrue(success, "Should accept ether");
        assertEq(address(treasury).balance, INITIAL_BALANCE + amount, "Treasury balance should increase");
    }
}
