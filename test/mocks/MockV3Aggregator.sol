// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract MockV3Aggregator {
    uint8 public decimals;
    int256 public latestAnswer;
    uint256 public latestTimestamp;
    uint80 public latestRound;
    uint80 public answeredInRound;

    constructor(uint8 _decimals, int256 _initialAnswer) {
        decimals = _decimals;
        updateAnswer(_initialAnswer);
    }

    function updateAnswer(int256 _answer) public {
        latestAnswer = _answer;
        latestTimestamp = block.timestamp;
        latestRound++;
        answeredInRound = latestRound;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 _answeredInRound
        )
    {
        return (
            latestRound,
            latestAnswer,
            latestTimestamp,
            latestTimestamp,
            answeredInRound
        );
    }
}
