// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../../src/game/ResourceAMM.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1_000_000 ether);
    }
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract AMMHandler is Test {
    ResourceAMM public amm;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    address public actor = address(0xBEEF);

    constructor(ResourceAMM _amm, MockERC20 _tokenA, MockERC20 _tokenB) {
        amm = _amm;
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function swap(uint256 amountIn) external {
        amountIn = bound(amountIn, 1e15, 100 ether);
        tokenA.mint(actor, amountIn);
        vm.startPrank(actor);
        tokenA.approve(address(amm), amountIn);
        try amm.swap(address(tokenA), address(tokenB), amountIn) {} catch {}
        vm.stopPrank();
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        amountA = bound(amountA, 1 ether, 1000 ether);
        amountB = bound(amountB, 1 ether, 1000 ether);
        tokenA.mint(actor, amountA);
        tokenB.mint(actor, amountB);
        vm.startPrank(actor);
        tokenA.approve(address(amm), amountA);
        tokenB.approve(address(amm), amountB);
        try amm.addLiquidity(amountA, amountB) {} catch {}
        vm.stopPrank();
    }
}

contract ResourceAMMInvariantTest is Test {
    ResourceAMM public amm;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    AMMHandler public handler;

    uint256 public initialK;

    function setUp() public {
        tokenA = new MockERC20("Token A", "TKA");
        tokenB = new MockERC20("Token B", "TKB");
        amm = new ResourceAMM(address(tokenA), address(tokenB));

        tokenA.approve(address(amm), 10_000 ether);
        tokenB.approve(address(amm), 10_000 ether);
        amm.addLiquidity(10_000 ether, 10_000 ether);
        initialK = 10_000 ether * 10_000 ether;

        handler = new AMMHandler(amm, tokenA, tokenB);
        targetContract(address(handler));
    }

    function invariant_k_never_decreases() public view {
        (uint256 resA, uint256 resB) = amm.getReserves();
        assertGe(resA * resB, initialK);
    }

    function invariant_reserves_match_balances() public view {
        (uint256 resA, uint256 resB) = amm.getReserves();
        assertEq(tokenA.balanceOf(address(amm)), resA);
        assertEq(tokenB.balanceOf(address(amm)), resB);
    }

    function invariant_liquidity_shares_nonzero() public view {
        assertGt(amm.totalLiquidityShares(), 0);
    }
}
