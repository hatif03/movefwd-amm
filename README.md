# Sui AMM with NFT LP Positions

A decentralized Automated Market Maker (AMM) built on the Sui blockchain with NFT-based liquidity provider positions, implementing the constant product formula (x * y = k).

🌐 **Live Demo**: [https://movefwd-amm.vercel.app](https://movefwd-amm.vercel.app)

[![SuiSwap](https://img.shields.io/badge/Live-SuiSwap%20AMM-00d4aa?style=for-the-badge)](https://movefwd-amm.vercel.app)
[![Sui Testnet](https://img.shields.io/badge/Network-Sui%20Testnet-6fbcf0?style=for-the-badge)](https://suiscan.xyz/testnet/object/0x2ece39501958bbccee8d22cad8ed70226148da7df7e6fbc4aa20b5aeb9c0de65)

## Features

### Core AMM Functionality
- **Constant Product Formula**: Classic x * y = k invariant for fair pricing
- **Multiple Fee Tiers**: 0.05%, 0.3%, and 1% fee options
- **Efficient Swaps**: Optimized swap execution with minimal gas costs

### NFT LP Positions
- **Transferable Positions**: LP positions represented as NFTs that can be transferred or sold
- **Dynamic Metadata**: Real-time position value and fee tracking
- **Impermanent Loss Tracking**: Built-in IL calculation for positions

### Stable Swap Pools
- **Lower Slippage**: Optimized curve for stable asset pairs (USDC/USDT, etc.)
- **Amplification Coefficient**: Configurable curve steepness
- **Efficient Stable-to-Stable Swaps**: Better rates for similar-priced assets

### Fee Distribution
- **Automatic Fee Accumulation**: Fees collected on every swap
- **Pro-rata Distribution**: Fair distribution based on LP share
- **Auto-compound Option**: Reinvest fees back into position
- **Protocol Fee Collection**: Configurable protocol fee (10% of trading fees)

### Slippage Protection
- **Minimum Output Enforcement**: Protect against unfavorable swaps
- **Transaction Deadlines**: Time-limited transactions
- **Price Impact Warnings**: Calculate and display price impact
- **Price Limit Orders**: Set target prices for execution

### Web Interface
- **Modern DeFi UI**: Dark theme with professional DEX aesthetics
- **Wallet Integration**: Connect with Sui Wallet via @mysten/dapp-kit
- **Real-time Data**: Live pool reserves, prices, and balances
- **Demo Token Faucet**: Get test tokens to explore the protocol

## Project Structure

```
├── contracts/                    # Move smart contracts
│   ├── sources/
│   │   ├── constants.move        # Protocol constants and configuration
│   │   ├── errors.move           # Error codes
│   │   ├── events.move           # Event definitions
│   │   ├── math.move             # AMM math utilities
│   │   ├── lp_position_nft.move  # NFT-based LP positions
│   │   ├── pool_factory.move     # Pool creation and management
│   │   ├── stable_swap_pool.move # Stable swap implementation
│   │   ├── fee_distributor.move  # Fee distribution logic
│   │   ├── slippage_protection.move # Slippage management
│   │   └── demo_tokens.move      # Demo tokens for testing
│   ├── tests/                    # Move unit tests
│   └── Move.toml                 # Package configuration
│
├── frontend/                     # Next.js web application
│   ├── src/
│   │   ├── app/                  # Next.js App Router pages
│   │   │   ├── page.tsx          # Dashboard
│   │   │   ├── swap/             # Token swap interface
│   │   │   ├── pools/            # Pool list & add liquidity
│   │   │   ├── positions/        # LP position management
│   │   │   └── faucet/           # Demo token faucet
│   │   ├── components/           # React components
│   │   │   ├── ui/               # shadcn/ui components
│   │   │   ├── layout/           # Header, footer, navigation
│   │   │   └── providers/        # Sui wallet providers
│   │   └── lib/
│   │       ├── sui/              # Sui SDK integration
│   │       │   ├── constants.ts  # Contract addresses
│   │       │   ├── transactions.ts # PTB builders
│   │       │   └── queries.ts    # On-chain data queries
│   │       └── mock-data.ts      # Demo data for UI
│   ├── package.json
│   └── tailwind.config.ts
│
└── scripts/                      # Deployment & demo scripts
    ├── deploy.sh                 # Contract deployment
    └── demo.sh                   # Interactive demo
```

## Quick Start

### Prerequisites

1. Install Sui CLI:
```bash
# macOS
brew install sui

# Or from source
cargo install --locked --git https://github.com/MystenLabs/sui.git --branch devnet sui
```

2. Configure Sui CLI:
```bash
sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443
sui client switch --env testnet
sui client faucet  # Get test SUI tokens
```

### Build

```bash
cd contracts
sui move build
```

### Test

```bash
cd contracts
sui move test
```

### Deploy

```bash
# Deploy to testnet
sui client publish --gas-budget 500000000
```

## Testnet Deployment

The contracts are deployed on **Sui Testnet** (v3 with public faucet):

| Item | Value |
|------|-------|
| **Package ID** | `0x374b4c8fec99c1f2dd38983fd1624c21d1984ec9258648aab9a5adaaafd70afa` |
| **PoolFactory** | `0xeb0bc8869f53adcf10a10b92070d6910289ee54261dcfed387f659c8ffd53ed6` |
| **FeeDistributor** | `0x23036241a23fa36fb8b996d6369f377bdcdecea194860e38e6382031591f384e` |
| **SlippageSettings** | `0x0613b47f6bf7bba429f2d0aae883bc3fde29f7485308c65963b437103259c11e` |
| **PublicFaucet** | `0xa2d7ea8c75a3bdb035cd77659808998bbecec1cd7b5641e6e1d4768184eafe5e` |

View on explorer: [Sui Explorer](https://suiscan.xyz/testnet/object/0x374b4c8fec99c1f2dd38983fd1624c21d1984ec9258648aab9a5adaaafd70afa)

### Demo

```bash
# Run interactive demo
./scripts/demo.sh

# Or run specific commands
./scripts/demo.sh create-pool
./scripts/demo.sh swap
```

## Web Interface

The project includes a full-featured Next.js frontend for interacting with the AMM contracts.

### Live Demo

Visit **[https://movefwd-amm.vercel.app](https://movefwd-amm.vercel.app)** to try the live demo on Sui Testnet.

### Features

| Page | Description |
|------|-------------|
| **Dashboard** | Protocol overview with TVL ($15.05M), volume ($3.11M), top pools, and recent activity |
| **Swap** | Trade between any token pair with real-time price quotes and slippage protection |
| **Pools** | Browse all liquidity pools, view APRs, and add liquidity |
| **Positions** | Manage your LP Position NFTs, track earned fees, remove liquidity |
| **Faucet** | Mint demo tokens (USDC, USDT, ETH, BTC, WSUI) for testing |

### Run Locally

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build
```

The frontend will be available at `http://localhost:3000`.

### Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Sui SDK**: @mysten/sui, @mysten/dapp-kit
- **Styling**: Tailwind CSS with custom dark DeFi theme
- **UI Components**: shadcn/ui
- **State Management**: TanStack Query (built into dapp-kit)

### Wallet Connection

The app supports Sui Wallet connection via the dapp-kit. Users can:

1. Click "Connect Wallet" in the header
2. Select Sui Wallet from the modal
3. Approve the connection in their wallet
4. Interact with all AMM functions

### Demo Walkthrough

Try these steps to explore the full protocol:

1. **Connect Wallet** - Use Sui Wallet on testnet
2. **Get Demo Tokens** - Visit the [Faucet](https://movefwd-amm.vercel.app/faucet) to mint USDC + ETH
3. **Perform a Swap** - Go to [Swap](https://movefwd-amm.vercel.app/swap) and trade USDC for ETH
4. **Add Liquidity** - Create an LP position in the USDC/ETH pool
5. **View LP NFT** - Check your [Positions](https://movefwd-amm.vercel.app/positions) page
6. **Track Fees** - Watch your accumulated trading fees grow

## Usage Examples

### Create a Pool

```move
// Create a USDC/ETH pool with 0.3% fee
let position = pool_factory::create_pool<USDC, ETH>(
    &mut factory,
    usdc_coin,
    eth_coin,
    30, // 0.3% fee (30 basis points)
    &clock,
    ctx,
);
```

### Add Liquidity

```move
// Add liquidity to existing pool
let position = pool_factory::add_liquidity<USDC, ETH>(
    &mut pool,
    usdc_coin,
    eth_coin,
    min_lp_tokens, // Slippage protection
    &clock,
    ctx,
);
```

### Swap Tokens

```move
// Swap USDC for ETH
let eth_out = pool_factory::swap_a_for_b<USDC, ETH>(
    &mut pool,
    usdc_coin,
    min_eth_out, // Slippage protection
    ctx,
);

// Or swap ETH for USDC
let usdc_out = pool_factory::swap_b_for_a<USDC, ETH>(
    &mut pool,
    eth_coin,
    min_usdc_out,
    ctx,
);
```

### Remove Liquidity

```move
// Remove partial liquidity
let (usdc, eth) = pool_factory::remove_liquidity<USDC, ETH>(
    &mut pool,
    &mut position,
    lp_tokens_to_remove,
    min_usdc,
    min_eth,
    &clock,
    ctx,
);

// Remove all liquidity and burn NFT
let (usdc, eth) = pool_factory::remove_all_liquidity<USDC, ETH>(
    &mut pool,
    position,
    min_usdc,
    min_eth,
    &clock,
    ctx,
);
```

### View Position Value

```move
// Calculate current position value
let (value_a, value_b) = lp_position_nft::calculate_position_value(
    &position,
    reserve_a,
    reserve_b,
    total_supply,
);

// Calculate impermanent loss
let il_bps = lp_position_nft::calculate_impermanent_loss(
    &position,
    current_reserve_a,
    current_reserve_b,
    total_supply,
);
```

## Fee Tiers

| Tier | Fee | Best For |
|------|-----|----------|
| Low | 0.05% | Stable pairs (USDC/USDT) |
| Medium | 0.3% | Standard pairs (ETH/USDC) |
| High | 1% | Exotic/volatile pairs |

## Security Considerations

- **Slippage Protection**: Always set appropriate minimum output amounts
- **Deadline Enforcement**: Use transaction deadlines to prevent stale transactions
- **Price Impact Limits**: Check price impact before large swaps
- **K Invariant**: The protocol maintains the x * y = k invariant at all times

## Testing

The project includes comprehensive tests:

- **Unit Tests**: Test individual functions and modules
- **Integration Tests**: Test complete workflows
- **Edge Cases**: Handle extreme values and error conditions

Run all tests:
```bash
sui move test
```

Run specific test:
```bash
sui move test math_tests
```

## Architecture

### Constant Product Formula

The AMM uses the constant product formula where the product of reserves must remain constant:

```
x * y = k

Output = (input_with_fee * reserve_out) / (reserve_in + input_with_fee)
```

### Stable Swap Formula

For stable pairs, we use the StableSwap invariant with amplification coefficient A:

```
A * n^n * sum(x_i) + D = A * D * n^n + D^(n+1) / (n^n * prod(x_i))
```

### LP Token Calculation

Initial deposit:
```
lp_tokens = sqrt(amount_a * amount_b) - MINIMUM_LIQUIDITY
```

Subsequent deposits:
```
lp_tokens = min(
    amount_a * total_supply / reserve_a,
    amount_b * total_supply / reserve_b
)
```

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Submit a pull request

## Resources

- [SuiSwap Live Demo](https://movefwd-amm.vercel.app) - Try the AMM on testnet
- [Contract on Explorer](https://suiscan.xyz/testnet/object/0x374b4c8fec99c1f2dd38983fd1624c21d1984ec9258648aab9a5adaaafd70afa) - View deployed contracts
- [Public Faucet](https://suiscan.xyz/testnet/object/0xa2d7ea8c75a3bdb035cd77659808998bbecec1cd7b5641e6e1d4768184eafe5e) - Anyone can get test tokens
- [Sui Documentation](https://docs.sui.io/)
- [Move Language](https://move-language.github.io/move/)
- [Uniswap V2 Whitepaper](https://uniswap.org/whitepaper.pdf)
- [Curve StableSwap](https://curve.fi/files/stableswap-paper.pdf)


