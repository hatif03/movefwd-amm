// Deployed Contract Addresses on Sui Testnet (v2 with demo tokens)
export const PACKAGE_ID = "0xc506ab88e436640b27afdc5d4f70feaae7dfd8c58c6b00b587be44f342558089";
export const POOL_FACTORY_ID = "0x0025e19450c6f390900e4a3d879735b119e4503a67aeec5c3e9b9cf0747ba3e7";
export const FEE_DISTRIBUTOR_ID = "0xefe4a10aab40be514f11a31c9d9e6d736aae5b47c2c0df34c107a3a71bc2e0ca";
export const SLIPPAGE_SETTINGS_ID = "0x9130617e7916b948280f4741c17fe808086fbe1b08e4b740340a541ca49a52b1";

// System Objects
export const CLOCK_ID = "0x6";

// Module Names
export const MODULES = {
  POOL_FACTORY: "pool_factory",
  STABLE_SWAP_POOL: "stable_swap_pool",
  LP_POSITION_NFT: "lp_position_nft",
  FEE_DISTRIBUTOR: "fee_distributor",
  SLIPPAGE_PROTECTION: "slippage_protection",
  DEMO_TOKENS: "demo_tokens",
} as const;

// Fee Tiers (in basis points)
export const FEE_TIERS = {
  LOW: 5,      // 0.05%
  MEDIUM: 30,  // 0.3%
  HIGH: 100,   // 1%
} as const;

// Demo Token Types (each token in its own module for OTW compliance)
export const DEMO_TOKENS = {
  USDC: {
    type: `${PACKAGE_ID}::demo_usdc::DEMO_USDC`,
    module: "demo_usdc",
    symbol: "USDC",
    name: "Demo USD Coin",
    decimals: 6,
    icon: "💵",
    color: "#2775ca",
  },
  USDT: {
    type: `${PACKAGE_ID}::demo_usdt::DEMO_USDT`,
    module: "demo_usdt",
    symbol: "USDT",
    name: "Demo Tether USD",
    decimals: 6,
    icon: "💴",
    color: "#26a17b",
  },
  ETH: {
    type: `${PACKAGE_ID}::demo_eth::DEMO_ETH`,
    module: "demo_eth",
    symbol: "ETH",
    name: "Demo Ethereum",
    decimals: 18,
    icon: "⟠",
    color: "#627eea",
  },
  BTC: {
    type: `${PACKAGE_ID}::demo_btc::DEMO_BTC`,
    module: "demo_btc",
    symbol: "BTC",
    name: "Demo Bitcoin",
    decimals: 8,
    icon: "₿",
    color: "#f7931a",
  },
  WSUI: {
    type: `${PACKAGE_ID}::demo_wsui::DEMO_WSUI`,
    module: "demo_wsui",
    symbol: "WSUI",
    name: "Demo Wrapped SUI",
    decimals: 9,
    icon: "🌊",
    color: "#6fbcf0",
  },
} as const;

export type TokenSymbol = keyof typeof DEMO_TOKENS;

// LP Position NFT Type
export const LP_POSITION_NFT_TYPE = `${PACKAGE_ID}::lp_position_nft::LPPositionNFT`;

// Pool Types
export const LIQUIDITY_POOL_TYPE = `${PACKAGE_ID}::pool_factory::LiquidityPool`;
export const STABLE_SWAP_POOL_TYPE = `${PACKAGE_ID}::stable_swap_pool::StableSwapPool`;

// Treasury Cap Types (for minting demo tokens)
export const TREASURY_CAP_TYPES = {
  USDC: `0x2::coin::TreasuryCap<${PACKAGE_ID}::demo_usdc::DEMO_USDC>`,
  USDT: `0x2::coin::TreasuryCap<${PACKAGE_ID}::demo_usdt::DEMO_USDT>`,
  ETH: `0x2::coin::TreasuryCap<${PACKAGE_ID}::demo_eth::DEMO_ETH>`,
  BTC: `0x2::coin::TreasuryCap<${PACKAGE_ID}::demo_btc::DEMO_BTC>`,
  WSUI: `0x2::coin::TreasuryCap<${PACKAGE_ID}::demo_wsui::DEMO_WSUI>`,
} as const;

// Explorer Links
export const EXPLORER_BASE_URL = "https://suiscan.xyz/testnet";

export function getObjectUrl(objectId: string): string {
  return `${EXPLORER_BASE_URL}/object/${objectId}`;
}

export function getTxUrl(txDigest: string): string {
  return `${EXPLORER_BASE_URL}/tx/${txDigest}`;
}

export function getAccountUrl(address: string): string {
  return `${EXPLORER_BASE_URL}/account/${address}`;
}


