// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "@openzeppelin/contracts/governance/TimelockController.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "../src/game/GameItems.sol";
import "../src/game/RentalVault.sol";
import "../src/game/GameParameters.sol";
import "../src/game/ResourceAMM.sol";
import "../src/factory/GameFactory.sol";
import "../src/governance/GovernanceToken.sol";
import "../src/governance/GameGovernor.sol";
import "../src/governance/GameTimelock.sol";
import "../src/vrf/LootBoxVRF.sol";
import "../src/vault/GameVaultV1.sol";
import "../src/vault/GameVaultV2.sol";

contract DeployFull is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);

        GameParameters params = new GameParameters();

        GameItems items = new GameItems(
            "Game Items",
            "GITEMS",
            address(params)
        );

        LootBoxVRF lootBox = new LootBoxVRF(
            vm.envAddress("VRF_COORDINATOR"),
            vm.envUint("VRF_SUBSCRIPTION_ID"),
            vm.envBytes32("VRF_KEY_HASH"),
            address(items)
        );

        items.grantRole(items.VRF_ROLE(), address(lootBox));

        RentalVault rental = new RentalVault(address(items));

        GovernanceToken gov = new GovernanceToken();
        GovernanceToken govB = new GovernanceToken();
        GameTimelock timelock = new GameTimelock(
            2 days,
            new address[](0),
            new address[](0),
            vm.addr(pk)
        );

        GameGovernor governor = new GameGovernor(
            IVotes(address(gov)),
            TimelockController(payable(address(timelock)))
        );

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));

        GameVaultV1 impl = new GameVaultV1();

        bytes memory initData = abi.encodeWithSelector(
            GameVaultV1.initialize.selector,
            address(gov),
            "GameFi Vault Shares",
            "vGFI",
            500,
            vm.addr(pk),
            0
        );

        ERC1967Proxy vault = new ERC1967Proxy(address(impl), initData);

        GameVaultV2 implV2 = new GameVaultV2();
        GameVaultV1(address(vault)).upgradeToAndCall(address(implV2), "");

        ResourceAMM amm = new ResourceAMM(address(gov), address(govB));

        GameFactory factory = new GameFactory();

        vm.stopBroadcast();

        console.log("LootBoxVRF:", address(lootBox));
        console.log("GameItems:", address(items));
        console.log("RentalVault:", address(rental));
        console.log("Governor:", address(governor));
        console.log("Vault:", address(vault));
        console.log("AMM:", address(amm));
        console.log("Factory:", address(factory));
    }
}
