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

interface IVRFCoordinatorV2PlusSubscriptionManager {
    function addConsumer(uint256 subId, address consumer) external;
}

contract DeployFull is Script {
    address private deployer;
    address private vrfCoordinator;
    uint256 private subscriptionId;
    bytes32 private keyHash;
    bool private registerConsumer;
    bool private nativePayment;
    uint32 private callbackGasLimit;
    uint256 private initialLiquidity;

    GameParameters private params;
    GameItems private items;
    LootBoxVRF private lootBox;
    RentalVault private rental;
    GovernanceToken private gov;
    GovernanceToken private swapTokenB;
    GameTimelock private timelock;
    GameGovernor private governor;
    GameVaultV1 private vaultImpl;
    GameVaultV2 private vaultImplV2;
    ERC1967Proxy private vault;
    ResourceAMM private amm;
    GameFactory private factory;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        _loadConfig(pk);

        vm.startBroadcast(pk);

        _deployGameAndVrf();
        _deployGovernanceAndVault();
        _deployAmmAndFactory();

        vm.stopBroadcast();

        _logDeployment();
    }

    function _loadConfig(uint256 pk) private {
        deployer = vm.addr(pk);
        vrfCoordinator = vm.envAddress("VRF_COORDINATOR");
        subscriptionId = vm.envUint("VRF_SUBSCRIPTION_ID");
        keyHash = vm.envBytes32("VRF_KEY_HASH");
        registerConsumer = vm.envOr("REGISTER_VRF_CONSUMER", true);
        nativePayment = vm.envOr("VRF_NATIVE_PAYMENT", true);
        callbackGasLimit = uint32(vm.envOr("VRF_CALLBACK_GAS_LIMIT", uint256(2_000_000)));
        initialLiquidity = vm.envOr("INITIAL_AMM_LIQUIDITY", uint256(100 ether));
    }

    function _deployGameAndVrf() private {
        params = new GameParameters();
        items = new GameItems("Game Items", "GITEMS", address(params));
        lootBox = new LootBoxVRF(vrfCoordinator, subscriptionId, keyHash, address(items));

        items.grantRole(items.VRF_ROLE(), address(lootBox));
        lootBox.setNativePayment(nativePayment);
        lootBox.setCallbackGasLimit(callbackGasLimit);
        _configureRecipes();

        if (registerConsumer) {
            IVRFCoordinatorV2PlusSubscriptionManager(vrfCoordinator).addConsumer(subscriptionId, address(lootBox));
        }

        rental = new RentalVault(address(items));
    }

    function _configureRecipes() private {
        _setRecipe(3, 4, 5);
        _setRecipe(4, 3, 5);
        _setRecipe(5, 2, 3);

        params.setCraftingCost(3, 1);
        params.setCraftingCost(4, 1);
        params.setCraftingCost(5, 1);
    }

    function _setRecipe(uint256 resultId, uint256 ingredientA, uint256 ingredientB) private {
        uint256[] memory ingredients = new uint256[](2);
        ingredients[0] = ingredientA;
        ingredients[1] = ingredientB;
        items.setCraftingRecipe(ingredients, resultId);
    }

    function _deployGovernanceAndVault() private {
        gov = new GovernanceToken();
        swapTokenB = new GovernanceToken();
        timelock = new GameTimelock(2 days, new address[](0), new address[](0), deployer);

        governor = new GameGovernor(IVotes(address(gov)), TimelockController(payable(address(timelock))));

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));

        _deployVault();
    }

    function _deployVault() private {
        vaultImpl = new GameVaultV1();
        bytes memory initData = abi.encodeWithSelector(
            GameVaultV1.initialize.selector, address(gov), "GameFi Vault Shares", "vGFI", 500, deployer, 0
        );

        vault = new ERC1967Proxy(address(vaultImpl), initData);

        vaultImplV2 = new GameVaultV2();
        GameVaultV1(address(vault)).upgradeToAndCall(address(vaultImplV2), "");
    }

    function _deployAmmAndFactory() private {
        amm = new ResourceAMM(address(gov), address(swapTokenB));

        if (initialLiquidity > 0) {
            gov.testMint();
            swapTokenB.testMint();
            gov.approve(address(amm), initialLiquidity);
            swapTokenB.approve(address(amm), initialLiquidity);
            amm.addLiquidity(initialLiquidity, initialLiquidity);
        }

        factory = new GameFactory();
    }

    function _logDeployment() private view {
        console.log("GameParameters:", address(params));
        console.log("GameItems:", address(items));
        console.log("LootBoxVRF:", address(lootBox));
        console.log("RentalVault:", address(rental));
        console.log("GovernanceToken:", address(gov));
        console.log("SwapTokenB:", address(swapTokenB));
        console.log("Governor:", address(governor));
        console.log("Timelock:", address(timelock));
        console.log("Vault:", address(vault));
        console.log("VaultV1Implementation:", address(vaultImpl));
        console.log("VaultV2Implementation:", address(vaultImplV2));
        console.log("AMM:", address(amm));
        console.log("Factory:", address(factory));
        console.log("VRF subscription:", subscriptionId);
        console.log("VRF nativePayment:", nativePayment);
        console.log("VRF callbackGasLimit:", callbackGasLimit);
        console.log("VRF consumer registered:", registerConsumer);
        console.log("Initial AMM liquidity:", initialLiquidity);
    }
}
