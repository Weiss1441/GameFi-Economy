// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/game/ResourceAMM.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 ether);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract ResourceAMMTest is Test {
    ResourceAMM public amm;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    address public user = address(0x123);
    address public user2 = address(0x456);

    function setUp() public {
        tokenA = new MockERC20("Token A", "TKNA");
        tokenB = new MockERC20("Token B", "TKNB");

        tokenA.mint(user, 1000 ether);
        tokenB.mint(user, 1000 ether);
        tokenA.mint(user2, 500 ether);
        tokenB.mint(user2, 500 ether);

        vm.startPrank(user);
        amm = new ResourceAMM(address(tokenA), address(tokenB));
        tokenA.approve(address(amm), 1000 ether);
        tokenB.approve(address(amm), 1000 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenA.approve(address(amm), 500 ether);
        tokenB.approve(address(amm), 500 ether);
        vm.stopPrank();
    }

    function test_addLiquidity() public {
        vm.prank(user);
        uint256 shares = amm.addLiquidity(100 ether, 100 ether);

        assertGt(shares, 0);
        (uint256 reserveA, uint256 reserveB) = amm.getReserves();
        assertEq(reserveA, 100 ether);
        assertEq(reserveB, 100 ether);
        assertEq(amm.totalLiquidityShares(), shares);
    }

    function test_swap() public {
        vm.prank(user);
        amm.addLiquidity(100 ether, 100 ether);

        vm.prank(user2);
        uint256 amountOut = amm.swap(address(tokenA), address(tokenB), 10 ether, 1);

        assertGt(amountOut, 0);
        assertLt(amountOut, 10 ether);

        (uint256 reserveA, uint256 reserveB) = amm.getReserves();
        assertEq(reserveA, 110 ether);
        assertApproxEqAbs(reserveB, 100 ether - amountOut, 1e10);
    }

    function test_removeLiquidity() public {
        vm.prank(user);
        uint256 shares = amm.addLiquidity(100 ether, 100 ether);

        vm.prank(user);
        (uint256 amountA, uint256 amountB) = amm.removeLiquidity(shares);

        assertApproxEqAbs(amountA, 100 ether, 1e10);
        assertApproxEqAbs(amountB, 100 ether, 1e10);
        assertEq(amm.totalLiquidityShares(), 0);
    }

    function test_revert_insufficientLiquidity() public {
        vm.prank(user);
        vm.expectRevert("Insufficient output amount");
        amm.swap(address(tokenA), address(tokenB), 10 ether, 0);
    }

    function test_revert_highSlippage() public {
        vm.prank(user);
        amm.addLiquidity(100 ether, 100 ether);

        vm.prank(user2);
        vm.expectRevert("High slippage");
        amm.swap(address(tokenA), address(tokenB), 10 ether, 10 ether);
    }

    function test_getAmountOut() public {
        vm.prank(user);
        amm.addLiquidity(100 ether, 100 ether);

        uint256 amountOut = amm.getAmountOut(10 ether, address(tokenA), address(tokenB));
        assertGt(amountOut, 0);
        assertLt(amountOut, 10 ether);
    }

    function test_gas_sqrtYul() public view {
        uint256 value = 10_000 ether;
        uint256 result = amm.sqrtYul(value);
        assertGt(result, 0);
    }

    function testFuzz_swapInvariant(uint256 amountIn) public {
        vm.assume(amountIn > 0.01 ether && amountIn < 10 ether);

        vm.prank(user);
        amm.addLiquidity(100 ether, 100 ether);

        (uint256 reserveABefore, uint256 reserveBBefore) = amm.getReserves();
        uint256 kBefore = reserveABefore * reserveBBefore;

        vm.prank(user2);
        amm.swap(address(tokenA), address(tokenB), amountIn, 0);

        (uint256 reserveAAfter, uint256 reserveBAfter) = amm.getReserves();
        uint256 kAfter = reserveAAfter * reserveBAfter;

        assertGe(kAfter, kBefore);
    }
}
