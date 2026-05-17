// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/vault/GameVaultV1.sol";
import "../src/vault/GameVaultV2.sol";

contract UpgradeGameVault is Script {
    function run() external {
        uint256 ownerKey = vm.envUint("PRIVATE_KEY");
        address proxy    = vm.envAddress("GAME_VAULT_PROXY");

        vm.startBroadcast(ownerKey);


        GameVaultV2 implV2 = new GameVaultV2();


        bytes memory reinitData = abi.encodeCall(
            GameVaultV2.initializeV2,
            (
                1000  // reserveRatioBps: 10%
            )
        );


        GameVaultV1(proxy).upgradeToAndCall(address(implV2), reinitData);

        vm.stopBroadcast();

        console.log("=== GameVault Upgraded to V2 ===");
        console.log("Implementation V2 :", address(implV2));
        console.log("Proxy (unchanged) :", proxy);


        console.log("Reserve ratio bps :", GameVaultV2(proxy).reserveRatioBps());
    }
}