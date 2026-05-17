// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../src/vault/GameVaultV1.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock", "MCK") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract VaultHandlerV1 {
    GameVaultV1 public vault;
    uint256 public lastAssets;
    uint256 public lastTimeElapsed;
    uint256 public lastProjected;

    constructor(GameVaultV1 _vault) {
        vault = _vault;
    }

    function probe(uint256 assets, uint256 timeElapsed) external {
        lastAssets = assets;
        lastTimeElapsed = timeElapsed;
        lastProjected = vault.getProjectedAssets(assets, timeElapsed);
    }
}

contract GameVaultV1InvariantTest is Test {
    GameVaultV1 public implementationV1;
    GameVaultV1 public vault;
    ERC1967Proxy public proxy;
    VaultHandlerV1 public handler;
    MockToken public asset;

    address public feeRecipient = address(0xFEE);

    function setUp() public {
        asset = new MockToken();
        implementationV1 = new GameVaultV1();
        bytes memory initData = abi.encodeCall(
            GameVaultV1.initialize,
            (address(asset), "GameFi Vault Shares", "vGFI", 500, feeRecipient, 50)
        );
        proxy = new ERC1967Proxy(address(implementationV1), initData);
        vault = GameVaultV1(address(proxy));
        handler = new VaultHandlerV1(vault);
        targetContract(address(handler));
    }

    function invariant_projected_nonnegative() public view {
        assertGe(handler.lastProjected(), 0);
    }

    function invariant_projected_ge_assets() public view {
        uint256 assets = handler.lastAssets();
        if (assets == 0) return;
        assertGe(handler.lastProjected(), assets);
    }

    function invariant_yieldRate_bound() public view {
        assertLe(vault.yieldRate(), vault.MAX_YIELD_RATE());
    }
}