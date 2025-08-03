# 🦄 Swap Contracts – AMM DEX Smart Contract Implementation

![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue) ![Hardhat](https://img.shields.io/badge/Hardhat-v2-green) ![License](https://img.shields.io/badge/License-MIT-yellow)

A ground-up Swap DApp smart contract system inspired by Uniswap V2. Supports multi-token swaps, liquidity pool creation and management, deterministic pair addresses via CREATE2, and deep liquidity seeding for minimal slippage. I independently built everything: Solidity contracts (ERC20, PairAMM, Factory, Router), Hardhat deployment tooling, local and Sepolia testnet support, automated liquidity initialization, and frontend integration for real swap flows.

## Features
- Automatic deployment of multiple ERC20 test tokens (SwapX, GoldX, EnergyCoin, USDT)  
- CREATE2-based deterministic Pair contract addresses (predictable and unique)  
- Factory that tracks and prevents duplicate pair creation  
- Router that orchestrates addLiquidity and swap logic  
- Deep liquidity pools to simulate large trades with near-zero slippage  
- Support for both local Hardhat development chain and Ethereum Sepolia testnet  
- Frontend integration (wallet connection, approval flow, swap UI)

## Quick Start (Local Development Chain)
1. Install dependencies: `npm install`  
2. Start local Hardhat node: `npx hardhat node`  
3. Deploy contracts and seed liquidity:  
   ```bash
   npx hardhat run scripts/deploy-full-demo.ts --network localhost
   ```

## Testnet Deployment (Sepolia)
1. Create a `.env` file and add your private key (must have Sepolia ETH):  
   `PRIVATE_KEY=0xabc123...your_private_key`  
2. Acquire Sepolia test ETH: https://sepoliafaucet.com/  
3. Deploy:  
   ```bash
   npx hardhat run scripts/deploy-full-demo.ts --network sepolia
   ```

## .env Example
```env
# Use a testnet-only wallet; do NOT use mainnet private keys with real funds.
PRIVATE_KEY=0xabc123...your_private_key
```

## Default Tokens & Rate Design
| Symbol | Rate vs USDT | Description          |
|--------|--------------|----------------------|
| SWX    | 0.001        | Low-price token      |
| GOX    | 0.01         | Mid-tier token       |
| EGC    | 1            | Stable/high-value    |
| USDT   | 1            | Base stablecoin      |

Pools are seeded with deep liquidity (e.g., 10,000,000 units) to emulate realistic large trades with minimal price impact.

## Architecture Overview
ERC20 Tokens → Factory (CREATE2-deployed pair pools) → PairAMM (per-pair internal reserve pools) → Router (unified entry for addLiquidity / swap)

## Frontend Integration
Frontend (e.g., React + wagmi) connects to deployed contracts, manages wallet connection, approvals, slippage configuration, and executes swaps via the Router. Ensure the targeted network (localhost vs Sepolia) matches deployment.

## Troubleshooting
- **Insufficient gas**: Ensure the deployment wallet has enough Sepolia ETH from a faucet.  
- **Missing approval**: Tokens must be approved to the Router before swaps or adding liquidity.  
- **CREATE2 address mismatch**: Deterministic addresses only apply when the same salt and bytecode are used on the same chain; local ephemeral state may differ.  
- **Swap failure / slippage**: Verify the path and reserves in PairAMM; deep liquidity should minimize impact.

## .env Configuration
Create a `.env` file with:  
`PRIVATE_KEY=0xabc123...your_private_key`  
- Local chain uses the first account automatically.  
- Testnet requires a funded private key.  
- Deployments fail without sufficient ETH.

## Security / Scope Note
This implementation is intended for demonstration/testing purposes: no fees, no LP tokens, minimal access control, and lacks production-grade safeguards. Do not use in production without auditing, rate limiting, and upgradeability considerations.

## Author Background
This is a flagship project from my transition from iOS engineer to Web3 engineer. I independently designed and implemented the full stack: smart contract architecture, deployment automation, liquidity initialization, and frontend swap integration. I have hands-on understanding of AMM mechanics (pair creation / add liquidity / swap), deterministic CREATE2 deployments, liquidity depth, and slippage control, and can deploy, debug, and iterate across local and testnet environments. This is not copied—it's built by me.

## License
MIT License. See [LICENSE](./LICENSE) for full text.
