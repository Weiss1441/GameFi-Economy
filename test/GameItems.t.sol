// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../src/game/GameItems.sol";
import "../src/game/GameParameters.sol";

contract GameItemsTest is Test {
    GameItems public gameItems;
    GameParameters public gameParams;
    address public owner = address(0x123);
    address public player = address(0x456);
    address public player2 = address(0x789);

    function setUp() public {
        vm.prank(owner);
        gameParams = new GameParameters();
        vm.prank(owner);
        gameItems = new GameItems("Game Items", "GITEMS", address(gameParams));
    }

    function test_mint_item() public {
        vm.prank(owner);
        gameItems.mint(player, 1, 10, "");
        assertEq(gameItems.balanceOf(player, 1), 10);
    }

    function test_metadata_and_gameParams() public view {
        assertEq(gameItems.name(), "Game Items");
        assertEq(gameItems.symbol(), "GITEMS");
        assertEq(address(gameItems.gameParams()), address(gameParams));
    }

    function test_mintFromVRF() public {
        vm.prank(owner);
        gameItems.mintFromVRF(player, 4);
        assertEq(gameItems.balanceOf(player, 4), 1);
    }

    function test_revert_mintFromVRF_invalidReceiver() public {
        vm.prank(owner);
        vm.expectRevert("Invalid receiver");
        gameItems.mintFromVRF(address(0), 4);
    }

    function test_revert_unauthorized_mintFromVRF() public {
        vm.prank(player);
        vm.expectRevert();
        gameItems.mintFromVRF(player, 4);
    }

    function test_revert_unauthorized_mint() public {
        vm.prank(player);
        vm.expectRevert();
        gameItems.mint(player, 1, 10, "");
    }

    function test_burn_item() public {
        vm.prank(owner);
        gameItems.mint(player, 1, 5, "");
        vm.prank(player);
        gameItems.burn(player, 1, 2);
        assertEq(gameItems.balanceOf(player, 1), 3);
    }

    function test_revert_unauthorized_burn() public {
        vm.prank(owner);
        gameItems.mint(player, 1, 5, "");
        vm.prank(address(0x999));
        vm.expectRevert("Not authorized");
        gameItems.burn(player, 1, 1);
    }

    function test_approved_operator_can_burn() public {
        vm.prank(owner);
        gameItems.mint(player, 1, 5, "");
        vm.prank(player);
        gameItems.setApprovalForAll(player2, true);
        vm.prank(player2);
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

    function test_revert_craft_no_ingredients() public {
        uint256[] memory ingredients = new uint256[](0);
        vm.prank(player);
        vm.expectRevert("No ingredients");
        gameItems.craft(ingredients, 3);
    }

    function test_setCraftingRecipe() public {
        uint256[] memory ingredients = new uint256[](2);
        ingredients[0] = 1;
        ingredients[1] = 2;

        vm.prank(owner);
        gameItems.setCraftingRecipe(ingredients, 5);

        assertEq(gameItems.craftingRecipes(5, 0), 1);
        assertEq(gameItems.craftingRecipes(5, 1), 2);
        assertEq(gameItems.recipeResults(uint256(keccak256(abi.encodePacked(ingredients)))), 5);
    }

    function test_revert_nonAdminSetCraftingRecipe() public {
        uint256[] memory ingredients = new uint256[](1);
        ingredients[0] = 1;

        vm.prank(player);
        vm.expectRevert();
        gameItems.setCraftingRecipe(ingredients, 5);
    }

    function test_uri_format() public view {
        string memory uri = gameItems.uri(42);
        assertEq(uri, "https://api.gamefi.com/items/42.json");
    }

    function test_supportsInterfaces() public view {
        assertTrue(gameItems.supportsInterface(type(IERC165).interfaceId));
        assertTrue(gameItems.supportsInterface(type(IAccessControl).interfaceId));
    }

    function testFuzz_mint_amount(uint256 amount) public {
        amount = bound(amount, 1, 1_000_000);
        vm.prank(owner);
        gameItems.mint(player, 1, amount, "");
        assertEq(gameItems.balanceOf(player, 1), amount);
    }
}
