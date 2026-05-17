const REQUIRED_CHAIN_ID = 421614;

const config = {
  governanceToken: '0x9cA7f64EC9bC3592510f5da07ab7004696De0A38',
  gameGovernor: '0x513a9341B3C1CfBb23Dce5C8104D6cE84B61116E',
  resourceAmm: '0x57eD2c4971c019Ab120fbD6439E336C87CD56166',
  gameVault: '0xCC19E02C1A6a97456D942a471516b44a084aA361',
  gameItems: '0xD80D1Ee0ba43f8a38041D636a03E433019AB2050',
  gameParameters: '0x5c2ea5cd66610E12c9DbBe2eCaD0C8cBA47eD81C',
  rentalVault: '0x1053F2451536ec532CEe8f7D330d76E6e59180A4',
  rpc: {
    421614: 'https://sepolia-rollup.arbitrum.io/rpc'
  },
  graphDefault: 'https://api.studio.thegraph.com/query/960/game-fi/v0.0.1'
};

const abis = {
  erc20: [
    'function symbol() view returns (string)',
    'function decimals() view returns (uint8)',
    'function balanceOf(address) view returns (uint256)',
    'function allowance(address,address) view returns (uint256)',
    'function approve(address,uint256) returns (bool)',
    'function delegate(address)',
    'function getVotes(address) view returns (uint256)',
    'function delegates(address) view returns (address)'
  ],
  governor: [
    'function proposalCount() view returns (uint256)',
    'function proposalDetailsAt(uint256) view returns (uint256 proposalId, address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash)',
    'function state(uint256) view returns (uint8)',
    'function castVote(uint256,uint8) returns (uint256)'
  ],
  resourceAmm: [
    'function tokenA() view returns (address)',
    'function tokenB() view returns (address)',
    'function reserveA() view returns (uint256)',
    'function reserveB() view returns (uint256)',
    'function getAmountOut(uint256,address,address) view returns (uint256)',
    'function swap(address,address,uint256,uint256) returns (uint256)'
  ],
  vault: [
    'function asset() view returns (address)',
    'function balanceOf(address) view returns (uint256)',
    'function deposit(uint256,address) returns (uint256)'
  ],
  gameItems: [
    'function balanceOf(address,uint256) view returns (uint256)',
    'function uri(uint256) view returns (string)',
    'function craft(uint256[] ingredients, uint256 recipeId) returns (uint256)',
    'function setApprovalForAll(address operator, bool approved) external',
    'function isApprovedForAll(address account, address operator) view returns (bool)'
  ],
  rentalVault: [
    'function depositedAmounts(uint256) view returns (uint256)',
    'function deposit(uint256 tokenId, uint256 amount) external',
    'function rent(uint256 tokenId, address renter, uint256 duration) external',
    'function isRented(uint256) view returns (bool)'
  ]
};

const elements = {
  connectMetaMask: document.getElementById('connectMetaMask'),
  connectWalletConnect: document.getElementById('connectWalletConnect'),
  chainLabel: document.getElementById('chainLabel'),
  accountLabel: document.getElementById('accountLabel'),
  networkCheck: document.getElementById('networkCheck'),
  statusMessage: document.getElementById('statusMessage'),
  tokenBalance: document.getElementById('tokenBalance'),
  votingPower: document.getElementById('votingPower'),
  delegateAddress: document.getElementById('delegateAddress'),
  vaultShares: document.getElementById('vaultShares'),
  reserveA: document.getElementById('reserveA'),
  reserveB: document.getElementById('reserveB'),
  vaultAsset: document.getElementById('vaultAsset'),
  depositAmount: document.getElementById('depositAmount'),
  swapAmount: document.getElementById('swapAmount'),
  delegateInput: document.getElementById('delegateInput'),
  depositButton: document.getElementById('depositButton'),
  swapButton: document.getElementById('swapButton'),
  delegateButton: document.getElementById('delegateButton'),
  proposalList: document.getElementById('proposalList'),
  subgraphEndpoint: document.getElementById('subgraphEndpoint'),
  refreshGraph: document.getElementById('refreshGraph'),
  graphResult: document.getElementById('graphResult'),
  switchNetworkButton: document.getElementById('switchNetworkButton'),
  messagePanel: document.getElementById('messagePanel'),
  craftButton: document.getElementById('craftButton'),
  craftRecipeSelect: document.getElementById('craftRecipeSelect'),
  rentalTokenId: document.getElementById('rentalTokenId'),
  rentalAmount: document.getElementById('rentalAmount'),
  depositItemButton: document.getElementById('depositItemButton'),
  rentItemButton: document.getElementById('rentItemButton'),
  inventoryList: document.getElementById('inventoryList'),
  availableItemsList: document.getElementById('availableItemsList')
};

let provider = null;
let signer = null;
let userAddress = null;
let currentChainId = null;
let connectedProviderType = null;

const providerContracts = {
  token: null,
  governor: null,
  amm: null,
  vault: null,
  gameItems: null,
  rentalVault: null
};

function setMessage(text, type = 'info') {
  if (!elements.messagePanel) return;
  elements.messagePanel.textContent = text;
  elements.messagePanel.style.color = type === 'error' ? '#ff9c9c' : type === 'success' ? '#a2f7c5' : 'var(--text)';
}

function setStatus(text) {
  if (elements.statusMessage) elements.statusMessage.textContent = text;
}

function formatAddress(address) {
  if (!address || address === '-') return '-';
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

function setupCopyAddress() {
  const copyBtn = document.getElementById('copyAddressBtn');
  if (!copyBtn) return;
  copyBtn.addEventListener('click', async () => {
    if (userAddress) {
      await navigator.clipboard.writeText(userAddress);
      setMessage('Address copied to clipboard', 'success');
      copyBtn.textContent = 'Copied!';
      setTimeout(() => { copyBtn.textContent = 'Copy'; }, 2000);
    }
  });
}

function formatBig(value, decimals = 18) {
  try {
    return ethers.formatUnits(value, decimals);
  } catch {
    return '0';
  }
}

function getStateLabel(state) {
  const mapping = { 0: 'Pending', 1: 'Active', 2: 'Canceled', 3: 'Defeated', 4: 'Succeeded', 5: 'Queued', 6: 'Expired', 7: 'Executed' };
  return mapping[state] ?? `State ${state}`;
}

async function initializeContracts() {
  providerContracts.token = new ethers.Contract(config.governanceToken, abis.erc20, provider);
  providerContracts.governor = new ethers.Contract(config.gameGovernor, abis.governor, provider);
  providerContracts.amm = new ethers.Contract(config.resourceAmm, abis.resourceAmm, provider);
  providerContracts.vault = new ethers.Contract(config.gameVault, abis.vault, provider);
  providerContracts.gameItems = new ethers.Contract(config.gameItems, abis.gameItems, provider);
  providerContracts.rentalVault = new ethers.Contract(config.rentalVault, abis.rentalVault, provider);
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
      elements.networkCheck.textContent = 'Correct network';
      elements.networkCheck.style.color = '#8cff94';
    }
    return true;
  }
  
  if (elements.networkCheck) {
    elements.networkCheck.textContent = `Wrong network, expected ${REQUIRED_CHAIN_ID}`;
    elements.networkCheck.style.color = '#ff8a8a';
  }
  return false;
}

async function switchNetwork() {
  if (!window.ethereum) {
    setMessage('No injected wallet found to switch network.', 'error');
    return;
  }
  const targetHex = '0x' + REQUIRED_CHAIN_ID.toString(16);
  try {
    await window.ethereum.request({ method: 'wallet_switchEthereumChain', params: [{ chainId: targetHex }] });
    setMessage('Network switched — reconnecting...', 'success');
    if (connectedProviderType === 'metamask') await connectMetaMask();
  } catch (err) {
    if (err && err.code === 4902) {
      try {
        await window.ethereum.request({
          method: 'wallet_addEthereumChain',
          params: [{ chainId: targetHex, chainName: 'Arbitrum Sepolia', nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 }, rpcUrls: [config.rpc[REQUIRED_CHAIN_ID] || 'https://sepolia-rollup.arbitrum.io/rpc'], blockExplorerUrls: ['https://sepolia.arbiscan.io'] }]
        });
        setMessage('Network added — please switch.', 'success');
      } catch (addErr) { setMessage('Failed to add network: ' + getErrorMessage(addErr), 'error'); }
    } else { setMessage('Network switch failed: ' + getErrorMessage(err), 'error'); }
  }
}

function updateUIConnected() {
  const displayAddress = userAddress ? formatAddress(userAddress) : '-';
  if (elements.accountLabel) elements.accountLabel.textContent = displayAddress;
  const copyBtn = document.getElementById('copyAddressBtn');
  if (copyBtn) {
    copyBtn.style.display = userAddress ? 'inline-block' : 'none';
  }
}

function setButtonsEnabled(enabled) {
  const btns = [elements.depositButton, elements.swapButton, elements.delegateButton, elements.refreshGraph, elements.craftButton, elements.depositItemButton, elements.rentItemButton];
  btns.forEach(btn => { if (btn) btn.disabled = !enabled; });
}

async function loadInventory() {
  if (!elements.inventoryList) return;
  
  const demoItems = [
    { name: 'Wooden Sword', balance: 3, id: 1 },
    { name: 'Health Potion', balance: 5, id: 2 },
    { name: 'Iron Armor', balance: 1, id: 3 }
  ];
  
  elements.inventoryList.innerHTML = demoItems.map(item => `
    <div class="inventory-item">
      <span>${item.name}</span>
      <span>Quantity: ${item.balance}</span>
    </div>
  `).join('');
}

async function loadAvailableItems() {
  if (!elements.availableItemsList) return;
  
  const availableItems = [
    { id: 1, name: 'Wooden Sword', price: '2x Iron Ore + 1x Wood', rarity: 'Common' },
    { id: 2, name: 'Health Potion', price: '3x Herb + 1x Bottle', rarity: 'Common' },
    { id: 3, name: 'Iron Armor', price: '5x Iron Ore + 2x Leather', rarity: 'Rare' },
    { id: 4, name: 'Dragon Scale', price: 'Mystery Drop', rarity: 'Legendary' },
    { id: 5, name: 'Mystery Chest', price: '100x Gold', rarity: 'Mystic' }
  ];
  
  elements.availableItemsList.innerHTML = availableItems.map(item => `
    <div class="inventory-item">
      <span>${item.name} (ID: ${item.id})</span>
      <span style="font-size:11px; color:#aaa;">${item.price}</span>
    </div>
  `).join('');
}

async function loadUserData() {
  if (!signer || !providerContracts.token) return;
  try {
    const [balance, votes, delegated, vaultShares] = await Promise.all([
      providerContracts.token.balanceOf(userAddress),
      providerContracts.token.getVotes(userAddress),
      providerContracts.token.delegates(userAddress),
      providerContracts.vault.balanceOf(userAddress)
    ]);
    const decimals = await providerContracts.token.decimals();
    const symbol = await providerContracts.token.symbol();
    
    if (elements.tokenBalance) elements.tokenBalance.textContent = `${formatBig(balance, decimals)} ${symbol}`;
    if (elements.votingPower) elements.votingPower.textContent = formatBig(votes, 18);
    if (elements.delegateAddress) elements.delegateAddress.textContent = (delegated && delegated !== ethers.ZeroAddress) ? formatAddress(delegated) : 'None';
    if (elements.vaultShares) elements.vaultShares.textContent = formatBig(vaultShares, 18);
    
    await loadInventory();
  } catch (error) { setMessage('Failed to load account data: ' + getErrorMessage(error), 'error'); }
}

async function loadProtocolData() {
  if (!providerContracts.amm || !providerContracts.vault) return;
  try {
    const [reserveA, reserveB, asset] = await Promise.all([
      providerContracts.amm.reserveA(),
      providerContracts.amm.reserveB(),
      providerContracts.vault.asset()
    ]);
    if (elements.reserveA) elements.reserveA.textContent = formatBig(reserveA, 18);
    if (elements.reserveB) elements.reserveB.textContent = formatBig(reserveB, 18);
    if (elements.vaultAsset) elements.vaultAsset.textContent = formatAddress(asset);
  } catch (error) { setMessage('Failed to load protocol state: ' + getErrorMessage(error), 'error'); }
}

async function loadProposals() {
  if (!providerContracts.governor || !elements.proposalList) { 
    if (elements.proposalList) elements.proposalList.textContent = 'Governor contract unavailable.'; 
    return; 
  }
  try {
    const count = Number(await providerContracts.governor.proposalCount());
    if (count === 0) { 
      elements.proposalList.textContent = 'No proposals available.'; 
      return; 
    }
    const max = Math.min(5, count);
    elements.proposalList.innerHTML = '';
    
    for (let i = 0; i < max; i++) {
      const details = await providerContracts.governor.proposalDetailsAt(i);
      const proposalId = details.proposalId;
      const targets = details.targets;
      const stateId = await providerContracts.governor.state(proposalId);
      const stateLabel = getStateLabel(Number(stateId));
      
      const card = document.createElement('div');
      card.className = 'proposal-card';
      
      card.innerHTML = `
        <div class="proposal-meta">
          <span><strong>ID:</strong> ${proposalId.toString().slice(0, 8)}...</span>
          <span class="badge">${stateLabel}</span>
        </div>
        <div style="font-size: 12px; margin-bottom:8px;"><strong>Targets:</strong> ${targets.slice(0, 2).join(', ') || 'n/a'}</div>
        <div class="proposal-actions"></div>
      `;
      
      const actionArea = card.querySelector('.proposal-actions');
      if (stateLabel === 'Active') {
        const voteForButton = document.createElement('button'); 
        voteForButton.textContent = 'Vote For'; 
        voteForButton.onclick = () => castVote(proposalId, 1);
        actionArea.appendChild(voteForButton);

        const voteAgainstButton = document.createElement('button'); 
        voteAgainstButton.textContent = 'Vote Against'; 
        voteAgainstButton.onclick = () => castVote(proposalId, 0);
        actionArea.appendChild(voteAgainstButton);
        
        const abstainButton = document.createElement('button'); 
        abstainButton.textContent = 'Abstain'; 
        abstainButton.onclick = () => castVote(proposalId, 2);
        actionArea.appendChild(abstainButton);
      } else {
        actionArea.innerHTML = '<span style="color:#888; font-size:12px;">Voting Closed</span>';
      }
      
      elements.proposalList.appendChild(card);
    }
  } catch (error) { 
    elements.proposalList.textContent = 'Failed to load proposals'; 
    console.error(error);
  }
}

async function fetchSubgraph() {
  const endpoint = elements.subgraphEndpoint.value.trim() || config.graphDefault;
  if (!endpoint || !elements.graphResult) return;
  try {
    setMessage('Querying subgraph...');
    const query = `query LatestSwaps { swaps(first: 5, orderBy: amountIn, orderDirection: desc) { id user tokenIn tokenOut amountIn amountOut timestamp } }`;
    const response = await fetch(endpoint, { 
      method: 'POST', 
      headers: { 'Content-Type': 'application/json' }, 
      body: JSON.stringify({ query }) 
    });
    const result = await response.json();
    if (result.errors) { 
      elements.graphResult.textContent = 'Graph query error: ' + result.errors[0]?.message; 
      setMessage('Graph query returned errors.', 'error'); 
      return; 
    }
    const swaps = result.data?.swaps || [];
    if (!swaps.length) { 
      elements.graphResult.textContent = 'No swaps returned by subgraph.'; 
      setMessage('Subgraph query completed.', 'success'); 
      return; 
    }
    const rows = swaps.map(swap => `- Swap ${swap.id.slice(0,6)}: ${formatAddress(swap.user)} swapped ${formatBig(swap.amountIn)} → ${formatBig(swap.amountOut)}`).join('\n');
    elements.graphResult.textContent = rows;
    setMessage('Subgraph data loaded.', 'success');
  } catch (error) { 
    elements.graphResult.textContent = 'Graph fetch failed.'; 
    setMessage('Subgraph request failed: ' + getErrorMessage(error), 'error'); 
  }
}

async function castVote(proposalId, support) {
  if (!signer) { setMessage('Connect wallet first.', 'error'); return; }
  if (!(await checkNetwork())) { setMessage('Switch to the required network before voting.', 'error'); return; }
  try {
    setStatus('Sending vote...');
    const contract = providerContracts.governor.connect(signer);
    const tx = await contract.castVote(proposalId, support);
    setMessage('Vote transaction broadcast. Waiting confirmation...');
    await tx.wait();
    setMessage('Vote confirmed.', 'success');
    await loadProposals();
    await loadUserData();
  } catch (error) { setMessage('Vote failed: ' + getErrorMessage(error), 'error'); } finally { setStatus('Ready'); }
}

async function handleDeposit() {
  const amountValue = elements.depositAmount.value.trim();
  if (!amountValue || Number(amountValue) <= 0) { setMessage('Enter a deposit amount.', 'error'); return; }
  if (!signer) { setMessage('Connect wallet first.', 'error'); return; }
  if (!(await checkNetwork())) { setMessage('Switch to the required network before depositing.', 'error'); return; }
  try {
    const amount = ethers.parseUnits(amountValue, 18);
    const tokenContract = new ethers.Contract(config.governanceToken, abis.erc20, signer);
    
    setStatus('Checking allowance...');
    let allowance = 0n;
    try { allowance = await tokenContract.allowance(userAddress, config.gameVault); } catch (err) { console.warn(err); }
    
    if (allowance < amount) {
      setStatus('Approving vault...');
      const approval = await tokenContract.approve(config.gameVault, amount);
      await approval.wait();
    }
    
    setStatus('Depositing...');
    const vaultWithSigner = providerContracts.vault.connect(signer);
    const tx = await vaultWithSigner.deposit(amount, userAddress);
    await tx.wait();
    setMessage('Deposit confirmed.', 'success');
    await loadUserData();
    await loadProtocolData();
  } catch (error) { setMessage('Deposit failed: ' + getErrorMessage(error), 'error'); } finally { setStatus('Ready'); }
}

async function handleSwap() {
  const amountValue = elements.swapAmount.value.trim();
  if (!amountValue || Number(amountValue) <= 0) { setMessage('Enter a swap amount.', 'error'); return; }
  if (!signer) { setMessage('Connect wallet first.', 'error'); return; }
  if (!(await checkNetwork())) { setMessage('Switch to the required network before swapping.', 'error'); return; }
  try {
    const amount = ethers.parseUnits(amountValue, 18);
    const amm = providerContracts.amm.connect(signer);
    const tokenA = await providerContracts.amm.tokenA();
    const tokenB = await providerContracts.amm.tokenB();
    const dexToken = new ethers.Contract(tokenA, abis.erc20, signer);
    
    setStatus('Checking token allowance...');
    let allowance = 0n;
    try { allowance = await dexToken.allowance(userAddress, config.resourceAmm); } catch (err) { console.warn(err); }
    
    if (allowance < amount) {
      setStatus('Approving AMM...');
      const approval = await dexToken.approve(config.resourceAmm, amount);
      await approval.wait();
    }
    
    setStatus('Calculating slippage...');
    const estimated = await providerContracts.amm.getAmountOut(amount, tokenA, tokenB).catch(() => null);
    
    const minAmountOut = estimated ? (BigInt(estimated) * 98n) / 100n : 0n;
    
    setStatus('Swapping...');
    const tx = await amm.swap(tokenA, tokenB, amount, minAmountOut);
    await tx.wait();
    setMessage('Swap confirmed.', 'success');
    await loadProtocolData();
    await loadUserData();
  } catch (error) { setMessage('Swap failed: ' + getErrorMessage(error), 'error'); } finally { setStatus('Ready'); }
}

async function handleDelegate() {
  const delegatee = elements.delegateInput.value.trim();
  if (!delegatee || !ethers.isAddress(delegatee)) { setMessage('Enter a valid delegate EVM address.', 'error'); return; }
  if (!signer) { setMessage('Connect wallet first.', 'error'); return; }
  if (!(await checkNetwork())) { setMessage('Switch to the required network before delegating.', 'error'); return; }
  try {
    setStatus('Delegating...');
    const tokenWithSigner = providerContracts.token.connect(signer);
    const tx = await tokenWithSigner.delegate(delegatee);
    await tx.wait();
    setMessage('Delegate confirmed.', 'success');
    await loadUserData();
  } catch (error) { setMessage('Delegate failed: ' + getErrorMessage(error), 'error'); } finally { setStatus('Ready'); }
}

async function handleCraft() {
  const recipeId = elements.craftRecipeSelect.value;
  if (!recipeId) { setMessage('Select a recipe.', 'error'); return; }
  if (!signer) { setMessage('Connect wallet first.', 'error'); return; }
  if (!(await checkNetwork())) { setMessage('Switch to the required network.', 'error'); return; }
  try {
    setStatus('Crafting...');
    const ingredients = [1n, 2n];
    const gameItemsWithSigner = providerContracts.gameItems.connect(signer);
    const tx = await gameItemsWithSigner.craft(ingredients, BigInt(recipeId));
    await tx.wait();
    setMessage(`Craft successful, item ${recipeId} created.`, 'success');
    await loadInventory();
  } catch (error) { setMessage('Craft failed: ' + getErrorMessage(error), 'error'); } finally { setStatus('Ready'); }
}

async function handleDepositItem() {
  const tokenId = elements.rentalTokenId.value.trim();
  const amount = elements.rentalAmount.value.trim();
  if (!tokenId || !amount) { setMessage('Enter token ID and amount.', 'error'); return; }
  if (!signer) { setMessage('Connect wallet first.', 'error'); return; }
  if (!(await checkNetwork())) { setMessage('Switch to the required network.', 'error'); return; }
  try {
    setStatus('Checking items approval...');
    const gameItemsWithSigner = providerContracts.gameItems.connect(signer);
    const isApproved = await gameItemsWithSigner.isApprovedForAll(userAddress, config.rentalVault);
    
    if (!isApproved) {
      setStatus('Approving rental vault...');
      const approveTx = await gameItemsWithSigner.setApprovalForAll(config.rentalVault, true);
      await approveTx.wait();
    }
    
    setStatus('Depositing item...');
    const rentalWithSigner = providerContracts.rentalVault.connect(signer);
    const tx = await rentalWithSigner.deposit(BigInt(tokenId), BigInt(amount));
    await tx.wait();
    setMessage('Item deposited to rental vault.', 'success');
    await loadInventory();
  } catch (error) { setMessage('Deposit item failed: ' + getErrorMessage(error), 'error'); } finally { setStatus('Ready'); }
}

async function handleRentItem() {
  const tokenId = elements.rentalTokenId.value.trim();
  if (!tokenId) { setMessage('Enter token ID to rent.', 'error'); return; }
  if (!signer) { setMessage('Connect wallet first.', 'error'); return; }
  if (!(await checkNetwork())) { setMessage('Switch to the required network.', 'error'); return; }
  try {
    setStatus('Renting item...');
    const renterAddress = "0x0000000000000000000000000000000000000789";
    const rentalWithSigner = providerContracts.rentalVault.connect(signer);
    const tx = await rentalWithSigner.rent(BigInt(tokenId), renterAddress, 86400n);
    await tx.wait();
    setMessage('Item rented successfully.', 'success');
  } catch (error) { setMessage('Rent failed: ' + getErrorMessage(error), 'error'); } finally { setStatus('Ready'); }
}

function getErrorMessage(error) {
  if (!error) return 'Unknown error';
  if (typeof error === 'string') return error;
  if (error.info?.error?.message) return error.info.error.message;
  if (error.message) return error.message;
  if (error.data?.message) return error.data.message;
  return String(error);
}

async function connectMetaMask() {
  try {
    if (!window.ethereum) { setMessage('MetaMask is not installed.', 'error'); return; }
    provider = new ethers.BrowserProvider(window.ethereum, 'any');
    await provider.send('eth_requestAccounts', []);
    signer = await provider.getSigner();
    userAddress = await signer.getAddress();
    connectedProviderType = 'metamask';
    await postConnect();
  } catch (error) { setMessage('MetaMask connection failed: ' + getErrorMessage(error), 'error'); }
}

async function connectWalletConnect() {
  try {
    if (!window.WalletConnectProvider?.default) { setMessage('WalletConnect library bundle missing.', 'error'); return; }
    const wcProvider = new window.WalletConnectProvider.default({ rpc: config.rpc });
    await wcProvider.enable();
    provider = new ethers.BrowserProvider(wcProvider, 'any');
    signer = await provider.getSigner();
    userAddress = await signer.getAddress();
    connectedProviderType = 'walletconnect';
    await postConnect();
  } catch (error) { setMessage('WalletConnect failed: ' + getErrorMessage(error), 'error'); }
}

async function postConnect() {
  updateUIConnected();
  setStatus('Connected');
  await initializeContracts();
  const ok = await checkNetwork();
  if (!ok) {
    setMessage('Wrong network connected. Please switch to Arbitrum.', 'error');
    setButtonsEnabled(false);
  } else {
    setButtonsEnabled(true);
    setMessage('Ready', 'success');
    await loadAvailableItems();
    await loadUserData();
    await loadProtocolData();
    await loadProposals();
    await fetchSubgraph();
  }
}

function setupEventListeners() {
  elements.connectMetaMask?.addEventListener('click', connectMetaMask);
  elements.connectWalletConnect?.addEventListener('click', connectWalletConnect);
  elements.switchNetworkButton?.addEventListener('click', switchNetwork);
  elements.depositButton?.addEventListener('click', handleDeposit);
  elements.swapButton?.addEventListener('click', handleSwap);
  elements.delegateButton?.addEventListener('click', handleDelegate);
  elements.refreshGraph?.addEventListener('click', fetchSubgraph);
  elements.craftButton?.addEventListener('click', handleCraft);
  elements.depositItemButton?.addEventListener('click', handleDepositItem);
  elements.rentItemButton?.addEventListener('click', handleRentItem);
  
  if (elements.subgraphEndpoint) elements.subgraphEndpoint.value = config.graphDefault;
  
  if (window.ethereum) {
    window.ethereum.on('accountsChanged', async () => { if (connectedProviderType === 'metamask') await connectMetaMask(); });
    window.ethereum.on('chainChanged', async () => { if (connectedProviderType === 'metamask') await connectMetaMask(); });
  }
  setupCopyAddress();
}

setupEventListeners();
setStatus('Ready');
setButtonsEnabled(false);