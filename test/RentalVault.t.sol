// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/game/RentalVault.sol";
import "../src/game/GameItems.sol";
import "../src/game/GameParameters.sol";

contract RentalVaultTest is Test {
    RentalVault public rentalVault;
    GameItems public gameItems;
    GameParameters public gameParams;
    
    address public owner = address(0x123);
    address public player = address(0x456);
    address public renter = address(0x789);
    
    uint256 public tokenId = 1;
    uint256 public amount = 5;
    
    function setUp() public {
        vm.prank(owner);
        gameParams = new GameParameters();
        
        vm.prank(owner);
        gameItems = new GameItems("Test Items", "TEST", address(gameParams));
        
        vm.prank(owner);
        rentalVault = new RentalVault(address(gameItems));
        
        
        vm.prank(owner);
        gameItems.mint(player, tokenId, amount, "");
        
        
        vm.prank(player);
        gameItems.setApprovalForAll(address(rentalVault), true);
    }
    
    function test_deposit() public {
        vm.prank(player);
        rentalVault.deposit(tokenId, amount);
        
        assertEq(rentalVault.depositedAmounts(tokenId), amount);
    }
    
    function test_rent() public {
        vm.prank(player);
        rentalVault.deposit(tokenId, amount);
        
        vm.prank(player);
        rentalVault.rent(tokenId, renter, 7 days);
        
        assertTrue(rentalVault.isRented(tokenId));
    }
    
    function test_reclaim() public {
        vm.prank(player);
        rentalVault.deposit(tokenId, amount);
        
        vm.prank(player);
        rentalVault.rent(tokenId, renter, 1 days);
        
        
        vm.warp(block.timestamp + 2 days);
        
        vm.prank(player);
        rentalVault.reclaim(tokenId);
        
        assertEq(rentalVault.depositedAmounts(tokenId), 0);
        assertFalse(rentalVault.isRented(tokenId));
    }
    
    function test_revert_notOwnerReclaim() public {
        vm.prank(player);
        rentalVault.deposit(tokenId, amount);
        
        vm.prank(renter);
        vm.expectRevert("Not the owner");
        rentalVault.reclaim(tokenId);
    }
    
    function test_returnNft() public {
        vm.prank(player);
        rentalVault.deposit(tokenId, amount);
        
        vm.prank(player);
        rentalVault.rent(tokenId, renter, 7 days);
        
        vm.prank(renter);
        rentalVault.returnNft(tokenId);
        
        assertFalse(rentalVault.isRented(tokenId));
    }
}