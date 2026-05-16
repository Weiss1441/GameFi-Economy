## Yul Assembly Optimization & Benchmarks (ResourceAMM)

The `ResourceAMM` contract utilizes an optimized square root function written in inline assembly (Yul) for calculating liquidity pool shares via the constant product formula (x * y = k). 

Below is the comparative gas analysis generated via Foundry (`forge test --gas-report`) before and after switching the internal `_sqrt` calculation to the Yul execution engine.

### 1. Function Execution Gas Comparison

| Function / Operation | Solidity Execution (Gas) | Yul Assembly Execution (Gas) | Absolute Savings (Gas) | Relative Change (%) |
| :--- | :--- | :--- | :--- | :--- |
| `sqrt` (Standalone call) | 10,708 | 3,172 | 7,536 | **-70.38%** |
| `addLiquidity` (Average) | 212,219 | 199,202 | 13,017 | **-6.13%** |

### 2. Contract Deployment Metrics

| Metric | Before Optimization (Solidity) | After Optimization (Yul) | Savings / Reduction |
| :--- | :--- | :--- | :--- |
| **Deployment Cost** | 900,867 gas | 891,120 gas | 9,747 gas |
| **Deployment Size** | 4,144 bytes | 4,099 bytes | 45 bytes |

