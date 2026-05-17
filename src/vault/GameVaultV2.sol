// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./GameVaultV1.sol";

contract GameVaultV2 is GameVaultV1 {
    uint256 public reserveRatioBps;
    uint256 public constant MAX_RESERVE_RATIO_BPS = 5000;

    mapping(address => uint256) public stakedAt;

    event ReserveRatioUpdated(uint256 oldRatio, uint256 newRatio);

    error ReserveRatioTooHigh(uint256 requested, uint256 max);

    function initializeV2(uint256 reserveRatioBps_) external reinitializer(2) onlyOwner {
        if (reserveRatioBps_ > MAX_RESERVE_RATIO_BPS) {
            revert ReserveRatioTooHigh(reserveRatioBps_, MAX_RESERVE_RATIO_BPS);
        }
        reserveRatioBps = reserveRatioBps_;
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        if (stakedAt[receiver] == 0) {
            stakedAt[receiver] = block.timestamp;
        }
        shares = super.deposit(assets, receiver);
    }

    function setReserveRatio(uint256 newRatio) external onlyOwner {
        if (newRatio > MAX_RESERVE_RATIO_BPS) {
            revert ReserveRatioTooHigh(newRatio, MAX_RESERVE_RATIO_BPS);
        }
        emit ReserveRatioUpdated(reserveRatioBps, newRatio);
        reserveRatioBps = newRatio;
    }

    function getReserveAdjustedAssets(uint256 assets) public view returns (uint256) {
        if (reserveRatioBps == 0) return assets;
        return (assets * (10000 - reserveRatioBps)) / 10000;
    }

    function getStakeDuration(address user) public view returns (uint256) {
        if (stakedAt[user] == 0) return 0;
        return block.timestamp - stakedAt[user];
    }
}
