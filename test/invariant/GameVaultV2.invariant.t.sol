// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../src/vault/GameVaultV1.sol";
import "../../src/vault/GameVaultV2.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock", "MCK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract VaultHandlerV2 {
    GameVaultV2 public vault;
    uint256 public lastAssets;
    uint256 public lastReserveAdjusted;

    constructor(GameVaultV2 _vault) {
        vault = _vault;
    }

    function probeReserveAdjusted(uint256 assets) external {
        lastAssets = assets;
        lastReserveAdjusted = vault.getReserveAdjustedAssets(assets);
    }
}

contract GameVaultV2InvariantTest is Test {
    GameVaultV1 public implementationV1;
    GameVaultV2 public implementationV2;
    GameVaultV2 public vault;
    ERC1967Proxy public proxy;
    VaultHandlerV2 public handler;
    MockToken public asset;

    address public feeRecipient = address(0xFEE);

    function setUp() public {
        asset = new MockToken();
        implementationV1 = new GameVaultV1();
        bytes memory initData = abi.encodeCall(
            GameVaultV1.initialize, (address(asset), "GameFi Vault Shares", "vGFI", 500, feeRecipient, 50)
        );
        proxy = new ERC1967Proxy(address(implementationV1), initData);

        implementationV2 = new GameVaultV2();
        GameVaultV1(address(proxy))
            .upgradeToAndCall(address(implementationV2), abi.encodeCall(GameVaultV2.initializeV2, (1000)));

        vault = GameVaultV2(address(proxy));
        handler = new VaultHandlerV2(vault);
        targetContract(address(handler));
    }

    function invariant_reserve_adjusted_le_assets() public view {
        assertLe(handler.lastReserveAdjusted(), handler.lastAssets());
    }

    function invariant_reserve_ratio_bound() public view {
        assertLe(vault.reserveRatioBps(), vault.MAX_RESERVE_RATIO_BPS());
    }
}
