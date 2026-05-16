// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IResourceAMM {
    function addLiquidity(uint256 amountA, uint256 amountB) external returns (uint256 shares);
    function removeLiquidity(uint256 shares) external returns (uint256 amountA, uint256 amountB);
    function swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut) external returns (uint256 amountOut);
    function getReserves() external view returns (uint256 reserveA, uint256 reserveB);
}