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



# WEEK 8

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

### Check coverage
- forge coverage --report summary


# Verified contracts links

- GameParameters - https://sepolia.arbiscan.io/address/0x5c2ea5cd66610E12c9DbBe2eCaD0C8cBA47eD81C
- GameItems - https://sepolia.arbiscan.io/address/0xD80D1Ee0ba43f8a38041D636a03E433019AB2050
- RentalVault - https://sepolia.arbiscan.io/address/0x1053F2451536ec532CEe8f7D330d76E6e59180A4
- GovernanceToken - https://sepolia.arbiscan.io/address/0x9cA7f64EC9bC3592510f5da07ab7004696De0A38
- GovernanceToken B - https://sepolia.arbiscan.io/address/0x28488689a2586A9fD3d9da51187C465c9d452240
- GameTimelock - https://sepolia.arbiscan.io/address/0x217f2DaB51fCbb5B1832b503Acab281DAf9984B8
- GameGovernor - https://sepolia.arbiscan.io/address/0x513a9341B3C1CfBb23Dce5C8104D6cE84B61116E
- GameVault V1 Implementation - https://sepolia.arbiscan.io/address/0x74c81daB6653e598C160b34f67eb4F3946F0Cf69
- GameVault V2 Implementation - https://sepolia.arbiscan.io/address/0xCc600591c8F71F09b9D8162aa94f48a0FbF91535
- ResourceAMM - https://sepolia.arbiscan.io/address/0x57eD2c4971c019Ab120fbD6439E336C87CD56166
- GameFactory - https://sepolia.arbiscan.io/address/0x489c16De80001AF2326f20490065209aa65d0538