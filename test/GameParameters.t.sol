// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/game/GameParameters.sol";

contract GameParametersTest is Test {
    GameParameters public gameParams;
    address public owner = address(0x123);
    address public nonOwner = address(0x456);
    
    function setUp() public {
        vm.prank(owner);
        gameParams = new GameParameters();
    }
    
    function test_setDropRate() public {
        vm.prank(owner);
        gameParams.setDropRate(1, 5000);
        
        uint256 rate = gameParams.getDropRate(1);
        assertEq(rate, 5000);
    }
    
    function test_setCraftingCost() public {
        vm.prank(owner);
        gameParams.setCraftingCost(1, 100 ether);
        
        uint256 cost = gameParams.getCraftingCost(1);
        assertEq(cost, 100 ether);
    }
    
    function test_revert_nonOwner_setDropRate() public {
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        gameParams.setDropRate(1, 5000);
    }
    
    function test_revert_rateExceedsMax() public {
        vm.prank(owner);
        vm.expectRevert("Rate exceeds max");
        gameParams.setDropRate(1, 10001);
    }
    
    function test_setMultipleDropRates() public {
        uint256[] memory itemIds = new uint256[](3);
        itemIds[0] = 1;
        itemIds[1] = 2;
        itemIds[2] = 3;
        
        uint256[] memory rates = new uint256[](3);
        rates[0] = 5000;
        rates[1] = 3000;
        rates[2] = 2000;
        
        vm.prank(owner);
        gameParams.setMultipleDropRates(itemIds, rates);
        
        assertEq(gameParams.getDropRate(1), 5000);
        assertEq(gameParams.getDropRate(2), 3000);
        assertEq(gameParams.getDropRate(3), 2000);
    }
}