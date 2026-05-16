// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/oracle/PriceFeedOracle.sol";
import "./mocks/MockV3Aggregator.sol";

contract PriceFeedOracleTest is Test {
    MockV3Aggregator public feed;
    PriceFeedOracle public oracle;
    address public owner = address(0x123);

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2_000 * 1e8;
    uint256 public constant MAX_STALENESS = 1 days;

    function setUp() public {
        feed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);

        vm.prank(owner);
        oracle = new PriceFeedOracle(address(feed), MAX_STALENESS);
    }

    function test_getLatestPrice() public {
        (int256 price, uint8 decimals) = oracle.getLatestPrice();

        assertEq(price, INITIAL_PRICE);
        assertEq(decimals, DECIMALS);
    }

    function test_getMaxStaleness() public {
        assertEq(oracle.getMaxStaleness(), MAX_STALENESS);
    }

    function test_revert_onStalePrice() public {
        vm.warp(block.timestamp + MAX_STALENESS + 1);
        vm.expectRevert();
        oracle.getLatestPrice();
    }

    function test_revert_onNegativePrice() public {
        feed.updateAnswer(-1);
        vm.expectRevert();
        oracle.getLatestPrice();
    }

    function test_ownerCanUpdateFeed() public {
        MockV3Aggregator otherFeed = new MockV3Aggregator(DECIMALS, 123 * 1e8);

        vm.prank(owner);
        oracle.setFeed(address(otherFeed));

        (int256 price, ) = oracle.getLatestPrice();
        assertEq(price, 123 * 1e8);
    }

    function test_revert_nonOwnerSetFeed() public {
        MockV3Aggregator otherFeed = new MockV3Aggregator(DECIMALS, 123 * 1e8);

        vm.prank(address(0x999));
        vm.expectRevert();
        oracle.setFeed(address(otherFeed));
    }

    function test_ownerCanUpdateMaxStaleness() public {
        vm.prank(owner);
        oracle.setMaxStaleness(2 days);

        assertEq(oracle.getMaxStaleness(), 2 days);
    }
}
