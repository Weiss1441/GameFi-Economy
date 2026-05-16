// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract GameVaultV1 is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public yieldRate;
    uint256 public lastYieldUpdate;
    uint256 public constant MAX_YIELD_RATE = 10000;

    event YieldRateUpdated(uint256 oldYieldRate, uint256 newYieldRate);

    error YieldRateTooHigh(uint256 requested, uint256 max);

    function initialize(string memory name_, string memory symbol_, uint256 initialYieldRate_) external initializer {
        __ERC20_init(name_, symbol_);
        __Ownable_init(msg.sender);

        if (initialYieldRate_ > MAX_YIELD_RATE) revert YieldRateTooHigh(initialYieldRate_, MAX_YIELD_RATE);
        yieldRate = initialYieldRate_;
        lastYieldUpdate = block.timestamp;
    }

    function setYieldRate(uint256 newRate) external onlyOwner {
        if (newRate > MAX_YIELD_RATE) revert YieldRateTooHigh(newRate, MAX_YIELD_RATE);
        emit YieldRateUpdated(yieldRate, newRate);
        yieldRate = newRate;
    }

    function getProjectedAssets(uint256 assets, uint256 timeElapsed) public view returns (uint256) {
        uint256 yearlyYield = (assets * yieldRate) / 10000;
        uint256 proportionalYield = (yearlyYield * timeElapsed) / 365 days;
        return assets + proportionalYield;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    uint256[50] private __gap;
}
