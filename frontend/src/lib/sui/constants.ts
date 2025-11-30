// Deployed Contract Addresses on Sui Testnet (v3 with public faucet)
export const PACKAGE_ID = "0x374b4c8fec99c1f2dd38983fd1624c21d1984ec9258648aab9a5adaaafd70afa";
export const POOL_FACTORY_ID = "0xeb0bc8869f53adcf10a10b92070d6910289ee54261dcfed387f659c8ffd53ed6";
export const FEE_DISTRIBUTOR_ID = "0x23036241a23fa36fb8b996d6369f377bdcdecea194860e38e6382031591f384e";
export const SLIPPAGE_SETTINGS_ID = "0x0613b47f6bf7bba429f2d0aae883bc3fde29f7485308c65963b437103259c11e";

// Public Faucet - Anyone can mint tokens from this!
export const PUBLIC_FAUCET_ID = "0xa2d7ea8c75a3bdb035cd77659808998bbecec1cd7b5641e6e1d4768184eafe5e";
export const PUBLIC_FAUCET_INITIAL_VERSION = 349181019;

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


