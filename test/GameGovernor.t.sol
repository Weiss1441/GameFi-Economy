// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/governance/GovernanceToken.sol";
import "../src/governance/GameGovernor.sol";
import "../src/governance/GameTimelock.sol";
import "../src/game/GameParameters.sol";

contract GameGovernorTest is Test {
    GovernanceToken token;
    GameGovernor governor;
    GameTimelock timelock;
    GameParameters params;
    address voter = address(1);

    function setUp() public {
        token = new GovernanceToken();
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        timelock = new GameTimelock(2 days, proposers, executors, address(this));
        governor = new GameGovernor(IVotes(address(token)), TimelockController(payable(address(timelock))));
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));
        params = new GameParameters();
        params.transferOwnership(address(timelock));
        token.transfer(voter, token.balanceOf(address(this)));
        vm.prank(voter);
        token.delegate(voter);
        vm.roll(block.number + 1);
    }

    function _propose() internal returns (uint256, address[] memory, uint256[] memory, bytes[] memory, string memory) {
        address[] memory targets = new address[](1);
        targets[0] = address(params);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(params.setDropRate.selector, 1, 5000);
        string memory description = "Update drop rate";
        vm.prank(voter);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        return (proposalId, targets, values, calldatas, description);
    }

    function testGovernanceFlow() public {
        (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            string memory description
        ) = _propose();
        vm.roll(block.number + governor.votingDelay() + 1);
        vm.prank(voter);
        governor.castVote(proposalId, 1);
        vm.roll(block.number + governor.votingPeriod() + 1);
        bytes32 descriptionHash = keccak256(bytes(description));
        governor.queue(targets, values, calldatas, descriptionHash);
        vm.warp(block.timestamp + 2 days + 1);
        governor.execute(targets, values, calldatas, descriptionHash);
        assertEq(params.dropRates(1), 5000);
    }

    function test_governorParameters() public view {
        assertEq(governor.votingDelay(), 7200);
        assertEq(governor.votingPeriod(), 50400);
        assertEq(governor.proposalThreshold(), 10000 ether);
        assertEq(governor.quorum(block.number - 1), token.totalSupply() * 4 / 100);
        assertEq(governor.timelock(), address(timelock));
        assertEq(address(governor.token()), address(token));
    }

    function test_proposalNeedsQueuing() public {
        (uint256 proposalId,,,,) = _propose();
        assertTrue(governor.proposalNeedsQueuing(proposalId));
    }

    function test_proposalState_active() public {
        (uint256 proposalId,,,,) = _propose();
        vm.roll(block.number + governor.votingDelay() + 1);
        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Active));
    }

    function test_proposalState_defeated() public {
        (uint256 proposalId,,,,) = _propose();
        vm.roll(block.number + governor.votingDelay() + 1);
        vm.prank(voter);
        governor.castVote(proposalId, 0);
        vm.roll(block.number + governor.votingPeriod() + 1);
        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Defeated));
    }

    function test_revert_double_vote() public {
        (uint256 proposalId,,,,) = _propose();
        vm.roll(block.number + governor.votingDelay() + 1);
        vm.prank(voter);
        governor.castVote(proposalId, 1);
        vm.prank(voter);
        vm.expectRevert();
        governor.castVote(proposalId, 1);
    }

    function test_cancelDefeatedProposalByProposer() public {
        (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            string memory description
        ) = _propose();

        vm.prank(voter);
        governor.cancel(targets, values, calldatas, keccak256(bytes(description)));

        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Canceled));
    }

    function test_revert_below_threshold() public {
        address poorVoter = address(99);
        vm.prank(poorVoter);
        address[] memory targets = new address[](1);
        targets[0] = address(params);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(params.setDropRate.selector, 1, 1000);
        vm.expectRevert();
        governor.propose(targets, values, calldatas, "poor proposal");
    }

    function testFuzz_votingPowerAfterDelegate(uint256 transferAmount) public {
        vm.assume(transferAmount > 0 && transferAmount <= token.totalSupply());
        address newVoter = address(0xBEEF);
        vm.prank(voter);
        token.transfer(newVoter, transferAmount);
        vm.prank(newVoter);
        token.delegate(newVoter);
        vm.roll(block.number + 1);
        assertEq(governor.getVotes(newVoter, block.number - 1), transferAmount);
    }
}
