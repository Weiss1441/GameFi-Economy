// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/vault/GameVaultV1.sol";
import "../src/vault/GameVaultV2.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock Resource", "mRES") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract GameVaultUUPSTest is Test {
    MockToken public asset;
    GameVaultV1 public implementationV1;
    GameVaultV2 public implementationV2;
    ERC1967Proxy public proxy;
    GameVaultV1 public vaultV1;
    GameVaultV2 public vaultV2;

    address public owner = address(this);
    address public feeRecipient = address(0xFEE);
    address public alice = address(0xA11CE);

    function setUp() public {
        asset = new MockToken();
        implementationV1 = new GameVaultV1();
        bytes memory initData =
            abi.encodeCall(GameVaultV1.initialize, (address(asset), "GameFi Vault", "gvGFI", 500, feeRecipient, 50));
        proxy = new ERC1967Proxy(address(implementationV1), initData);
        vaultV1 = GameVaultV1(address(proxy));
    }

    function testInitialized() public view {
        assertEq(vaultV1.yieldRate(), 500);
        assertEq(vaultV1.feeBps(), 50);
        assertEq(vaultV1.feeRecipient(), feeRecipient);
        assertEq(vaultV1.owner(), owner);
        assertEq(vaultV1.asset(), address(asset));
    }

    function testCannotInitializeTwice() public {
        vm.expectRevert();
        vaultV1.initialize(address(asset), "X", "Y", 100, feeRecipient, 10);
    }

    function testDeposit() public {
        uint256 amount = 1000 ether;
        asset.mint(alice, amount);
        vm.startPrank(alice);
        asset.approve(address(proxy), amount);
        uint256 shares = vaultV1.deposit(amount, alice);
        vm.stopPrank();
        assertGt(shares, 0);
        assertEq(asset.balanceOf(feeRecipient), 5 ether);
        assertEq(vaultV1.balanceOf(alice), shares);
    }

    function testDepositZeroReverts() public {
        vm.expectRevert(GameVaultV1.ZeroAmount.selector);
        vaultV1.deposit(0, alice);
    }

    function testWithdraw() public {
        uint256 amount = 1000 ether;
        asset.mint(alice, amount);
        vm.startPrank(alice);
        asset.approve(address(proxy), amount);
        vaultV1.deposit(amount, alice);
        uint256 sharesBefore = vaultV1.balanceOf(alice);
        assertGt(sharesBefore, 0);
        uint256 withdrawAmount = 400 ether;
        vaultV1.withdraw(withdrawAmount, alice, alice);
        vm.stopPrank();
        assertEq(asset.balanceOf(alice), withdrawAmount);
    }

    function testSetYieldRate() public {
        vaultV1.setYieldRate(750);
        assertEq(vaultV1.yieldRate(), 750);
    }

    function testSetYieldRateTooHighReverts() public {
        vm.expectRevert(abi.encodeWithSelector(GameVaultV1.YieldRateTooHigh.selector, 99999, 10000));
        vaultV1.setYieldRate(99999);
    }

    function testSetYieldRateNonOwnerReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        vaultV1.setYieldRate(999);
    }

    function testSetFeeBps() public {
        vaultV1.setFeeBps(100);
        assertEq(vaultV1.feeBps(), 100);
    }

    function testSetFeeRecipient() public {
        vaultV1.setFeeRecipient(alice);
        assertEq(vaultV1.feeRecipient(), alice);
    }

    function testSetFeeRecipientZeroReverts() public {
        vm.expectRevert(GameVaultV1.ZeroAddress.selector);
        vaultV1.setFeeRecipient(address(0));
    }

    function testUpgradeToV2() public {
        vaultV1.setYieldRate(750);
        implementationV2 = new GameVaultV2();
        GameVaultV1(address(proxy))
            .upgradeToAndCall(address(implementationV2), abi.encodeCall(GameVaultV2.initializeV2, (1000)));
        vaultV2 = GameVaultV2(address(proxy));
        assertEq(vaultV2.yieldRate(), 750);
        assertEq(vaultV2.owner(), owner);
        assertEq(vaultV2.feeBps(), 50);
        assertEq(vaultV2.reserveRatioBps(), 1000);
        assertEq(vaultV2.getReserveAdjustedAssets(10_000 ether), 9000 ether);
    }

    function testV2DepositTracksStakeDuration() public {
        implementationV2 = new GameVaultV2();
        GameVaultV1(address(proxy))
            .upgradeToAndCall(address(implementationV2), abi.encodeCall(GameVaultV2.initializeV2, (0)));
        vaultV2 = GameVaultV2(address(proxy));

        uint256 amount = 1000 ether;
        asset.mint(alice, amount);
        vm.startPrank(alice);
        asset.approve(address(proxy), amount);
        vaultV2.deposit(amount, alice);
        vm.stopPrank();

        assertEq(vaultV2.getStakeDuration(address(0xCAFE)), 0);
        assertEq(vaultV2.stakedAt(alice), block.timestamp);

        vm.warp(block.timestamp + 3 days);
        assertEq(vaultV2.getStakeDuration(alice), 3 days);
    }

    function testV2SetReserveRatio() public {
        implementationV2 = new GameVaultV2();
        GameVaultV1(address(proxy))
            .upgradeToAndCall(address(implementationV2), abi.encodeCall(GameVaultV2.initializeV2, (500)));
        vaultV2 = GameVaultV2(address(proxy));

        vaultV2.setReserveRatio(2500);
        assertEq(vaultV2.reserveRatioBps(), 2500);
        assertEq(vaultV2.getReserveAdjustedAssets(10_000 ether), 7500 ether);
    }

    function testV2ReserveRatioTooHighReverts() public {
        implementationV2 = new GameVaultV2();
        GameVaultV1(address(proxy))
            .upgradeToAndCall(address(implementationV2), abi.encodeCall(GameVaultV2.initializeV2, (500)));
        vaultV2 = GameVaultV2(address(proxy));

        vm.expectRevert(abi.encodeWithSelector(GameVaultV2.ReserveRatioTooHigh.selector, 5001, 5000));
        vaultV2.setReserveRatio(5001);
    }

    function testV2InitializeReserveRatioTooHighReverts() public {
        implementationV2 = new GameVaultV2();
        vm.expectRevert(abi.encodeWithSelector(GameVaultV2.ReserveRatioTooHigh.selector, 5001, 5000));
        GameVaultV1(address(proxy))
            .upgradeToAndCall(address(implementationV2), abi.encodeCall(GameVaultV2.initializeV2, (5001)));
    }

    function testUpgradeFailsForNonOwner() public {
        implementationV2 = new GameVaultV2();
        vm.prank(alice);
        vm.expectRevert();
        GameVaultV1(address(proxy)).upgradeToAndCall(address(implementationV2), "");
    }

    function testStoragePreservedAfterUpgrade() public {
        uint256 amount = 1000 ether;
        asset.mint(alice, amount);
        vm.startPrank(alice);
        asset.approve(address(proxy), amount);
        vaultV1.deposit(amount, alice);
        vm.stopPrank();
        uint256 sharesBefore = vaultV1.balanceOf(alice);
        implementationV2 = new GameVaultV2();
        GameVaultV1(address(proxy))
            .upgradeToAndCall(address(implementationV2), abi.encodeCall(GameVaultV2.initializeV2, (500)));
        vaultV2 = GameVaultV2(address(proxy));
        assertEq(vaultV2.balanceOf(alice), sharesBefore);
        assertGt(vaultV2.totalFeesCollected(), 0);
    }

    function testGetProjectedAssets() public view {
        uint256 projected = vaultV1.getProjectedAssets(1000 ether, 365 days);
        assertEq(projected, 1050 ether);
    }

    function testFuzz_deposit(uint256 amount) public {
        vm.assume(amount > 0.01 ether && amount < 100_000 ether);
        asset.mint(alice, amount);
        vm.startPrank(alice);
        asset.approve(address(proxy), amount);
        uint256 shares = vaultV1.deposit(amount, alice);
        vm.stopPrank();
        assertGt(shares, 0);
        assertEq(vaultV1.balanceOf(alice), shares);
    }

    function testFuzz_withdraw(uint256 amount) public {
        vm.assume(amount > 1 ether && amount < 100_000 ether);
        asset.mint(alice, amount);
        vm.startPrank(alice);
        asset.approve(address(proxy), amount);
        vaultV1.deposit(amount, alice);
        uint256 shares = vaultV1.balanceOf(alice);
        uint256 assets = vaultV1.convertToAssets(shares);
        vaultV1.withdraw(assets, alice, alice);
        vm.stopPrank();
        assertEq(vaultV1.balanceOf(alice), 0);
    }

    function testFuzz_feeBpsNeverExceedsMax(uint256 feeBps) public {
        vm.assume(feeBps <= 1000);
        vaultV1.setFeeBps(feeBps);
        assertEq(vaultV1.feeBps(), feeBps);
        assertLe(vaultV1.feeBps(), vaultV1.MAX_FEE_BPS());
    }
}
