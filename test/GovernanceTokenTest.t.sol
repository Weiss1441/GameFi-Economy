// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/governance/GovernanceToken.sol";

contract GovernanceTokenTest is Test {
    GovernanceToken public token;
    address public user = address(0x123);

    function setUp() public {
        token = new GovernanceToken();
    }

    function test_initialSupply() public view {
        assertEq(token.totalSupply(), 1_000_000 * 10 ** 18);
    }

    function test_transfer() public {
        token.transfer(user, 100 ether);
        assertEq(token.balanceOf(user), 100 ether);
    }

    function test_delegate() public {
        token.delegate(user);
        assertEq(token.delegates(address(this)), user);
    }

    function test_voting_power_after_delegate() public {
        token.transfer(user, 500 ether);
        vm.prank(user);
        token.delegate(user);
        vm.roll(block.number + 1);
        assertEq(token.getVotes(user), 500 ether);
    }

    function test_permit() public {
        uint256 privateKey = 0x123;
        address owner = vm.addr(privateKey);
        token.transfer(owner, 1000 ether);

        uint256 deadline = block.timestamp + 1 days;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                            owner,
                            user,
                            100 ether,
                            token.nonces(owner),
                            deadline
                        )
                    )
                )
            )
        );
        token.permit(owner, user, 100 ether, deadline, v, r, s);
        assertEq(token.allowance(owner, user), 100 ether);
    }

    function testFuzz_votingPower(uint256 amount) public {
        amount = bound(amount, 1, 1_000_000 * 10 ** 18);
        token.transfer(user, amount);
        vm.prank(user);
        token.delegate(user);
        vm.roll(block.number + 1);
        assertEq(token.getVotes(user), amount);
    }
}
