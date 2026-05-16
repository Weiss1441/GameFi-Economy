// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IPriceFeedOracle.sol";

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract PriceFeedOracle is Ownable, IPriceFeedOracle {
    AggregatorV3Interface public feed;
    uint256 public maxStalenessSeconds;

    error InvalidFeed(address feed);
    error InvalidPrice(int256 price);
    error StalePrice(uint256 updatedAt, uint256 maxStalenessSeconds);

    event FeedUpdated(address indexed oldFeed, address indexed newFeed);
    event MaxStalenessUpdated(uint256 oldMaxStalenessSeconds, uint256 newMaxStalenessSeconds);

    constructor(address feed_, uint256 maxStalenessSeconds_) Ownable(msg.sender) {
        if (feed_ == address(0)) revert InvalidFeed(feed_);
        feed = AggregatorV3Interface(feed_);
        maxStalenessSeconds = maxStalenessSeconds_;
    }

    function setFeed(address feed_) external onlyOwner {
        if (feed_ == address(0)) revert InvalidFeed(feed_);
        emit FeedUpdated(address(feed), feed_);
        feed = AggregatorV3Interface(feed_);
    }

    function setMaxStaleness(uint256 maxStalenessSeconds_) external onlyOwner {
        emit MaxStalenessUpdated(maxStalenessSeconds, maxStalenessSeconds_);
        maxStalenessSeconds = maxStalenessSeconds_;
    }

    function getLatestPrice() public view override returns (int256 price, uint8 decimals) {
        (uint80 roundId, int256 answer,, uint256 updatedAt, uint80 answeredInRound) = feed.latestRoundData();

        if (roundId == 0 || answeredInRound == 0) revert InvalidPrice(answer);
        if (answer <= 0) revert InvalidPrice(answer);
        if (block.timestamp - updatedAt > maxStalenessSeconds) {
            revert StalePrice(updatedAt, maxStalenessSeconds);
        }

        return (answer, feed.decimals());
    }

    function getMaxStaleness() external view override returns (uint256) {
        return maxStalenessSeconds;
    }
}
