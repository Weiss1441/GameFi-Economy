// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./GameVaultV1.sol";

contract GameVaultV2 is GameVaultV1 {
    uint256 public reserveRatioBps;
    uint256 public constant MAX_RESERVE_RATIO_BPS = 5000;

    event ReserveRatioUpdated(uint256 oldRatio, uint256 newRatio);

    error ReserveRatioTooHigh(uint256 requested, uint256 max);

    function setReserveRatio(uint256 newRatio) external onlyOwner {
        if (newRatio > MAX_RESERVE_RATIO_BPS) revert ReserveRatioTooHigh(newRatio, MAX_RESERVE_RATIO_BPS);
        emit ReserveRatioUpdated(reserveRatioBps, newRatio);
        reserveRatioBps = newRatio;
    }

    function getReserveAdjustedAssets(uint256 assets) public view returns (uint256) {
        if (reserveRatioBps == 0) {
            return assets;
        }
        return (assets * (10000 - reserveRatioBps)) / 10000;
    }

    uint256[49] private __gap;
}
