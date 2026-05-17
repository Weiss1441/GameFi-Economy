// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/vault/GameVaultV1.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock", "MCK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract GameVaultV1Test is Test {
    GameVaultV1 public implementationV1;
    GameVaultV1 public vault;
    ERC1967Proxy public proxy;
    MockToken public asset;

    address public feeRecipient = address(0xFEE);

    function setUp() public {
        asset = new MockToken();
        implementationV1 = new GameVaultV1();
        bytes memory initData = abi.encodeCall(
            GameVaultV1.initialize, (address(asset), "GameFi Vault Shares", "vGFI", 500, feeRecipient, 50)
        );
        proxy = new ERC1967Proxy(address(implementationV1), initData);
        vault = GameVaultV1(address(proxy));
    }

    function test_initialize_sets_values() public view {
        assertEq(vault.yieldRate(), 500);
        assertEq(vault.feeBps(), 50);
        assertEq(vault.feeRecipient(), feeRecipient);
        assertEq(vault.owner(), address(this));
        assertEq(vault.asset(), address(asset));
    }

    function test_owner_can_setYieldRate() public {
        vault.setYieldRate(750);
        assertEq(vault.yieldRate(), 750);
    }

    function test_nonowner_cannot_setYieldRate() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        vault.setYieldRate(600);
    }

    function test_getProjectedAssets_over_year() public view {
        uint256 projected = vault.getProjectedAssets(100 ether, 365 days);
        assertEq(projected, 105 ether);
    }
}
