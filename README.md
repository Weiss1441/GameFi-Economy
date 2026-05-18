# WEEK 6

# Blockchain Technologies 2 FINAL PROJECT
## Team Members: Darya Dmukhailo, Nurym Muratov
### Topic:GameFi Economy
#### an ERC-1155 in-game item economy with crafting, a marketplace AMM for fungible resources, an NFT rental vault, Chainlink VRF for loot drops, DAO-governed game parameters (drop rates,crafting costs), L2 deployment.

# WEEK 7

# Project Setup & Initialization

## Installation process

### Initialize npm project
- npm init -y

### Install frontend dependencies (for later)
- npm install --save-dev typescript @types/node

### Initialize Foundry project
- forge init --force

### Install OpenZeppelin contracts (ERC standards, access control, security)
- forge install OpenZeppelin/openzeppelin-contracts

### Install Chainlink contracts (VRF, oracles)
- forge install smartcontractkit/chainlink

### Install Foundry standard library (testing utilities)
- forge install foundry-rs/forge-std

## Core Contracts
- src/game/GameItems.sol - ERC-1155 in-game items with crafting system
- src/game/ResourceAMM.sol - Constant product AMM for fungible resources (x·y=k, 0.3% fee)
- src/game/RentalVault.sol - NFT rental mechanism with time-locked rentals
- src/game/GameParameters.sol - DAO-governed game settings (drop rates, crafting costs)
- src/interfaces/*.sol - Contract interfaces for loose coupling
 - src/vault/GameVaultV1.sol - Upgradeable vault implementation (UUPS)
 - src/vault/GameVaultV2.sol - Vault V2 extends V1 with reserve ratio and additional view helpers

## Commands

### Compile all contracts
forge build

### Run full test suite
forge test

### Generate coverage report
forge coverage

## Test Results
- All tests passed: 20/20
- Coverage >80%



# WEEK 8-9

### Added Components

- GovernanceToken (ERC20Votes + ERC20Permit) 
 - GameVaultV1/V2 (upgradeable vault module)
- GameFactory (CREATE + CREATE2) 
- Yul assembly optimization (sqrt) 

### Test Summary

- All tests passed: 46/46
- Coverage 78.97% 
- Fuzz tests: ResourceAMM swap invariant + GameVault deposit/withdraw
 - Fuzz tests: ResourceAMM swap invariant; UUPS upgrade flow for vault
- Unit tests: All core functions covered

## Commands used in this week

### Dependencies installation

- forge install foundry-rs/forge-stdforge install OpenZeppelin/openzeppelin-contracts-upgradeable 
- forge install OpenZeppelin/openzeppelin-foundry-upgrades

### Tests

- forge test test/GovernanceTokenTest.t.sol
- forge test test/GameVaultV1.t.sol
- forge test test/GameFactory.t.sol
- forge test test/GameGovernor.t.sol
- forge test test/GameItems.t.sol
- forge test test/GameParameters.t.sol
- forge test test/GameVaultUUPS.t.sol
- forge test test/LootBoxVRF.t.sol
- forge test test/PriceFeedOracle.t.sol
- forge test test/RentalVault.t.sol
- forge test test/ResourceAMM.t.sol
- forge test test/fork/Fork.t.sol
- forge test test/invariant/GameVaultV1.invariant.t.sol
- forge test test/invariant/GameVaultV2.invariant.t.sol
- forge test test/invariant/ResourceAMM.invariant.t.sol

121 tests passed, 0 failed, 0 skipped


### Check coverage
- forge coverage --no-match-coverage "script"
 Result: 92.14% (387/420)

# Verified contracts links

- GameParameters - https://sepolia.arbiscan.io/address/0x9AD99854cB4d757a5C684d3951ebCB9edbdA7906
- GameItems - https://sepolia.arbiscan.io/address/0x7ECFB17fae78476Cc0A6Ca7239e87B8C40B61406
- LootBoxVRF - https://sepolia.arbiscan.io/address/0x2B2C850b9094FFF0f2d814BC79ae696b0cBb6006
- RentalVault - https://sepolia.arbiscan.io/address/0x78Af981075BaA5F9d64f84cEC26A9970C9B4404A
- GovernanceToken - https://sepolia.arbiscan.io/address/0x0b437CD552a192A0662B08dc843cC2CaD8704a9c
- SwapTokenB - https://sepolia.arbiscan.io/address/0xfa1C556d095F4d1577F4D53c94C35EF2CF782494
- GameTimelock - https://sepolia.arbiscan.io/address/0xe26E6C5Cb47167627d6bC24705ddDc5a6ec22ACE
- GameGovernor - https://sepolia.arbiscan.io/address/0x95bA2074cd84ea48aAa3DC553e663d98b9a756A4
- GameVault Proxy - https://sepolia.arbiscan.io/address/0xb2572c83406a0824B8557AAFb9FC037070d82041
- GameVault V1 Implementation - https://sepolia.arbiscan.io/address/0xaB2787995106E2fd488f5D9B149d0a4232553357
- GameVault V2 Implementation - https://sepolia.arbiscan.io/address/0xCA232C9AE5033f5FaAb2430841C10dBA22Ac8fF3
- ResourceAMM - https://sepolia.arbiscan.io/address/0xB9d86f7faDDC177C41E1d3de8a7a21127a8018D2
- GameFactory - https://sepolia.arbiscan.io/address/0x2B5B6A06a8f91bd39FDb6B0091388f2B4aBC7e7A
