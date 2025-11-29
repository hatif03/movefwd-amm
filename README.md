# Sui AMM with NFT LP Positions

A decentralized Automated Market Maker (AMM) built on the Sui blockchain with NFT-based liquidity provider positions, implementing the constant product formula (x * y = k).

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

## Project Structure

```
contracts/
├── sources/
│   ├── constants.move       # Protocol constants and configuration
│   ├── errors.move          # Error codes
│   ├── events.move          # Event definitions
│   ├── math.move            # AMM math utilities
│   ├── lp_position_nft.move # NFT-based LP positions
│   ├── pool_factory.move    # Pool creation and management
│   ├── stable_swap_pool.move # Stable swap implementation
│   ├── fee_distributor.move # Fee distribution logic
│   ├── slippage_protection.move # Slippage management
│   └── demo_tokens.move     # Demo tokens for testing
├── tests/
│   ├── math_tests.move      # Math module tests
│   ├── lp_position_nft_tests.move # NFT tests
│   ├── pool_factory_tests.move # Pool tests
│   ├── slippage_tests.move  # Slippage protection tests
│   ├── constants_tests.move # Constants tests
│   └── integration_tests.move # End-to-end tests
└── Move.toml                # Package configuration
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

The contracts are deployed on **Sui Testnet**:

| Item | Value |
|------|-------|
| **Package ID** | `0x2ece39501958bbccee8d22cad8ed70226148da7df7e6fbc4aa20b5aeb9c0de65` |
| **PoolFactory** | `0xf3b24aaf25fcad3d6790b385a1325821a9a2aed31f70d15d403dffdb504e78ca` |
| **FeeDistributor** | `0x998117bfbff8f06e1ed2bc6ff5951146eba96d32113afecf729e503c74cdc127` |
| **SlippageSettings** | `0x3f8eed76d96117b231221d4fdda32980b243cd3756267d0eb1cc4d0c1215802b` |

View on explorer: [Sui Explorer](https://suiscan.xyz/testnet/object/0x2ece39501958bbccee8d22cad8ed70226148da7df7e6fbc4aa20b5aeb9c0de65)

### Demo

```bash
# Run interactive demo
./scripts/demo.sh

# Or run specific commands
./scripts/demo.sh create-pool
./scripts/demo.sh swap
```

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

- [Sui Documentation](https://docs.sui.io/)
- [Move Language](https://move-language.github.io/move/)
- [Uniswap V2 Whitepaper](https://uniswap.org/whitepaper.pdf)
- [Curve StableSwap](https://curve.fi/files/stableswap-paper.pdf)


