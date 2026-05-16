// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/vault/GameVault.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, 1_000_000 ether);
    }
}

contract GameVaultTest is Test {
    GameVault public vault;
    MockERC20 public asset;
    address public user = address(0x123);
    address public owner = address(0x456);

    function setUp() public {
        asset = new MockERC20();

        vm.prank(owner);
        vault = new GameVault(asset);

        asset.transfer(user, 1000 ether);

        vm.startPrank(user);
        asset.approve(address(vault), 1000 ether);
        vm.stopPrank();
    }

    function test_deposit() public {
        vm.prank(user);
        uint256 shares = vault.deposit(100 ether, user);

        assertEq(shares, 100 ether);
        assertEq(vault.balanceOf(user), 100 ether);
        assertEq(vault.totalAssets(), 100 ether);
    }

    function test_withdraw() public {
        vm.prank(user);
        vault.deposit(100 ether, user);

        vm.prank(user);
        uint256 assets = vault.redeem(100 ether, user, user);

        assertEq(assets, 100 ether);
        assertEq(vault.balanceOf(user), 0);
    }

    function test_setYieldRate() public {
        vm.prank(owner);
        vault.setYieldRate(1000); // 10%

        assertEq(vault.yieldRate(), 1000);
    }

    function test_revert_nonOwner_setYieldRate() public {
        vm.prank(user);
        vm.expectRevert();
        vault.setYieldRate(1000);
    }

    function testFuzz_depositWithdraw(uint256 amount) public {
        vm.assume(amount >= 0.01 ether && amount <= 1000 ether);

        vm.prank(user);
        uint256 shares = vault.deposit(amount, user);

        assertEq(shares, amount);

        vm.prank(user);
        uint256 assets = vault.redeem(shares, user, user);

        assertEq(assets, amount);
    }

    function test_getProjectedAssets() public {
        uint256 projected = vault.getProjectedAssets(100 ether, 365 days);
        // 100 + 5% = 105 ether
        assertApproxEqAbs(projected, 105 ether, 1e15);
    }
}
