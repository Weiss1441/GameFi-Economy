// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IGameParameters.sol";

contract GameParameters is Ownable, IGameParameters {
    mapping(uint256 => uint256) public dropRates; // basis points (10000 = 100%)
    mapping(uint256 => uint256) public craftingCosts;

    uint256 public constant MAX_BPS = 10000;

    event DropRateUpdated(uint256 indexed itemId, uint256 newRate);
    event CraftingCostUpdated(uint256 indexed recipeId, uint256 newCost);

    constructor() Ownable(msg.sender) {}

    function getDropRate(uint256 itemId) external view override returns (uint256) {
        return dropRates[itemId];
    }

    function getCraftingCost(uint256 recipeId) external view override returns (uint256) {
        return craftingCosts[recipeId];
    }

    function setDropRate(uint256 itemId, uint256 rate) external override onlyOwner {
        require(rate <= MAX_BPS, "Rate exceeds max");
        dropRates[itemId] = rate;
        emit DropRateUpdated(itemId, rate);
    }

    function setCraftingCost(uint256 recipeId, uint256 cost) external override onlyOwner {
        craftingCosts[recipeId] = cost;
        emit CraftingCostUpdated(recipeId, cost);
    }

    function setMultipleDropRates(uint256[] calldata itemIds, uint256[] calldata rates) external onlyOwner {
        require(itemIds.length == rates.length, "Arrays length mismatch");
        for (uint256 i = 0; i < itemIds.length; i++) {
            require(rates[i] <= MAX_BPS, "Rate exceeds max");
            dropRates[itemIds[i]] = rates[i];
            emit DropRateUpdated(itemIds[i], rates[i]);
        }
    }
}
