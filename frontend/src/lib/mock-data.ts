import { DEMO_TOKENS, TokenSymbol } from "./sui/constants";

// Static timestamp base - November 29, 2024
const BASE_TIMESTAMP = 1732924800000;

// Generate static timestamps (spread over past weeks)
function staticTimestamp(daysAgo: number, offsetHours: number = 0): number {
  const dayMs = 24 * 60 * 60 * 1000;
  const hourMs = 60 * 60 * 1000;
  return BASE_TIMESTAMP - (daysAgo * dayMs) + (offsetHours * hourMs);
}

// Pre-generated static addresses (deterministic)
const STATIC_ADDRESSES = [
  "0xa1b2c3d4e5f67890abcdef1234567890abcdef1234567890abcdef1234567890",
  "0xb2c3d4e5f67890abcdef1234567890abcdef1234567890abcdef1234567890a1",
  "0xc3d4e5f67890abcdef1234567890abcdef1234567890abcdef1234567890a1b2",
  "0xd4e5f67890abcdef1234567890abcdef1234567890abcdef1234567890a1b2c3",
  "0xe5f67890abcdef1234567890abcdef1234567890abcdef1234567890a1b2c3d4",
  "0xf67890abcdef1234567890abcdef1234567890abcdef1234567890a1b2c3d4e5",
  "0x7890abcdef1234567890abcdef1234567890abcdef1234567890a1b2c3d4e5f6",
  "0x890abcdef1234567890abcdef1234567890abcdef1234567890a1b2c3d4e5f67",
  "0x90abcdef1234567890abcdef1234567890abcdef1234567890a1b2c3d4e5f678",
  "0x0abcdef1234567890abcdef1234567890abcdef1234567890a1b2c3d4e5f6789",
];

// Shorten address for display
export function shortenAddress(address: string, chars: number = 4): string {
  return `${address.slice(0, chars + 2)}...${address.slice(-chars)}`;
}

// Mock pool data
export interface MockPool {
  id: string;
  tokenA: TokenSymbol;
  tokenB: TokenSymbol;
  reserveA: bigint;
  reserveB: bigint;
  feeTier: number;
  totalSupply: bigint;
  tvlUsd: number;
  volume24h: number;
  volume7d: number;
  fees24h: number;
  apr: number;
  priceChange24h: number;
}

export const MOCK_POOLS: MockPool[] = [
  {
    id: "0x1a2b3c4d5e6f7890abcdef1234567890abcdef1234567890abcdef1234567890",
    tokenA: "USDC",
    tokenB: "ETH",
    reserveA: 2500000_000000n, // 2.5M USDC
    reserveB: 750_000000000000000000n, // 750 ETH
    feeTier: 30,
    totalSupply: 1250000_000000n,
    tvlUsd: 5000000,
    volume24h: 892340,
    volume7d: 5234560,
    fees24h: 2677,
    apr: 19.52,
    priceChange24h: 2.34,
  },
  {
    id: "0x2b3c4d5e6f7890abcdef1234567890abcdef1234567890abcdef1234567890ab",
    tokenA: "USDC",
    tokenB: "USDT",
    reserveA: 1800000_000000n, // 1.8M USDC
    reserveB: 1795000_000000n, // 1.795M USDT
    feeTier: 5,
    totalSupply: 1797500_000000n,
    tvlUsd: 3595000,
    volume24h: 1234560,
    volume7d: 8567890,
    fees24h: 617,
    apr: 6.27,
    priceChange24h: 0.01,
  },
  {
    id: "0x3c4d5e6f7890abcdef1234567890abcdef1234567890abcdef1234567890abcd",
    tokenA: "WSUI",
    tokenB: "USDC",
    reserveA: 5000000_000000000n, // 5M WSUI
    reserveB: 1250000_000000n, // 1.25M USDC
    feeTier: 30,
    totalSupply: 2500000_000000n,
    tvlUsd: 2500000,
    volume24h: 456780,
    volume7d: 2890123,
    fees24h: 1370,
    apr: 20.01,
    priceChange24h: -1.23,
  },
  {
    id: "0x4d5e6f7890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
    tokenA: "BTC",
    tokenB: "USDC",
    reserveA: 25_00000000n, // 25 BTC
    reserveB: 1075000_000000n, // 1.075M USDC
    feeTier: 30,
    totalSupply: 163000_000000n,
    tvlUsd: 2150000,
    volume24h: 345670,
    volume7d: 2123450,
    fees24h: 1037,
    apr: 17.61,
    priceChange24h: 0.89,
  },
  {
    id: "0x5e6f7890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12",
    tokenA: "ETH",
    tokenB: "BTC",
    reserveA: 320_000000000000000000n, // 320 ETH
    reserveB: 15_00000000n, // 15 BTC
    feeTier: 30,
    totalSupply: 69000_000000n,
    tvlUsd: 1708000,
    volume24h: 178900,
    volume7d: 1234560,
    fees24h: 537,
    apr: 11.47,
    priceChange24h: 0.34,
  },
];

// Mock transaction activity
export interface MockTransaction {
  id: string;
  type: "swap" | "add_liquidity" | "remove_liquidity";
  timestamp: number;
  user: string;
  tokenA: TokenSymbol;
  tokenB: TokenSymbol;
  amountA: string;
  amountB: string;
  valueUsd: number;
  txHash: string;
}

// Static pre-generated transactions (no random generation)
export const MOCK_TRANSACTIONS: MockTransaction[] = [
  // Day 0 (today) - Recent activity
  {
    id: "1",
    type: "swap",
    timestamp: staticTimestamp(0, 2),
    user: STATIC_ADDRESSES[0],
    tokenA: "USDC",
    tokenB: "ETH",
    amountA: "5,000",
    amountB: "1.52",
    valueUsd: 5000,
    txHash: "0xabc123def456789012345678901234567890123456789012345678901234abcd",
  },
  {
    id: "2",
    type: "add_liquidity",
    timestamp: staticTimestamp(0, 4),
    user: STATIC_ADDRESSES[1],
    tokenA: "USDC",
    tokenB: "USDT",
    amountA: "50,000",
    amountB: "49,875",
    valueUsd: 99875,
    txHash: "0xbcd234ef5678901234567890123456789012345678901234567890123456bcde",
  },
  {
    id: "3",
    type: "swap",
    timestamp: staticTimestamp(0, 6),
    user: STATIC_ADDRESSES[2],
    tokenA: "ETH",
    tokenB: "USDC",
    amountA: "0.85",
    amountB: "2,805",
    valueUsd: 2805,
    txHash: "0xcde345f67890123456789012345678901234567890123456789012345678cdef",
  },
  // Day 1
  {
    id: "4",
    type: "swap",
    timestamp: staticTimestamp(1, 3),
    user: STATIC_ADDRESSES[3],
    tokenA: "WSUI",
    tokenB: "USDC",
    amountA: "10,000",
    amountB: "2,500",
    valueUsd: 2500,
    txHash: "0xdef456789012345678901234567890123456789012345678901234567890def0",
  },
  {
    id: "5",
    type: "remove_liquidity",
    timestamp: staticTimestamp(1, 8),
    user: STATIC_ADDRESSES[4],
    tokenA: "BTC",
    tokenB: "USDC",
    amountA: "0.5",
    amountB: "21,500",
    valueUsd: 43000,
    txHash: "0xef5678901234567890123456789012345678901234567890123456789012ef01",
  },
  {
    id: "6",
    type: "swap",
    timestamp: staticTimestamp(1, 12),
    user: STATIC_ADDRESSES[5],
    tokenA: "USDC",
    tokenB: "BTC",
    amountA: "10,000",
    amountB: "0.23",
    valueUsd: 10000,
    txHash: "0xf67890123456789012345678901234567890123456789012345678901234f012",
  },
  // Day 2
  {
    id: "7",
    type: "add_liquidity",
    timestamp: staticTimestamp(2, 5),
    user: STATIC_ADDRESSES[6],
    tokenA: "ETH",
    tokenB: "USDC",
    amountA: "5.0",
    amountB: "16,500",
    valueUsd: 33000,
    txHash: "0x78901234567890123456789012345678901234567890123456789012345670123",
  },
  {
    id: "8",
    type: "swap",
    timestamp: staticTimestamp(2, 10),
    user: STATIC_ADDRESSES[7],
    tokenA: "USDT",
    tokenB: "USDC",
    amountA: "25,000",
    amountB: "24,975",
    valueUsd: 25000,
    txHash: "0x89012345678901234567890123456789012345678901234567890123456780124",
  },
  // Day 3
  {
    id: "9",
    type: "swap",
    timestamp: staticTimestamp(3, 4),
    user: STATIC_ADDRESSES[8],
    tokenA: "ETH",
    tokenB: "BTC",
    amountA: "2.5",
    amountB: "0.12",
    valueUsd: 8250,
    txHash: "0x90123456789012345678901234567890123456789012345678901234567890125",
  },
  {
    id: "10",
    type: "add_liquidity",
    timestamp: staticTimestamp(3, 9),
    user: STATIC_ADDRESSES[9],
    tokenA: "WSUI",
    tokenB: "USDC",
    amountA: "100,000",
    amountB: "25,000",
    valueUsd: 50000,
    txHash: "0x01234567890123456789012345678901234567890123456789012345678901236",
  },
  // Day 4
  {
    id: "11",
    type: "swap",
    timestamp: staticTimestamp(4, 6),
    user: STATIC_ADDRESSES[0],
    tokenA: "BTC",
    tokenB: "ETH",
    amountA: "0.5",
    amountB: "10.5",
    valueUsd: 21500,
    txHash: "0x12345678901234567890123456789012345678901234567890123456789012347",
  },
  {
    id: "12",
    type: "swap",
    timestamp: staticTimestamp(4, 12),
    user: STATIC_ADDRESSES[1],
    tokenA: "USDC",
    tokenB: "WSUI",
    amountA: "1,000",
    amountB: "4,000",
    valueUsd: 1000,
    txHash: "0x23456789012345678901234567890123456789012345678901234567890123458",
  },
  // Day 5
  {
    id: "13",
    type: "remove_liquidity",
    timestamp: staticTimestamp(5, 3),
    user: STATIC_ADDRESSES[2],
    tokenA: "USDC",
    tokenB: "ETH",
    amountA: "25,000",
    amountB: "7.6",
    valueUsd: 50000,
    txHash: "0x34567890123456789012345678901234567890123456789012345678901234569",
  },
  {
    id: "14",
    type: "swap",
    timestamp: staticTimestamp(5, 8),
    user: STATIC_ADDRESSES[3],
    tokenA: "ETH",
    tokenB: "USDC",
    amountA: "3.2",
    amountB: "10,560",
    valueUsd: 10560,
    txHash: "0x4567890123456789012345678901234567890123456789012345678901234567a",
  },
  // Day 6
  {
    id: "15",
    type: "add_liquidity",
    timestamp: staticTimestamp(6, 5),
    user: STATIC_ADDRESSES[4],
    tokenA: "BTC",
    tokenB: "USDC",
    amountA: "1.0",
    amountB: "43,000",
    valueUsd: 86000,
    txHash: "0x567890123456789012345678901234567890123456789012345678901234567ab",
  },
  {
    id: "16",
    type: "swap",
    timestamp: staticTimestamp(6, 11),
    user: STATIC_ADDRESSES[5],
    tokenA: "USDC",
    tokenB: "ETH",
    amountA: "8,500",
    amountB: "2.58",
    valueUsd: 8500,
    txHash: "0x67890123456789012345678901234567890123456789012345678901234567abc",
  },
  // Day 7 (1 week ago)
  {
    id: "17",
    type: "swap",
    timestamp: staticTimestamp(7, 4),
    user: STATIC_ADDRESSES[6],
    tokenA: "WSUI",
    tokenB: "USDC",
    amountA: "50,000",
    amountB: "12,500",
    valueUsd: 12500,
    txHash: "0x7890123456789012345678901234567890123456789012345678901234567abcd",
  },
  {
    id: "18",
    type: "swap",
    timestamp: staticTimestamp(7, 9),
    user: STATIC_ADDRESSES[7],
    tokenA: "USDT",
    tokenB: "USDC",
    amountA: "100,000",
    amountB: "99,900",
    valueUsd: 100000,
    txHash: "0x890123456789012345678901234567890123456789012345678901234567abcde",
  },
  // More historical transactions
  {
    id: "19",
    type: "swap",
    timestamp: staticTimestamp(8, 6),
    user: STATIC_ADDRESSES[8],
    tokenA: "USDC",
    tokenB: "ETH",
    amountA: "3,500",
    amountB: "1.06",
    valueUsd: 3500,
    txHash: "0x90123456789012345678901234567890123456789012345678901234567abcdef",
  },
  {
    id: "20",
    type: "swap",
    timestamp: staticTimestamp(9, 3),
    user: STATIC_ADDRESSES[9],
    tokenA: "ETH",
    tokenB: "USDC",
    amountA: "1.2",
    amountB: "3,960",
    valueUsd: 3960,
    txHash: "0xa123456789012345678901234567890123456789012345678901234567abcdef0",
  },
  {
    id: "21",
    type: "add_liquidity",
    timestamp: staticTimestamp(10, 5),
    user: STATIC_ADDRESSES[0],
    tokenA: "BTC",
    tokenB: "USDC",
    amountA: "0.3",
    amountB: "12,900",
    valueUsd: 25800,
    txHash: "0xb23456789012345678901234567890123456789012345678901234567abcdef01",
  },
  {
    id: "22",
    type: "swap",
    timestamp: staticTimestamp(11, 7),
    user: STATIC_ADDRESSES[1],
    tokenA: "WSUI",
    tokenB: "USDC",
    amountA: "25,000",
    amountB: "6,250",
    valueUsd: 6250,
    txHash: "0xc3456789012345678901234567890123456789012345678901234567abcdef012",
  },
  {
    id: "23",
    type: "swap",
    timestamp: staticTimestamp(12, 2),
    user: STATIC_ADDRESSES[2],
    tokenA: "USDT",
    tokenB: "USDC",
    amountA: "15,000",
    amountB: "14,985",
    valueUsd: 15000,
    txHash: "0xd456789012345678901234567890123456789012345678901234567abcdef0123",
  },
  {
    id: "24",
    type: "swap",
    timestamp: staticTimestamp(13, 8),
    user: STATIC_ADDRESSES[3],
    tokenA: "ETH",
    tokenB: "BTC",
    amountA: "0.8",
    amountB: "0.04",
    valueUsd: 2640,
    txHash: "0xe56789012345678901234567890123456789012345678901234567abcdef01234",
  },
  {
    id: "25",
    type: "swap",
    timestamp: staticTimestamp(14, 4),
    user: STATIC_ADDRESSES[4],
    tokenA: "BTC",
    tokenB: "ETH",
    amountA: "0.15",
    amountB: "3.15",
    valueUsd: 6450,
    txHash: "0xf6789012345678901234567890123456789012345678901234567abcdef012345",
  },
];

// Sort transactions by timestamp (newest first)
MOCK_TRANSACTIONS.sort((a, b) => b.timestamp - a.timestamp);

// Protocol-level statistics
export const PROTOCOL_STATS = {
  totalValueLocked: 15_053_000, // $15.05M
  totalVolume24h: 3_108_250,    // $3.1M
  totalVolume7d: 20_050_583,    // $20M
  totalFeesGenerated: 45_678,   // $45.6K all time
  totalPools: 5,
  totalSwaps: 1272,
  totalLiquidityProviders: 89,
  averageAPR: 14.98,
};

// Price chart data (7 days) for USDC/ETH pair - static values
export const PRICE_HISTORY_ETH_USDC = Array.from({ length: 168 }, (_, i) => {
  const hoursAgo = 168 - i;
  const basePrice = 3300;
  // Deterministic price movement based on index
  const noise = Math.sin(i / 12) * 50 + Math.sin(i / 5) * 30 + Math.cos(i / 8) * 20;
  const trend = (i / 168) * 50;
  
  return {
    timestamp: BASE_TIMESTAMP - hoursAgo * 60 * 60 * 1000,
    price: basePrice + noise + trend,
    volume: 50000 + (i % 10) * 10000,
  };
});

// TVL chart data (30 days) - static values
export const TVL_HISTORY = Array.from({ length: 30 }, (_, i) => {
  const daysAgo = 30 - i;
  const baseTVL = 12_000_000;
  const growth = (i / 30) * 3_000_000;
  const noise = Math.sin(i / 3) * 300_000;
  
  return {
    timestamp: BASE_TIMESTAMP - daysAgo * 24 * 60 * 60 * 1000,
    tvl: baseTVL + growth + noise,
  };
});

// Format number with commas and optional decimals
export function formatNumber(value: number, decimals: number = 2): string {
  return value.toLocaleString("en-US", {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
}

// Format USD value
export function formatUsd(value: number): string {
  if (value >= 1_000_000) {
    return `$${(value / 1_000_000).toFixed(2)}M`;
  }
  if (value >= 1_000) {
    return `$${(value / 1_000).toFixed(2)}K`;
  }
  return `$${value.toFixed(2)}`;
}

// Format percentage
export function formatPercent(value: number): string {
  const sign = value >= 0 ? "+" : "";
  return `${sign}${value.toFixed(2)}%`;
}

// Get relative time string - use static base time for SSR consistency
export function getRelativeTime(timestamp: number): string {
  const diff = BASE_TIMESTAMP - timestamp;
  
  const minutes = Math.floor(diff / (1000 * 60));
  const hours = Math.floor(diff / (1000 * 60 * 60));
  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  
  if (minutes < 1) return "Just now";
  if (minutes < 60) return `${minutes}m ago`;
  if (hours < 24) return `${hours}h ago`;
  if (days < 7) return `${days}d ago`;
  
  return new Date(timestamp).toLocaleDateString("en-US");
}

// Get token info helper
export function getTokenInfo(symbol: TokenSymbol) {
  return DEMO_TOKENS[symbol];
}
