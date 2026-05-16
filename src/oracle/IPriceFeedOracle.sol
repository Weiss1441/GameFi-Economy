// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IPriceFeedOracle {
    /// @return price latest price from the oracle feed.
    /// @return decimals price decimals as provided by the Chainlink feed.
    function getLatestPrice() external view returns (int256 price, uint8 decimals);

    /// @return maxStaleness maximum allowed age of the price in seconds.
    function getMaxStaleness() external view returns (uint256);
}
