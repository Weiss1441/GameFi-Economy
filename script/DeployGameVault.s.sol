// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/vault/GameVaultV1.sol";

contract DeployGameVault is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address asset        = vm.envAddress("RESOURCE_TOKEN_ADDRESS");
        address feeRecipient = vm.envAddress("FEE_RECIPIENT");

        vm.startBroadcast(deployerKey);

        
        GameVaultV1 impl = new GameVaultV1();

        
        bytes memory initData = abi.encodeCall(
            GameVaultV1.initialize,
            (
                asset,
                "Game Resource Vault",
                "gvSHARE",
                500,         // yieldRate: 5%
                feeRecipient,
                50           // feeBps: 0.5%
            )
        );

        
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);

        vm.stopBroadcast();

        console.log("=== GameVault V1 Deployed ===");
        console.log("Implementation V1 :", address(impl));
        console.log("Proxy (use this)  :", address(proxy));
    }
}