// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/governance/TimelockController.sol";

contract GameTimelock is TimelockController {
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    )
        TimelockController(
            minDelay,
            proposers,
            executors,
            admin
        )
    {}
}
