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
import "../src/governance/GovernanceToken.sol";
import "../src/governance/GameGovernor.sol";
import "../src/governance/GameTimelock.sol";
import "../src/vault/GameVaultV1.sol";
import "../src/vault/GameVaultV2.sol";

contract DeployFull is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        GameParameters gameParams = new GameParameters();
        console.log("GameParameters deployed at:", address(gameParams));

        GameItems gameItems = new GameItems("Game Items", "GITEMS", address(gameParams));
        console.log("GameItems deployed at:", address(gameItems));

        RentalVault rentalVault = new RentalVault(address(gameItems));
        console.log("RentalVault deployed at:", address(rentalVault));

        GovernanceToken token = new GovernanceToken();
        console.log("GovernanceToken deployed at:", address(token));

        address deployer = vm.addr(deployerPrivateKey);
        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);

        GameTimelock timelock = new GameTimelock(2 days, proposers, executors, deployer);
        console.log("GameTimelock deployed at:", address(timelock));

        GameGovernor governor = new GameGovernor(IVotes(address(token)), TimelockController(payable(address(timelock))));
        console.log("GameGovernor deployed at:", address(governor));

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));
        timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), msg.sender);

        GameVaultV1 implementationV1 = new GameVaultV1();
        bytes memory initData = abi.encodeWithSelector(GameVaultV1.initialize.selector, "GameFi Vault Shares", "vGFI", 500);
        ERC1967Proxy vaultProxy = new ERC1967Proxy(address(implementationV1), initData);
        console.log("GameVault proxy deployed at:", address(vaultProxy));
        console.log("GameVault V1 implementation deployed at:", address(implementationV1));

        GameVaultV1 vaultV1 = GameVaultV1(address(vaultProxy));
        GameVaultV2 implementationV2 = new GameVaultV2();
        vaultV1.upgradeToAndCall(address(implementationV2), "");
        console.log("GameVault V2 implementation deployed at:", address(implementationV2));

        vm.stopBroadcast();
    }
}
