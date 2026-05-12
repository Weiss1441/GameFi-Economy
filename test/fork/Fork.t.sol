// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IChainlinkFeed {
    function latestRoundData() external view returns (
        uint80, int256, uint256, uint256, uint80
    );
    function decimals() external view returns (uint8);
}

contract ForkTest is Test {
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant ETH_USD_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    // Binance hot wallet — always has huge USDC balance
    address constant USDC_WHALE = 0x28C6c06298d514Db089934071355E5743bf21d60;

    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("ETH_MAINNET_RPC"));
        vm.selectFork(mainnetFork);
    }

    function test_fork_chainlink_eth_usd_feed() public view {
        IChainlinkFeed feed = IChainlinkFeed(ETH_USD_FEED);
        (uint80 roundId, int256 price, , uint256 updatedAt,) = feed.latestRoundData();
        assertGt(roundId, 0);
        assertGt(price, 100 * 1e8);
        assertLt(price, 100_000 * 1e8);
        assertGt(updatedAt, 0);
    }

    function test_fork_usdc_total_supply() public view {
        uint256 supply = IERC20(USDC).totalSupply();
        assertGt(supply, 1_000_000 * 1e6); // > $1M
    }

    function test_fork_usdc_transfer() public {
        IERC20 usdc = IERC20(USDC);
        address recipient = address(0xBEEF);

        uint256 whaleBefore = usdc.balanceOf(USDC_WHALE);
        assertGt(whaleBefore, 1000 * 1e6);

        vm.prank(USDC_WHALE);
        usdc.transfer(recipient, 1000 * 1e6);

        assertEq(usdc.balanceOf(recipient), 1000 * 1e6);
        assertEq(usdc.balanceOf(USDC_WHALE), whaleBefore - 1000 * 1e6);
    }
}
