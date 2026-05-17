// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/game/GameItems.sol";
import "../src/vrf/LootBoxVRF.sol";

contract DeployLootBoxVRF is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address gameItemsAddress = vm.envAddress("GAME_ITEMS_ADDRESS");

        vm.startBroadcast(pk);

        LootBoxVRF lootBox = new LootBoxVRF(
            vm.envAddress("VRF_COORDINATOR"),
            vm.envUint("VRF_SUBSCRIPTION_ID"),
            vm.envBytes32("VRF_KEY_HASH"),
            gameItemsAddress
        );

        GameItems(gameItemsAddress).grantRole(
            GameItems(gameItemsAddress).VRF_ROLE(),
            address(lootBox)
        );

        vm.stopBroadcast();

        console.log("LootBoxVRF:", address(lootBox));
    }
}
