// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/game/GameItems.sol";
import "../src/game/ResourceAMM.sol";
import "../src/game/RentalVault.sol";
import "../src/game/GameParameters.sol";


contract DeployCore is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // deploy GameParameters first
        GameParameters gameParams = new GameParameters();
        console.log("GameParameters deployed at:", address(gameParams));
        
        // deploy GameItems
        GameItems gameItems = new GameItems("Game Items", "GITEMS", address(gameParams));
        console.log("GameItems deployed at:", address(gameItems));
        
        // deploy RentalVault
        RentalVault rentalVault = new RentalVault(address(gameItems));
        console.log("RentalVault deployed at:", address(rentalVault));
        
        // ResourceAMM amm = new ResourceAMM(address(tokenA), address(tokenB));
        
        vm.stopBroadcast();
    }
}