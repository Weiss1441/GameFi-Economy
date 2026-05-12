// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../../src/vault/GameVault.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockAsset is ERC20 {
    constructor() ERC20("Mock Asset", "MASSET") {
        _mint(msg.sender, 10_000_000 ether);
    }
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract VaultHandler is Test {
    GameVault public vault;
    MockAsset public asset;
    address[] public actors;

    constructor(GameVault _vault, MockAsset _asset) {
        vault = _vault;
        asset = _asset;
        actors.push(address(0xA1));
        actors.push(address(0xA2));
        actors.push(address(0xA3));
    }

    function deposit(uint256 actorSeed, uint256 amount) external {
        address actor = actors[actorSeed % actors.length];
        amount = bound(amount, 1 ether, 10_000 ether);
        asset.mint(actor, amount);
        vm.startPrank(actor);
        asset.approve(address(vault), amount);
        try vault.deposit(amount, actor) {} catch {}
        vm.stopPrank();
    }

    function withdraw(uint256 actorSeed, uint256 shares) external {
        address actor = actors[actorSeed % actors.length];
        uint256 bal = vault.balanceOf(actor);
        if (bal == 0) return;
        shares = bound(shares, 1, bal);
        vm.startPrank(actor);
        try vault.redeem(shares, actor, actor) {} catch {}
        vm.stopPrank();
    }
}

contract GameVaultInvariantTest is Test {
    GameVault public vault;
    MockAsset public asset;
    VaultHandler public handler;

    function setUp() public {
        asset = new MockAsset();
        vault = new GameVault(IERC20(address(asset)));
        handler = new VaultHandler(vault, asset);
        targetContract(address(handler));
    }

    function invariant_total_assets_nonnegative() public view {
        assertGe(vault.totalAssets(), 0);
    }

    function invariant_total_assets_ge_total_supply() public view {
        if (vault.totalSupply() == 0) return;
        assertGe(vault.totalAssets(), vault.totalSupply());
    }
}
