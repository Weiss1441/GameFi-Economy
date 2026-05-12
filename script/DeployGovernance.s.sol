// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";

import "../src/governance/GovernanceToken.sol";
import "../src/governance/GameGovernor.sol";
import "../src/governance/GameTimelock.sol";

contract DeployGovernance is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        GovernanceToken token = new GovernanceToken();

        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);

        GameTimelock timelock = new GameTimelock(
            2 days,
            proposers,
            executors,
            msg.sender
        );

        GameGovernor governor = new GameGovernor(
            IVotes(address(token)),
            TimelockController(payable(address(timelock)))
        );

        proposers[0] = address(governor);
        executors[0] = address(0);

        timelock.grantRole(
            timelock.PROPOSER_ROLE(),
            address(governor)
        );

        timelock.grantRole(
            timelock.EXECUTOR_ROLE(),
            address(0)
        );

        timelock.revokeRole(
            timelock.DEFAULT_ADMIN_ROLE(),
            msg.sender
        );

        vm.stopBroadcast();
    }
}