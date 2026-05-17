const REQUIRED_CHAIN_ID = 421614;

const config = {
  governanceToken: "0x0b437CD552a192A0662B08dc843cC2CaD8704a9c",
  gameGovernor: "0x95bA2074cd84ea48aAa3DC553e663d98b9a756A4",
  resourceAmm: "0xB9d86f7faDDC177C41E1d3de8a7a21127a8018D2",
  gameVault: "0xb2572c83406a0824B8557AAFb9FC037070d82041",
  gameItems: "0x7ECFB17fae78476Cc0A6Ca7239e87B8C40B61406",
  lootBoxVrf: "0x2B2C850b9094FFF0f2d814BC79ae696b0cBb6006",
  gameParameters: "0x9AD99854cB4d757a5C684d3951ebCB9edbdA7906",
  rentalVault: "0x78Af981075BaA5F9d64f84cEC26A9970C9B4404A",
  rpc: {
    421614: "https://sepolia-rollup.arbitrum.io/rpc",
  },
  graphDefault: "https://api.studio.thegraph.com/query/960/game-fi/v0.0.1",
};

const abis = {
  erc20: [
    "function symbol() view returns (string)",
    "function decimals() view returns (uint8)",
    "function balanceOf(address) view returns (uint256)",
    "function allowance(address,address) view returns (uint256)",
    "function approve(address,uint256) returns (bool)",
    "function testMint()",
    "function delegate(address)",
    "function getVotes(address) view returns (uint256)",
    "function delegates(address) view returns (address)",
  ],
  governor: [
    "function state(uint256) view returns (uint8)",
    "function castVote(uint256,uint8) returns (uint256)",
    "event ProposalCreated(uint256 proposalId, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint256 voteStart, uint256 voteEnd, string description)",
  ],
  resourceAmm: [
    "function tokenA() view returns (address)",
    "function tokenB() view returns (address)",
    "function reserveA() view returns (uint256)",
    "function reserveB() view returns (uint256)",
    "function getAmountOut(uint256,address,address) view returns (uint256)",
    "function addLiquidity(uint256,uint256) returns (uint256)",
    "function swap(address,address,uint256,uint256) returns (uint256)",
    "event Swap(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut)",
  ],
  vault: [
    "function asset() view returns (address)",
    "function balanceOf(address) view returns (uint256)",
    "function deposit(uint256,address) returns (uint256)",
  ],
  gameItems: [
    "function balanceOf(address,uint256) view returns (uint256)",
    "function uri(uint256) view returns (string)",
    "function craftingRecipes(uint256,uint256) view returns (uint256)",
    "function craft(uint256[] ingredients, uint256 recipeId) returns (uint256)",
    "function setApprovalForAll(address operator, bool approved) external",
    "function isApprovedForAll(address account, address operator) view returns (bool)",
  ],
  rentalVault: [
    "function gameItems() view returns (address)",
    "function depositedAmounts(uint256) view returns (uint256)",
    "function deposit(uint256 tokenId, uint256 amount) external",
    "function rent(uint256 tokenId, address renter, uint256 duration) external",
    "function isRented(uint256) view returns (bool)",
  ],
  lootBoxVrf: [
    "function requestLoot() returns (uint256 requestId)",
    "function requests(uint256) view returns (address user, bool fulfilled)",
    "event LootRequested(address indexed user, uint256 indexed requestId)",
    "event LootMinted(address indexed user, uint256 itemId, uint256 rarity)",
  ],
};

const elements = {
  connectMetaMask: document.getElementById("connectMetaMask"),
  connectWalletConnect: document.getElementById("connectWalletConnect"),
  chainLabel: document.getElementById("chainLabel"),
  accountLabel: document.getElementById("accountLabel"),
  networkCheck: document.getElementById("networkCheck"),
  statusMessage: document.getElementById("statusMessage"),
  tokenBalance: document.getElementById("tokenBalance"),
  votingPower: document.getElementById("votingPower"),
  delegateAddress: document.getElementById("delegateAddress"),
  vaultShares: document.getElementById("vaultShares"),
  reserveA: document.getElementById("reserveA"),
  reserveB: document.getElementById("reserveB"),
  ammTokenABalance: document.getElementById("ammTokenABalance"),
  ammTokenBBalance: document.getElementById("ammTokenBBalance"),
  vaultAsset: document.getElementById("vaultAsset"),
  depositAmount: document.getElementById("depositAmount"),
  swapAmount: document.getElementById("swapAmount"),
  liquidityAmountA: document.getElementById("liquidityAmountA"),
  liquidityAmountB: document.getElementById("liquidityAmountB"),
  mintSwapTokensButton: document.getElementById("mintSwapTokensButton"),
  addLiquidityButton: document.getElementById("addLiquidityButton"),
  mintGovernanceButton: document.getElementById("mintGovernanceButton"),
  delegateInput: document.getElementById("delegateInput"),
  depositButton: document.getElementById("depositButton"),
  swapButton: document.getElementById("swapButton"),
  delegateButton: document.getElementById("delegateButton"),
  proposalList: document.getElementById("proposalList"),
  subgraphEndpoint: document.getElementById("subgraphEndpoint"),
  refreshGraph: document.getElementById("refreshGraph"),
  graphResult: document.getElementById("graphResult"),
  switchNetworkButton: document.getElementById("switchNetworkButton"),
  messagePanel: document.getElementById("messagePanel"),
  craftButton: document.getElementById("craftButton"),
  craftRecipeSelect: document.getElementById("craftRecipeSelect"),
  craftRecipeInfo: document.getElementById("craftRecipeInfo"),
  rentalTokenId: document.getElementById("rentalTokenId"),
  rentalAmount: document.getElementById("rentalAmount"),
  depositItemButton: document.getElementById("depositItemButton"),
  rentItemButton: document.getElementById("rentItemButton"),
  rentalStatus: document.getElementById("rentalStatus"),
  rentalWalletBalance: document.getElementById("rentalWalletBalance"),
  rentalDepositedBalance: document.getElementById("rentalDepositedBalance"),
  governanceStatus: document.getElementById("governanceStatus"),
  inventoryList: document.getElementById("inventoryList"),
  availableItemsList: document.getElementById("availableItemsList"),
  lootButton: document.getElementById("lootButton"),
  lastLootRequest: document.getElementById("lastLootRequest"),
  lootResult: document.getElementById("lootResult"),
};

let provider = null;
let signer = null;
let userAddress = null;
let currentChainId = null;
let connectedProviderType = null;
let vaultAssetAddress = null;
let ammTokenAAddress = null;
let ammTokenBAddress = null;
let ammHasLiquidity = false;
let rentalVaultCompatible = false;

const providerContracts = {
  token: null,
  governor: null,
  amm: null,
  vault: null,
  gameItems: null,
  rentalVault: null,
  lootBoxVrf: null,
};

const itemCatalog = [
  { id: 1, name: "Wooden Sword", detail: "Common starter weapon" },
  { id: 2, name: "Health Potion", detail: "Common consumable" },
  { id: 3, name: "Iron Armor", detail: "Rare defensive item" },
  { id: 4, name: "Dragon Scale", detail: "Legendary loot drop" },
  { id: 5, name: "Mystery Chest", detail: "Mystic reward chest" },
];

const itemById = Object.fromEntries(itemCatalog.map((item) => [item.id, item]));

const craftRecipes = {
  3: { resultId: 3, name: "Iron Armor", ingredients: [4, 5] },
  4: { resultId: 4, name: "Dragon Scale", ingredients: [3, 5] },
  5: { resultId: 5, name: "Mystery Chest", ingredients: [2, 3] },
};

function setMessage(text, type = "info") {
  if (!elements.messagePanel) return;
  elements.messagePanel.textContent = text;
  elements.messagePanel.style.color =
    type === "error"
      ? "#ff9c9c"
      : type === "success"
        ? "#a2f7c5"
        : "var(--text)";
}

function setStatus(text) {
  if (elements.statusMessage) elements.statusMessage.textContent = text;
}

function formatAddress(address) {
  if (!address || address === "-") return "-";
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

function setAddressText(element, address, fallback = "-") {
  if (!element) return;
  if (!address || address === ethers.ZeroAddress) {
    element.textContent = fallback;
    element.removeAttribute("title");
    return;
  }
  element.textContent = formatAddress(address);
  element.title = address;
  element.classList.add("inline-address");
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function renderAddress(address) {
  if (!address || address === ethers.ZeroAddress) return "-";
  return `<code class="inline-address" title="${escapeHtml(address)}">${formatAddress(address)}</code>`;
}

function getRecipeDescription(recipe) {
  return recipe.ingredients
    .map((id) => `${itemById[id]?.name || `Item ${id}`} #${id}`)
    .join(" + ");
}

function updateCraftRecipeInfo() {
  if (!elements.craftRecipeInfo || !elements.craftRecipeSelect) return;
  const recipe = craftRecipes[Number(elements.craftRecipeSelect.value)];
  if (!recipe) {
    elements.craftRecipeInfo.textContent = "Select a recipe.";
    return;
  }
  elements.craftRecipeInfo.textContent = `Creates ${recipe.name} #${recipe.resultId}. Requires ${getRecipeDescription(recipe)}.`;
}

async function getCraftIngredients(recipe) {
  if (!providerContracts.gameItems) return recipe.ingredients;

  const onchainIngredients = [];
  for (let index = 0; index < 8; index++) {
    try {
      const ingredient = await providerContracts.gameItems.craftingRecipes(
        recipe.resultId,
        index,
      );
      onchainIngredients.push(Number(ingredient));
    } catch {
      break;
    }
  }

  return onchainIngredients.length ? onchainIngredients : recipe.ingredients;
}

function setupCopyAddress() {
  const copyBtn = document.getElementById("copyAddressBtn");
  if (!copyBtn) return;
  copyBtn.addEventListener("click", async () => {
    if (userAddress) {
      await navigator.clipboard.writeText(userAddress);
      setMessage("Address copied to clipboard", "success");
      copyBtn.textContent = "Copied!";
      setTimeout(() => {
        copyBtn.textContent = "Copy";
      }, 2000);
    }
  });
}

function formatBig(value, decimals = 18) {
  try {
    return ethers.formatUnits(value, decimals);
  } catch {
    return "0";
  }
}

async function getTxOverrides() {
  if (!provider) return {};
  try {
    const gasPriceHex = await provider.send("eth_gasPrice", []);
    if (gasPriceHex) {
      const gasPrice = BigInt(gasPriceHex);
      return {
        gasPrice: (gasPrice * 12n) / 10n + 1n,
      };
    }
  } catch (error) {
    console.warn("Failed to estimate fee overrides", error);
  }
  return {};
}

function getStateLabel(state) {
  const mapping = {
    0: "Pending",
    1: "Active",
    2: "Canceled",
    3: "Defeated",
    4: "Succeeded",
    5: "Queued",
    6: "Expired",
    7: "Executed",
  };
  return mapping[state] ?? `State ${state}`;
}

async function initializeContracts() {
  providerContracts.token = new ethers.Contract(
    config.governanceToken,
    abis.erc20,
    provider,
  );
  providerContracts.governor = new ethers.Contract(
    config.gameGovernor,
    abis.governor,
    provider,
  );
  providerContracts.amm = new ethers.Contract(
    config.resourceAmm,
    abis.resourceAmm,
    provider,
  );
  providerContracts.vault = new ethers.Contract(
    config.gameVault,
    abis.vault,
    provider,
  );
  providerContracts.gameItems = new ethers.Contract(
    config.gameItems,
    abis.gameItems,
    provider,
  );
  providerContracts.rentalVault = new ethers.Contract(
    config.rentalVault,
    abis.rentalVault,
    provider,
  );
  providerContracts.lootBoxVrf =
    ethers.isAddress(config.lootBoxVrf) &&
    config.lootBoxVrf !== ethers.ZeroAddress
      ? new ethers.Contract(config.lootBoxVrf, abis.lootBoxVrf, provider)
      : null;
}

async function checkNetwork() {
  if (!provider) return false;
  const network = await provider.getNetwork();
  currentChainId = Number(network.chainId);

  if (elements.chainLabel) {
    elements.chainLabel.textContent = `${currentChainId} (0x${currentChainId.toString(16)})`;
  }

  if (currentChainId === REQUIRED_CHAIN_ID) {
    if (elements.networkCheck) {
      elements.networkCheck.textContent = "Correct network";
      elements.networkCheck.style.color = "#8cff94";
    }
    return true;
  }

  if (elements.networkCheck) {
    elements.networkCheck.textContent = `Wrong network, expected ${REQUIRED_CHAIN_ID}`;
    elements.networkCheck.style.color = "#ff8a8a";
  }
  return false;
}

async function switchNetwork() {
  if (!window.ethereum) {
    setMessage("No injected wallet found to switch network.", "error");
    return;
  }
  const targetHex = "0x" + REQUIRED_CHAIN_ID.toString(16);
  try {
    await window.ethereum.request({
      method: "wallet_switchEthereumChain",
      params: [{ chainId: targetHex }],
    });
    setMessage("Network switched — reconnecting...", "success");
    if (connectedProviderType === "metamask") await connectMetaMask();
  } catch (err) {
    if (err && err.code === 4902) {
      try {
        await window.ethereum.request({
          method: "wallet_addEthereumChain",
          params: [
            {
              chainId: targetHex,
              chainName: "Arbitrum Sepolia",
              nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
              rpcUrls: [
                config.rpc[REQUIRED_CHAIN_ID] ||
                  "https://sepolia-rollup.arbitrum.io/rpc",
              ],
              blockExplorerUrls: ["https://sepolia.arbiscan.io"],
            },
          ],
        });
        setMessage("Network added — please switch.", "success");
      } catch (addErr) {
        setMessage(
          "Failed to add network: " + getErrorMessage(addErr),
          "error",
        );
      }
    } else {
      setMessage("Network switch failed: " + getErrorMessage(err), "error");
    }
  }
}

function updateUIConnected() {
  setAddressText(elements.accountLabel, userAddress, "-");
  const copyBtn = document.getElementById("copyAddressBtn");
  if (copyBtn) {
    copyBtn.style.display = userAddress ? "inline-block" : "none";
  }
}

function setButtonsEnabled(enabled) {
  const btns = [
    elements.depositButton,
    elements.swapButton,
    elements.delegateButton,
    elements.refreshGraph,
    elements.craftButton,
    elements.depositItemButton,
    elements.rentItemButton,
    elements.lootButton,
    elements.mintSwapTokensButton,
    elements.addLiquidityButton,
    elements.mintGovernanceButton,
  ];
  btns.forEach((btn) => {
    if (btn) btn.disabled = !enabled;
  });
  if (enabled && elements.lootButton && !providerContracts.lootBoxVrf) {
    elements.lootButton.disabled = true;
    if (elements.lootResult)
      elements.lootResult.textContent =
        "LootBoxVRF address is not configured yet.";
  }
  if (enabled) {
    if (elements.swapButton) elements.swapButton.disabled = !ammHasLiquidity;
    if (elements.depositItemButton)
      elements.depositItemButton.disabled = !rentalVaultCompatible;
    if (elements.rentItemButton)
      elements.rentItemButton.disabled = !rentalVaultCompatible;
  }
}

function parsePositiveWholeBigInt(value, label) {
  const normalized = String(value || "").trim();
  if (!/^[0-9]+$/.test(normalized)) {
    throw new Error(`${label} must be a whole positive number.`);
  }
  const parsed = BigInt(normalized);
  if (parsed <= 0n) {
    throw new Error(`${label} must be greater than 0.`);
  }
  return parsed;
}

function setGovernanceStatus(text, type = "info") {
  if (!elements.governanceStatus) return;
  elements.governanceStatus.textContent = text;
  elements.governanceStatus.style.color =
    type === "error"
      ? "#ff9c9c"
      : type === "success"
        ? "var(--success)"
        : "var(--muted)";
}

async function loadInventory() {
  if (!elements.inventoryList) return;
  if (!providerContracts.gameItems || !userAddress) {
    elements.inventoryList.textContent = "Connect wallet to view items";
    return;
  }

  const balances = await Promise.all(
    itemCatalog.map(async (item) => ({
      ...item,
      balance: await providerContracts.gameItems.balanceOf(
        userAddress,
        item.id,
      ),
    })),
  );

  elements.inventoryList.innerHTML = balances
    .map(
      (item) => `
    <div class="inventory-item">
      <span class="item-name">${item.name}</span>
      <span class="item-balance">Qty ${item.balance.toString()}</span>
    </div>
  `,
    )
    .join("");
}

async function loadAvailableItems() {
  if (!elements.availableItemsList) return;

  elements.availableItemsList.innerHTML = itemCatalog
    .map(
      (item) => `
    <div class="inventory-item">
      <span class="item-name">${item.name} #${item.id}</span>
      <span class="item-detail">${item.detail}</span>
    </div>
  `,
    )
    .join("");
}

function watchLootEvents() {
  if (!providerContracts.lootBoxVrf || !userAddress) return;
  providerContracts.lootBoxVrf.removeAllListeners("LootMinted");
  providerContracts.lootBoxVrf.on(
    "LootMinted",
    async (user, itemId, rarity) => {
      if (user.toLowerCase() !== userAddress.toLowerCase()) return;
      if (elements.lootResult) {
        elements.lootResult.textContent = `Loot minted: item #${itemId.toString()}, rarity roll ${rarity.toString()}.`;
      }
      setMessage("Random loot fulfilled by Chainlink VRF.", "success");
      await loadInventory();
    },
  );
}

async function loadUserData() {
  if (!signer || !providerContracts.token) return;
  let tokenDecimals = 18;
  let tokenSymbol = "GFI";

  try {
    [tokenDecimals, tokenSymbol] = await Promise.all([
      providerContracts.token.decimals(),
      providerContracts.token.symbol(),
    ]);
  } catch (error) {
    console.warn("Failed to load governance token metadata", error);
  }

  try {
    const balance = await providerContracts.token.balanceOf(userAddress);
    if (elements.tokenBalance)
      elements.tokenBalance.textContent = `${formatBig(balance, tokenDecimals)} ${tokenSymbol}`;
    if (balance === 0n) {
      setGovernanceStatus(
        "Your wallet has 0 governance tokens. This token has no public faucet/mint in the contract; send GFI to this wallet before delegating or voting.",
        "info",
      );
    } else {
      setGovernanceStatus(
        "Governance token loaded. Delegate to yourself or another wallet to activate voting power.",
        "success",
      );
    }
  } catch (error) {
    if (elements.tokenBalance)
      elements.tokenBalance.textContent = "Unavailable";
    setGovernanceStatus(
      "Could not load governance token balance: " + getErrorMessage(error),
      "error",
    );
  }

  try {
    const votes = await providerContracts.token.getVotes(userAddress);
    if (elements.votingPower)
      elements.votingPower.textContent = `${formatBig(votes, tokenDecimals)} ${tokenSymbol}`;
  } catch (error) {
    if (elements.votingPower) elements.votingPower.textContent = "Unavailable";
    console.warn("Failed to load voting power", error);
  }

  try {
    const delegated = await providerContracts.token.delegates(userAddress);
    setAddressText(elements.delegateAddress, delegated, "None");
  } catch (error) {
    if (elements.delegateAddress)
      elements.delegateAddress.textContent = "Unavailable";
    console.warn("Failed to load delegate address", error);
  }

  try {
    if (providerContracts.vault && elements.vaultShares) {
      const vaultShares = await providerContracts.vault.balanceOf(userAddress);
      elements.vaultShares.textContent = formatBig(vaultShares, 18);
    }
  } catch (error) {
    if (elements.vaultShares) elements.vaultShares.textContent = "Unavailable";
    console.warn("Failed to load vault shares", error);
  }

  await loadInventory();
}

async function loadProtocolData() {
  if (!providerContracts.amm || !providerContracts.vault) return;
  try {
    const [reserveA, reserveB, asset, tokenA, tokenB] = await Promise.all([
      providerContracts.amm.reserveA(),
      providerContracts.amm.reserveB(),
      providerContracts.vault.asset(),
      providerContracts.amm.tokenA(),
      providerContracts.amm.tokenB(),
    ]);
    vaultAssetAddress = asset;
    ammTokenAAddress = tokenA;
    ammTokenBAddress = tokenB;
    ammHasLiquidity = reserveA > 0n && reserveB > 0n;
    if (elements.reserveA)
      elements.reserveA.textContent = formatBig(reserveA, 18);
    if (elements.reserveB)
      elements.reserveB.textContent = formatBig(reserveB, 18);
    setAddressText(elements.vaultAsset, asset, "-");
    await loadAmmBalances();
    if (!ammHasLiquidity) {
      if (elements.swapButton) elements.swapButton.disabled = true;
      setMessage(
        "AMM has no liquidity yet, so swaps are disabled until reserves are funded.",
        "info",
      );
    }
  } catch (error) {
    setMessage(
      "Failed to load protocol state: " + getErrorMessage(error),
      "error",
    );
  }
}

async function loadAmmBalances() {
  if (!userAddress || !ammTokenAAddress || !ammTokenBAddress) return;
  try {
    const tokenA = new ethers.Contract(ammTokenAAddress, abis.erc20, provider);
    const tokenB = new ethers.Contract(ammTokenBAddress, abis.erc20, provider);
    const [balanceA, balanceB, symbolA, symbolB] = await Promise.all([
      tokenA.balanceOf(userAddress),
      tokenB.balanceOf(userAddress),
      tokenA.symbol().catch(() => "A"),
      tokenB.symbol().catch(() => "B"),
    ]);
    if (elements.ammTokenABalance)
      elements.ammTokenABalance.textContent = `${formatBig(balanceA, 18)} ${symbolA}`;
    if (elements.ammTokenBBalance)
      elements.ammTokenBBalance.textContent = `${formatBig(balanceB, 18)} ${symbolB}`;
  } catch (error) {
    if (elements.ammTokenABalance)
      elements.ammTokenABalance.textContent = "Unavailable";
    if (elements.ammTokenBBalance)
      elements.ammTokenBBalance.textContent = "Unavailable";
    console.warn("Failed to load AMM balances", error);
  }
}

async function loadRentalBalances() {
  if (
    !userAddress ||
    !providerContracts.gameItems ||
    !providerContracts.rentalVault
  )
    return;
  const tokenIdRaw = elements.rentalTokenId?.value.trim() || "1";
  if (!/^[0-9]+$/.test(tokenIdRaw) || BigInt(tokenIdRaw) <= 0n) return;

  try {
    const tokenId = BigInt(tokenIdRaw);
    const [walletBalance, depositedBalance] = await Promise.all([
      providerContracts.gameItems.balanceOf(userAddress, tokenId),
      providerContracts.rentalVault.depositedAmounts(tokenId),
    ]);
    if (elements.rentalWalletBalance)
      elements.rentalWalletBalance.textContent = `#${tokenId} x ${walletBalance.toString()}`;
    if (elements.rentalDepositedBalance)
      elements.rentalDepositedBalance.textContent = `#${tokenId} x ${depositedBalance.toString()}`;
  } catch (error) {
    if (elements.rentalWalletBalance)
      elements.rentalWalletBalance.textContent = "Unavailable";
    if (elements.rentalDepositedBalance)
      elements.rentalDepositedBalance.textContent = "Unavailable";
    console.warn("Failed to load rental balances", error);
  }
}

async function checkRentalVaultCompatibility() {
  rentalVaultCompatible = false;
  if (!providerContracts.rentalVault || !elements.rentalStatus) return;
  try {
    const vaultGameItems = await providerContracts.rentalVault.gameItems();
    rentalVaultCompatible =
      vaultGameItems.toLowerCase() === config.gameItems.toLowerCase();
    if (rentalVaultCompatible) {
      elements.rentalStatus.textContent =
        "Rental vault is connected to the active GameItems contract.";
      elements.rentalStatus.style.color = "var(--success)";
      await loadRentalBalances();
    } else {
      elements.rentalStatus.textContent = `Rental vault uses ${formatAddress(vaultGameItems)}, but active GameItems is ${formatAddress(config.gameItems)}. Deploy/update RentalVault before deposits.`;
      elements.rentalStatus.title = `RentalVault gameItems: ${vaultGameItems}\nActive GameItems: ${config.gameItems}`;
      elements.rentalStatus.style.color = "#ff9c9c";
    }
  } catch (error) {
    elements.rentalStatus.textContent =
      "Could not check rental vault compatibility: " + getErrorMessage(error);
    elements.rentalStatus.style.color = "#ff9c9c";
  }
  setButtonsEnabled(true);
}

async function loadProposals() {
  if (!providerContracts.governor || !elements.proposalList) {
    if (elements.proposalList)
      elements.proposalList.textContent = "Governor contract unavailable.";
    return;
  }
  try {
    const filter = providerContracts.governor.filters.ProposalCreated();
    const events = await providerContracts.governor.queryFilter(filter, -50000);
    if (!events.length) {
      elements.proposalList.textContent = "No proposals available.";
      return;
    }
    const recentEvents = events.slice(-5).reverse();
    elements.proposalList.innerHTML = "";

    for (const event of recentEvents) {
      const proposalId = event.args.proposalId;
      const targets = event.args.targets || [];
      const targetHtml = targets.length
        ? targets
            .slice(0, 3)
            .map((address) => renderAddress(address))
            .join(", ")
        : "n/a";
      const stateId = await providerContracts.governor.state(proposalId);
      const stateLabel = getStateLabel(Number(stateId));

      const card = document.createElement("div");
      card.className = "proposal-card";

      card.innerHTML = `
        <div class="proposal-meta">
          <span><strong>ID:</strong> ${proposalId.toString().slice(0, 8)}...</span>
          <span class="badge">${stateLabel}</span>
        </div>
        <div class="proposal-targets"><strong>Targets:</strong> ${targetHtml}</div>
        <div class="proposal-actions"></div>
      `;

      const actionArea = card.querySelector(".proposal-actions");
      if (stateLabel === "Active") {
        const voteForButton = document.createElement("button");
        voteForButton.textContent = "Vote For";
        voteForButton.onclick = () => castVote(proposalId, 1);
        actionArea.appendChild(voteForButton);

        const voteAgainstButton = document.createElement("button");
        voteAgainstButton.textContent = "Vote Against";
        voteAgainstButton.onclick = () => castVote(proposalId, 0);
        actionArea.appendChild(voteAgainstButton);

        const abstainButton = document.createElement("button");
        abstainButton.textContent = "Abstain";
        abstainButton.onclick = () => castVote(proposalId, 2);
        actionArea.appendChild(abstainButton);
      } else {
        actionArea.innerHTML =
          '<span style="color:#888; font-size:12px;">Voting Closed</span>';
      }

      elements.proposalList.appendChild(card);
    }
  } catch (error) {
    elements.proposalList.textContent = "Failed to load proposals";
    console.error(error);
  }
}

async function fetchSubgraph() {
  const endpoint =
    elements.subgraphEndpoint.value.trim() || config.graphDefault;
  if (!endpoint || !elements.graphResult) return;
  try {
    setMessage("Querying subgraph...");
    const query = `query LatestSwaps { swaps(first: 5, orderBy: amountIn, orderDirection: desc) { id user tokenIn tokenOut amountIn amountOut timestamp } }`;
    const response = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ query }),
    });
    const result = await response.json();
    if (result.errors) {
      elements.graphResult.textContent =
        "Graph query error: " + result.errors[0]?.message;
      setMessage("Graph query returned errors.", "error");
      return;
    }
    const swaps = result.data?.swaps || [];
    if (!swaps.length) {
      await loadOnchainSwaps(
        "Subgraph has no indexed swaps for this deployment yet.",
      );
      return;
    }
    const rows = swaps
      .map(
        (swap) =>
          `- Swap ${swap.id.slice(0, 6)}: ${formatAddress(swap.user)} swapped ${formatBig(swap.amountIn)} → ${formatBig(swap.amountOut)}`,
      )
      .join("\n");
    elements.graphResult.textContent = rows;
    setMessage("Subgraph data loaded.", "success");
  } catch (error) {
    await loadOnchainSwaps(
      "Subgraph request failed: " + getErrorMessage(error),
    );
  }
}

async function loadOnchainSwaps(prefix) {
  if (!providerContracts.amm || !elements.graphResult) return;
  try {
    const filter = providerContracts.amm.filters.Swap();
    const events = await providerContracts.amm.queryFilter(filter, -50000);
    const recent = events.slice(-5).reverse();

    if (!recent.length) {
      elements.graphResult.textContent = `${prefix}\nNo on-chain Swap events found in the latest blocks.`;
      setMessage("No indexed or recent on-chain swaps found.", "info");
      return;
    }

    const rows = recent
      .map((event) => {
        const args = event.args;
        return `- On-chain swap ${event.transactionHash.slice(0, 10)}: ${formatAddress(args.user)} swapped ${formatBig(args.amountIn)} -> ${formatBig(args.amountOut)}`;
      })
      .join("\n");

    elements.graphResult.textContent = `${prefix}\nShowing latest on-chain AMM events instead:\n${rows}`;
    setMessage("Loaded latest on-chain AMM swap events.", "success");
  } catch (error) {
    elements.graphResult.textContent = `${prefix}\nOn-chain fallback failed: ${getErrorMessage(error)}`;
    setMessage("Could not load subgraph or on-chain swaps.", "error");
  }
}

async function castVote(proposalId, support) {
  if (!signer) {
    setMessage("Connect wallet first.", "error");
    return;
  }
  if (!(await checkNetwork())) {
    setMessage("Switch to the required network before voting.", "error");
    return;
  }
  try {
    setStatus("Sending vote...");
    const contract = providerContracts.governor.connect(signer);
    const tx = await contract.castVote(proposalId, support);
    setMessage("Vote transaction broadcast. Waiting confirmation...");
    await tx.wait();
    setMessage("Vote confirmed.", "success");
    await loadProposals();
    await loadUserData();
  } catch (error) {
    setMessage("Vote failed: " + getErrorMessage(error), "error");
  } finally {
    setStatus("Ready");
  }
}

async function handleDeposit() {
  const amountValue = elements.depositAmount.value.trim();
  if (!amountValue || Number(amountValue) <= 0) {
    setMessage("Enter a deposit amount.", "error");
    return;
  }
  if (!signer) {
    setMessage("Connect wallet first.", "error");
    return;
  }
  if (!(await checkNetwork())) {
    setMessage("Switch to the required network before depositing.", "error");
    return;
  }
  try {
    if (!vaultAssetAddress)
      vaultAssetAddress = await providerContracts.vault.asset();
    const amount = ethers.parseUnits(amountValue, 18);
    const tokenContract = new ethers.Contract(
      vaultAssetAddress,
      abis.erc20,
      signer,
    );
    const tokenSymbol = await tokenContract.symbol().catch(() => "asset");
    const assetBalance = await tokenContract.balanceOf(userAddress);
    if (assetBalance < amount) {
      setMessage(
        `Not enough ${tokenSymbol} for vault deposit. Balance: ${formatBig(assetBalance, 18)}.`,
        "error",
      );
      return;
    }

    setStatus("Checking allowance...");
    let allowance = 0n;
    try {
      allowance = await tokenContract.allowance(userAddress, config.gameVault);
    } catch (err) {
      console.warn(err);
    }

    if (allowance < amount) {
      setStatus("Approving vault...");
      const approval = await tokenContract.approve(
        config.gameVault,
        amount,
        await getTxOverrides(),
      );
      setMessage("Vault approval submitted. Waiting confirmation...");
      await approval.wait();
      setMessage("Vault approved. Sending deposit...");
    }

    setStatus("Depositing...");
    const vaultWithSigner = providerContracts.vault.connect(signer);
    const tx = await vaultWithSigner.deposit(
      amount,
      userAddress,
      await getTxOverrides(),
    );
    await tx.wait();
    setMessage("Deposit confirmed.", "success");
    await loadUserData();
    await loadProtocolData();
  } catch (error) {
    setMessage("Deposit failed: " + getErrorMessage(error), "error");
  } finally {
    setStatus("Ready");
  }
}

async function handleSwap() {
  const amountValue = elements.swapAmount.value.trim();
  if (!amountValue || Number(amountValue) <= 0) {
    setMessage("Enter a swap amount.", "error");
    return;
  }
  if (!signer) {
    setMessage("Connect wallet first.", "error");
    return;
  }
  if (!(await checkNetwork())) {
    setMessage("Switch to the required network before swapping.", "error");
    return;
  }
  try {
    const [reserveA, reserveB] = await Promise.all([
      providerContracts.amm.reserveA(),
      providerContracts.amm.reserveB(),
    ]);
    if (reserveA === 0n || reserveB === 0n) {
      ammHasLiquidity = false;
      if (elements.swapButton) elements.swapButton.disabled = true;
      setMessage(
        "Swap unavailable: AMM reserves are 0. Add liquidity first or use an AMM deployment with funded reserves.",
        "error",
      );
      return;
    }

    const amount = ethers.parseUnits(amountValue, 18);
    const amm = providerContracts.amm.connect(signer);
    const tokenA = await providerContracts.amm.tokenA();
    const tokenB = await providerContracts.amm.tokenB();
    const dexToken = new ethers.Contract(tokenA, abis.erc20, signer);
    const tokenSymbol = await dexToken.symbol().catch(() => "token A");
    const tokenBalance = await dexToken.balanceOf(userAddress);
    if (tokenBalance < amount) {
      setMessage(
        `Not enough ${tokenSymbol} to swap. Balance: ${formatBig(tokenBalance, 18)}.`,
        "error",
      );
      return;
    }

    setStatus("Checking token allowance...");
    let allowance = 0n;
    try {
      allowance = await dexToken.allowance(userAddress, config.resourceAmm);
    } catch (err) {
      console.warn(err);
    }

    if (allowance < amount) {
      setStatus("Approving AMM...");
      const approval = await dexToken.approve(
        config.resourceAmm,
        amount,
        await getTxOverrides(),
      );
      setMessage("AMM approval submitted. Waiting confirmation...");
      await approval.wait();
      setMessage("AMM approved. Sending swap...");
    }

    setStatus("Calculating slippage...");
    const estimated = await providerContracts.amm
      .getAmountOut(amount, tokenA, tokenB)
      .catch(() => null);

    const minAmountOut = estimated ? (BigInt(estimated) * 98n) / 100n : 0n;

    setStatus("Swapping...");
    const tx = await amm.swap(
      tokenA,
      tokenB,
      amount,
      minAmountOut,
      await getTxOverrides(),
    );
    await tx.wait();
    setMessage("Swap confirmed.", "success");
    await loadProtocolData();
    await loadUserData();
  } catch (error) {
    setMessage("Swap failed: " + getErrorMessage(error), "error");
  } finally {
    setStatus("Ready");
  }
}

async function handleDelegate() {
  const delegatee = elements.delegateInput.value.trim();
  if (!delegatee || !ethers.isAddress(delegatee)) {
    setMessage("Enter a valid delegate EVM address.", "error");
    return;
  }
  if (!signer) {
    setMessage("Connect wallet first.", "error");
    return;
  }
  if (!(await checkNetwork())) {
    setMessage("Switch to the required network before delegating.", "error");
    return;
  }
  try {
    setStatus("Delegating...");
    const tokenWithSigner = providerContracts.token.connect(signer);
    const tx = await tokenWithSigner.delegate(
      delegatee,
      await getTxOverrides(),
    );
    await tx.wait();
    setMessage("Delegate confirmed.", "success");
    await loadUserData();
  } catch (error) {
    setMessage("Delegate failed: " + getErrorMessage(error), "error");
  } finally {
    setStatus("Ready");
  }
}

async function handleCraft() {
  const recipe = craftRecipes[Number(elements.craftRecipeSelect.value)];
  if (!recipe) {
    setMessage("Select a recipe.", "error");
    return;
  }
  if (!signer) {
    setMessage("Connect wallet first.", "error");
    return;
  }
  if (!(await checkNetwork())) {
    setMessage("Switch to the required network.", "error");
    return;
  }
  try {
    setStatus("Checking ingredients...");
    const gameItemsWithSigner = providerContracts.gameItems.connect(signer);
    const ingredientIds = await getCraftIngredients(recipe);
    const missing = [];
    for (const ingredientId of ingredientIds) {
      const balance = await providerContracts.gameItems.balanceOf(
        userAddress,
        ingredientId,
      );
      if (balance < 1n)
        missing.push(itemById[ingredientId]?.name || `Item ${ingredientId}`);
    }
    if (missing.length) {
      setMessage(
        `Missing ingredients: ${missing.join(", ")}. Open loot boxes first.`,
        "error",
      );
      return;
    }

    setStatus("Crafting...");
    const ingredients = ingredientIds.map((id) => BigInt(id));
    try {
      await gameItemsWithSigner.craft.staticCall(
        ingredients,
        BigInt(recipe.resultId),
      );
    } catch (error) {
      setMessage(
        `Craft simulation failed for ${recipe.name}. Contract recipe: ${ingredientIds.join(" + ")} -> ${recipe.resultId}. ${getErrorMessage(error)}`,
        "error",
      );
      return;
    }
    const tx = await gameItemsWithSigner.craft(
      ingredients,
      BigInt(recipe.resultId),
      await getTxOverrides(),
    );
    await tx.wait();
    setMessage(
      `Craft successful: ${recipe.name} #${recipe.resultId} created.`,
      "success",
    );
    await loadInventory();
  } catch (error) {
    setMessage("Craft failed: " + getErrorMessage(error), "error");
  } finally {
    setStatus("Ready");
  }
}

async function handleDepositItem() {
  const tokenIdRaw = elements.rentalTokenId.value.trim();
  const amountRaw = elements.rentalAmount.value.trim();
  if (!tokenIdRaw || !amountRaw) {
    setMessage("Enter token ID and amount.", "error");
    return;
  }
  if (!signer) {
    setMessage("Connect wallet first.", "error");
    return;
  }
  if (!(await checkNetwork())) {
    setMessage("Switch to the required network.", "error");
    return;
  }
  try {
    const tokenId = parsePositiveWholeBigInt(tokenIdRaw, "Token ID");
    const amount = parsePositiveWholeBigInt(amountRaw, "Amount");

    await checkRentalVaultCompatibility();
    if (!rentalVaultCompatible) {
      setMessage(
        "Rental deposit blocked: this RentalVault was deployed for an older GameItems contract.",
        "error",
      );
      return;
    }

    const owned = await providerContracts.gameItems.balanceOf(
      userAddress,
      tokenId,
    );
    if (owned < amount) {
      setMessage(
        `Not enough item #${tokenId}. Owned: ${owned.toString()}, requested deposit: ${amount}.`,
        "error",
      );
      return;
    }

    setStatus("Checking items approval...");
    const gameItemsWithSigner = providerContracts.gameItems.connect(signer);
    const isApproved = await gameItemsWithSigner.isApprovedForAll(
      userAddress,
      config.rentalVault,
    );

    if (!isApproved) {
      setStatus("Approving rental vault...");
      const approveTx = await gameItemsWithSigner.setApprovalForAll(
        config.rentalVault,
        true,
        await getTxOverrides(),
      );
      setMessage("Rental vault approval submitted. Waiting confirmation...");
      await approveTx.wait();
      setMessage("Rental vault approved. Sending deposit...");
    }

    setStatus("Depositing item...");
    const rentalWithSigner = providerContracts.rentalVault.connect(signer);
    const tx = await rentalWithSigner.deposit(
      tokenId,
      amount,
      await getTxOverrides(),
    );
    await tx.wait();
    setMessage("Item deposited to rental vault.", "success");
    await loadInventory();
    await loadRentalBalances();
  } catch (error) {
    setMessage("Deposit item failed: " + getErrorMessage(error), "error");
  } finally {
    setStatus("Ready");
  }
}

async function handleRentItem() {
  const tokenIdRaw = elements.rentalTokenId.value.trim();
  if (!tokenIdRaw) {
    setMessage("Enter token ID to rent.", "error");
    return;
  }
  if (!signer) {
    setMessage("Connect wallet first.", "error");
    return;
  }
  if (!(await checkNetwork())) {
    setMessage("Switch to the required network.", "error");
    return;
  }
  try {
    const tokenId = parsePositiveWholeBigInt(tokenIdRaw, "Token ID");

    await checkRentalVaultCompatibility();
    if (!rentalVaultCompatible) {
      setMessage(
        "Rent blocked: this RentalVault was deployed for an older GameItems contract.",
        "error",
      );
      return;
    }

    const deposited =
      await providerContracts.rentalVault.depositedAmounts(tokenId);
    if (deposited === 0n) {
      setMessage(
        `Item #${tokenId} is not deposited in the rental vault yet.`,
        "error",
      );
      return;
    }

    setStatus("Renting item...");
    const renterAddress = "0x0000000000000000000000000000000000000789";
    const rentalWithSigner = providerContracts.rentalVault.connect(signer);
    const tx = await rentalWithSigner.rent(
      tokenId,
      renterAddress,
      86400n,
      await getTxOverrides(),
    );
    await tx.wait();
    setMessage("Item rented successfully.", "success");
  } catch (error) {
    setMessage("Rent failed: " + getErrorMessage(error), "error");
  } finally {
    setStatus("Ready");
  }
}

async function handleRequestLoot() {
  if (!providerContracts.lootBoxVrf) {
    setMessage(
      "LootBoxVRF is not deployed/configured in frontend config.",
      "error",
    );
    return;
  }
  if (!signer) {
    setMessage("Connect wallet first.", "error");
    return;
  }
  if (!(await checkNetwork())) {
    setMessage("Switch to the required network.", "error");
    return;
  }
  try {
    setStatus("Requesting VRF loot...");
    if (elements.lootResult)
      elements.lootResult.textContent =
        "Request sent. Waiting for transaction confirmation...";
    const lootWithSigner = providerContracts.lootBoxVrf.connect(signer);
    const tx = await lootWithSigner.requestLoot(await getTxOverrides());
    const receipt = await tx.wait();

    let requestId = null;
    for (const log of receipt.logs) {
      try {
        const parsed = providerContracts.lootBoxVrf.interface.parseLog(log);
        if (parsed?.name === "LootRequested") requestId = parsed.args.requestId;
      } catch {}
    }

    if (requestId && elements.lastLootRequest)
      elements.lastLootRequest.textContent = requestId.toString();
    if (elements.lootResult)
      elements.lootResult.textContent =
        "VRF request confirmed. Fulfillment can take a few minutes.";
    setMessage(
      "Loot request confirmed. Wait for Chainlink fulfillment.",
      "success",
    );
  } catch (error) {
    setMessage("Loot request failed: " + getErrorMessage(error), "error");
    if (elements.lootResult)
      elements.lootResult.textContent = getErrorMessage(error);
  } finally {
    setStatus("Ready");
  }
}

function getErrorMessage(error) {
  if (!error) return "Unknown error";
  if (typeof error === "string") return error;
  if (error.reason) return error.reason;
  if (error.shortMessage) return error.shortMessage;
  if (error.info?.error?.data?.message) return error.info.error.data.message;
  if (error.info?.error?.message) return error.info.error.message;
  if (error.error?.data?.message) return error.error.data.message;
  if (error.error?.message) return error.error.message;
  if (error.message) return error.message;
  if (error.data?.message) return error.data.message;
  return String(error);
}

async function mintTestToken(tokenAddress, label) {
  const token = new ethers.Contract(tokenAddress, abis.erc20, signer);
  const tx = await token.testMint(await getTxOverrides());
  setMessage(`${label} test mint submitted. Waiting confirmation...`);
  await tx.wait();
}

async function handleMintSwapTokens() {
  if (!signer) {
    setMessage("Connect wallet first.", "error");
    return;
  }
  if (!(await checkNetwork())) {
    setMessage("Switch to the required network before minting.", "error");
    return;
  }
  try {
    if (!ammTokenAAddress || !ammTokenBAddress) {
      ammTokenAAddress = await providerContracts.amm.tokenA();
      ammTokenBAddress = await providerContracts.amm.tokenB();
    }

    setStatus("Minting AMM test tokens...");
    await mintTestToken(ammTokenAAddress, "Token A");
    await mintTestToken(ammTokenBAddress, "Token B");
    setMessage("AMM test tokens minted.", "success");
    await loadUserData();
    await loadAmmBalances();
  } catch (error) {
    setMessage(
      "AMM test mint failed: " +
        getErrorMessage(error) +
        ". Redeploy tokens with GovernanceToken.testMint() first.",
      "error",
    );
  } finally {
    setStatus("Ready");
  }
}

async function handleAddLiquidity() {
  const amountAValue = elements.liquidityAmountA?.value.trim();
  const amountBValue = elements.liquidityAmountB?.value.trim();
  if (
    !amountAValue ||
    !amountBValue ||
    Number(amountAValue) <= 0 ||
    Number(amountBValue) <= 0
  ) {
    setMessage("Enter liquidity amounts for both AMM tokens.", "error");
    return;
  }
  if (!signer) {
    setMessage("Connect wallet first.", "error");
    return;
  }
  if (!(await checkNetwork())) {
    setMessage(
      "Switch to the required network before adding liquidity.",
      "error",
    );
    return;
  }
  try {
    if (!ammTokenAAddress || !ammTokenBAddress) {
      ammTokenAAddress = await providerContracts.amm.tokenA();
      ammTokenBAddress = await providerContracts.amm.tokenB();
    }

    const amountA = ethers.parseUnits(amountAValue, 18);
    const amountB = ethers.parseUnits(amountBValue, 18);
    const tokenA = new ethers.Contract(ammTokenAAddress, abis.erc20, signer);
    const tokenB = new ethers.Contract(ammTokenBAddress, abis.erc20, signer);

    for (const [token, amount, label] of [
      [tokenA, amountA, "Token A"],
      [tokenB, amountB, "Token B"],
    ]) {
      const balance = await token.balanceOf(userAddress);
      if (balance < amount) {
        setMessage(`Not enough ${label}. Mint test AMM tokens first.`, "error");
        return;
      }
      const allowance = await token.allowance(userAddress, config.resourceAmm);
      if (allowance < amount) {
        setStatus(`Approving ${label}...`);
        const approval = await token.approve(
          config.resourceAmm,
          amount,
          await getTxOverrides(),
        );
        await approval.wait();
      }
    }

    setStatus("Adding AMM liquidity...");
    const amm = providerContracts.amm.connect(signer);
    const tx = await amm.addLiquidity(amountA, amountB, await getTxOverrides());
    await tx.wait();
    setMessage("AMM liquidity added. Swaps are available now.", "success");
    await loadProtocolData();
    await loadAmmBalances();
  } catch (error) {
    setMessage("Add liquidity failed: " + getErrorMessage(error), "error");
  } finally {
    setStatus("Ready");
  }
}

async function handleMintGovernance() {
  if (!signer) {
    setMessage("Connect wallet first.", "error");
    return;
  }
  if (!(await checkNetwork())) {
    setMessage("Switch to the required network before minting.", "error");
    return;
  }
  try {
    setStatus("Minting test GFI...");
    await mintTestToken(config.governanceToken, "GFI");
    setMessage(
      "Test GFI minted. Delegate to yourself to activate voting power.",
      "success",
    );
    await loadUserData();
  } catch (error) {
    setMessage(
      "GFI test mint failed: " +
        getErrorMessage(error) +
        ". The currently configured token was deployed before testMint existed.",
      "error",
    );
  } finally {
    setStatus("Ready");
  }
}

async function connectMetaMask() {
  try {
    if (!window.ethereum) {
      setMessage("MetaMask is not installed.", "error");
      return;
    }
    provider = new ethers.BrowserProvider(window.ethereum, "any");
    await provider.send("eth_requestAccounts", []);
    signer = await provider.getSigner();
    userAddress = await signer.getAddress();
    connectedProviderType = "metamask";
    await postConnect();
  } catch (error) {
    setMessage(
      "MetaMask connection failed: " + getErrorMessage(error),
      "error",
    );
  }
}

async function connectWalletConnect() {
  try {
    if (!window.WalletConnectProvider?.default) {
      setMessage("WalletConnect library bundle missing.", "error");
      return;
    }
    const wcProvider = new window.WalletConnectProvider.default({
      rpc: config.rpc,
    });
    await wcProvider.enable();
    provider = new ethers.BrowserProvider(wcProvider, "any");
    signer = await provider.getSigner();
    userAddress = await signer.getAddress();
    connectedProviderType = "walletconnect";
    await postConnect();
  } catch (error) {
    setMessage("WalletConnect failed: " + getErrorMessage(error), "error");
  }
}

async function postConnect() {
  updateUIConnected();
  setStatus("Connected");
  await initializeContracts();
  const ok = await checkNetwork();
  if (!ok) {
    setMessage("Wrong network connected. Please switch to Arbitrum.", "error");
    setButtonsEnabled(false);
  } else {
    setButtonsEnabled(true);
    setMessage("Ready", "success");
    await loadAvailableItems();
    await loadUserData();
    await loadProtocolData();
    await checkRentalVaultCompatibility();
    await loadRentalBalances();
    await loadProposals();
    await fetchSubgraph();
    watchLootEvents();
  }
}

function setupEventListeners() {
  elements.connectMetaMask?.addEventListener("click", connectMetaMask);
  elements.connectWalletConnect?.addEventListener(
    "click",
    connectWalletConnect,
  );
  elements.switchNetworkButton?.addEventListener("click", switchNetwork);
  elements.depositButton?.addEventListener("click", handleDeposit);
  elements.swapButton?.addEventListener("click", handleSwap);
  elements.mintSwapTokensButton?.addEventListener(
    "click",
    handleMintSwapTokens,
  );
  elements.addLiquidityButton?.addEventListener("click", handleAddLiquidity);
  elements.mintGovernanceButton?.addEventListener(
    "click",
    handleMintGovernance,
  );
  elements.delegateButton?.addEventListener("click", handleDelegate);
  elements.refreshGraph?.addEventListener("click", fetchSubgraph);
  elements.craftButton?.addEventListener("click", handleCraft);
  elements.craftRecipeSelect?.addEventListener("change", updateCraftRecipeInfo);
  elements.depositItemButton?.addEventListener("click", handleDepositItem);
  elements.rentItemButton?.addEventListener("click", handleRentItem);
  elements.rentalTokenId?.addEventListener("input", loadRentalBalances);
  elements.lootButton?.addEventListener("click", handleRequestLoot);

  if (elements.subgraphEndpoint)
    elements.subgraphEndpoint.value = config.graphDefault;

  if (window.ethereum) {
    window.ethereum.on("accountsChanged", async () => {
      if (connectedProviderType === "metamask") await connectMetaMask();
    });
    window.ethereum.on("chainChanged", async () => {
      if (connectedProviderType === "metamask") await connectMetaMask();
    });
  }
  setupCopyAddress();
}

setupEventListeners();
updateCraftRecipeInfo();
setStatus("Ready");
setButtonsEnabled(false);
