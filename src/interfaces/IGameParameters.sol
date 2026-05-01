// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IGameParameters {
    function getDropRate(uint256 itemId) external view returns (uint256);
    function getCraftingCost(uint256 recipeId) external view returns (uint256);
    function setDropRate(uint256 itemId, uint256 rate) external;
    function setCraftingCost(uint256 recipeId, uint256 cost) external;
}