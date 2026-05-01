# Blockchain Technologies 2 FINAL PROJECT
## Team Members: Darya Dmukhailo, Nurym Muratov
### Topic:GameFi Economy
#### an ERC-1155 in-game item economy with crafting, a marketplace AMM for fungible resources, an NFT rental vault, Chainlink VRF for loot drops, DAO-governed game parameters (drop rates,crafting costs), L2 deployment.

# WEEK 6

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