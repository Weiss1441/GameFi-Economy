// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/vault/GameVaultV1.sol";
import "../src/vault/GameVaultV2.sol";

contract UpgradeGameVault is Script {
    function run() external {
        bool hasKey = vm.envExists("PRIVATE_KEY");
        if (hasKey) {
            uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
            vm.startBroadcast(deployerPrivateKey);
        } else {
            console.log("PRIVATE_KEY not set: running script locally without broadcasting.");
        }

        GameVaultV1 implementationV1 = new GameVaultV1();
        bytes memory initData = abi.encodeWithSelector(GameVaultV1.initialize.selector, "GameFi Vault Shares", "vGFI", 500);
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementationV1), initData);
        GameVaultV1 vaultV1 = GameVaultV1(address(proxy));

        console.log("Proxy deployed at:", address(proxy));
        console.log("Initial yieldRate:", vaultV1.yieldRate());
        console.log("Initial owner:", vaultV1.owner());

        vaultV1.setYieldRate(750);
        console.log("YieldRate after owner update:", vaultV1.yieldRate());

        GameVaultV2 implementationV2 = new GameVaultV2();
        vaultV1.upgradeToAndCall(address(implementationV2), "");

        GameVaultV2 vaultV2 = GameVaultV2(address(proxy));
        console.log("YieldRate after upgrade:", vaultV2.yieldRate());
        console.log("Owner after upgrade:", vaultV2.owner());
        console.log("ReserveRatio after upgrade:", vaultV2.reserveRatioBps());
        console.log("Projected assets from V2:", vaultV2.getReserveAdjustedAssets(10_000 ether));

        if (vm.envExists("PRIVATE_KEY")) {
            vm.stopBroadcast();
        }
    }
}
