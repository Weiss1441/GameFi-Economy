// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/game/GameItems.sol";
import "../src/game/GameParameters.sol";

contract GameItemsTest is Test {
    GameItems public gameItems;
    GameParameters public gameParams;
    address public owner = address(0x123);
    address public player = address(0x456);
    
    function setUp() public {
        vm.prank(owner);
        gameParams = new GameParameters();
        
        vm.prank(owner);
        gameItems = new GameItems("Game Items", "GITEMS", address(gameParams));
    }
    
    function test_mint_item() public {
        vm.prank(owner);
        gameItems.mint(player, 1, 10, "");
        
        uint256 balance = gameItems.balanceOf(player, 1);
        assertEq(balance, 10);
    }
    
    function test_burn_item() public {
        vm.prank(owner);
        gameItems.mint(player, 1, 5, "");
        
        vm.prank(player);
        gameItems.burn(player, 1, 2);
        
        assertEq(gameItems.balanceOf(player, 1), 3);
    }
    
    function test_craft_item() public {
        vm.prank(owner);
        gameItems.mint(player, 1, 3, "");
        vm.prank(owner);
        gameItems.mint(player, 2, 3, "");
        
        uint256[] memory ingredients = new uint256[](2);
        ingredients[0] = 1;
        ingredients[1] = 2;
        
        vm.prank(player);
        gameItems.craft(ingredients, 3);
        
        assertEq(gameItems.balanceOf(player, 3), 1);
        assertEq(gameItems.balanceOf(player, 1), 2);
        assertEq(gameItems.balanceOf(player, 2), 2);
    }
    
    function test_revert_unauthorized_burn() public {
        vm.prank(owner);
        gameItems.mint(player, 1, 5, "");
        
        vm.prank(address(0x999));
        vm.expectRevert("Not authorized");
        gameItems.burn(player, 1, 1);
    }
}