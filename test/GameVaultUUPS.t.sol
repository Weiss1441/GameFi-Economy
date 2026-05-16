// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/vault/GameVaultV1.sol";
import "../src/vault/GameVaultV2.sol";

contract GameVaultUUPSTest is Test {
    GameVaultV1 public implementationV1;
    GameVaultV2 public implementationV2;
    ERC1967Proxy public proxy;
    GameVaultV1 public vaultV1;
    GameVaultV2 public vaultV2;

    function setUp() public {
        implementationV1 = new GameVaultV1();
        bytes memory initData = abi.encodeWithSelector(GameVaultV1.initialize.selector, "GameFi Vault Shares", "vGFI", 500);
        proxy = new ERC1967Proxy(address(implementationV1), initData);
        vaultV1 = GameVaultV1(address(proxy));
    }

    function testInitializeAndUpgradeVault() public {
        assertEq(vaultV1.yieldRate(), 500);
        assertEq(vaultV1.owner(), address(this));

        vaultV1.setYieldRate(750);
        assertEq(vaultV1.yieldRate(), 750);

        implementationV2 = new GameVaultV2();
        vm.prank(address(this));
        GameVaultV1(address(proxy)).upgradeToAndCall(address(implementationV2), "");

        vaultV2 = GameVaultV2(address(proxy));
        assertEq(vaultV2.yieldRate(), 750);
        assertEq(vaultV2.owner(), address(this));

        vaultV2.setReserveRatio(1000);
        assertEq(vaultV2.reserveRatioBps(), 1000);
        assertEq(vaultV2.getReserveAdjustedAssets(10_000 ether), 9000 ether);
    }

    function testUpgradeFailsForNonOwner() public {
        implementationV2 = new GameVaultV2();
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        GameVaultV1(address(proxy)).upgradeToAndCall(address(implementationV2), "");
    }
}
