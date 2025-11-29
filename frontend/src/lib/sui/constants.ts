// Deployed Contract Addresses on Sui Testnet
export const PACKAGE_ID = "0x2ece39501958bbccee8d22cad8ed70226148da7df7e6fbc4aa20b5aeb9c0de65";
export const POOL_FACTORY_ID = "0xf3b24aaf25fcad3d6790b385a1325821a9a2aed31f70d15d403dffdb504e78ca";
export const FEE_DISTRIBUTOR_ID = "0x998117bfbff8f06e1ed2bc6ff5951146eba96d32113afecf729e503c74cdc127";
export const SLIPPAGE_SETTINGS_ID = "0x3f8eed76d96117b231221d4fdda32980b243cd3756267d0eb1cc4d0c1215802b";

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

// Demo Token Types
export const DEMO_TOKENS = {
  USDC: {
    type: `${PACKAGE_ID}::demo_tokens::DEMO_USDC`,
    symbol: "USDC",
    name: "Demo USD Coin",
    decimals: 6,
    icon: "💵",
    color: "#2775ca",
  },
  USDT: {
    type: `${PACKAGE_ID}::demo_tokens::DEMO_USDT`,
    symbol: "USDT",
    name: "Demo Tether USD",
    decimals: 6,
    icon: "💴",
    color: "#26a17b",
  },
  ETH: {
    type: `${PACKAGE_ID}::demo_tokens::DEMO_ETH`,
    symbol: "ETH",
    name: "Demo Ethereum",
    decimals: 18,
    icon: "⟠",
    color: "#627eea",
  },
  BTC: {
    type: `${PACKAGE_ID}::demo_tokens::DEMO_BTC`,
    symbol: "BTC",
    name: "Demo Bitcoin",
    decimals: 8,
    icon: "₿",
    color: "#f7931a",
  },
  WSUI: {
    type: `${PACKAGE_ID}::demo_tokens::DEMO_WSUI`,
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
  USDC: `0x2::coin::TreasuryCap<${PACKAGE_ID}::demo_tokens::DEMO_USDC>`,
  USDT: `0x2::coin::TreasuryCap<${PACKAGE_ID}::demo_tokens::DEMO_USDT>`,
  ETH: `0x2::coin::TreasuryCap<${PACKAGE_ID}::demo_tokens::DEMO_ETH>`,
  BTC: `0x2::coin::TreasuryCap<${PACKAGE_ID}::demo_tokens::DEMO_BTC>`,
  WSUI: `0x2::coin::TreasuryCap<${PACKAGE_ID}::demo_tokens::DEMO_WSUI>`,
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

