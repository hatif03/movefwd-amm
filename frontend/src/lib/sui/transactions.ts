import { Transaction } from "@mysten/sui/transactions";
import { 
  PACKAGE_ID, 
  POOL_FACTORY_ID, 
  CLOCK_ID, 
  MODULES,
  DEMO_TOKENS,
  TokenSymbol 
} from "./constants";

/**
 * Build a transaction to mint demo tokens
 */
export function buildMintTokensTx(
  treasuryCapId: string,
  tokenSymbol: TokenSymbol,
  amount: bigint,
  recipient: string
): Transaction {
  const tx = new Transaction();
  
  const functionName = `mint_${tokenSymbol.toLowerCase()}`;
  
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULES.DEMO_TOKENS}::${functionName}`,
    arguments: [
      tx.object(treasuryCapId),
      tx.pure.u64(amount),
      tx.pure.address(recipient),
    ],
  });
  
  return tx;
}

/**
 * Build a transaction to create a new liquidity pool
 */
export function buildCreatePoolTx(
  coinAType: string,
  coinBType: string,
  coinAId: string,
  coinBId: string,
  feeTier: number
): Transaction {
  const tx = new Transaction();
  
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULES.POOL_FACTORY}::create_pool`,
    typeArguments: [coinAType, coinBType],
    arguments: [
      tx.object(POOL_FACTORY_ID),
      tx.object(coinAId),
      tx.object(coinBId),
      tx.pure.u64(feeTier),
      tx.object(CLOCK_ID),
    ],
  });
  
  return tx;
}

/**
 * Build a transaction to add liquidity to an existing pool
 */
export function buildAddLiquidityTx(
  coinAType: string,
  coinBType: string,
  poolId: string,
  coinAId: string,
  coinBId: string,
  minLpTokens: bigint
): Transaction {
  const tx = new Transaction();
  
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULES.POOL_FACTORY}::add_liquidity`,
    typeArguments: [coinAType, coinBType],
    arguments: [
      tx.object(poolId),
      tx.object(coinAId),
      tx.object(coinBId),
      tx.pure.u64(minLpTokens),
      tx.object(CLOCK_ID),
    ],
  });
  
  return tx;
}

/**
 * Build a transaction to remove liquidity from a pool
 */
export function buildRemoveLiquidityTx(
  coinAType: string,
  coinBType: string,
  poolId: string,
  positionId: string,
  lpTokensToRemove: bigint,
  minAmountA: bigint,
  minAmountB: bigint
): Transaction {
  const tx = new Transaction();
  
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULES.POOL_FACTORY}::remove_liquidity`,
    typeArguments: [coinAType, coinBType],
    arguments: [
      tx.object(poolId),
      tx.object(positionId),
      tx.pure.u64(lpTokensToRemove),
      tx.pure.u64(minAmountA),
      tx.pure.u64(minAmountB),
      tx.object(CLOCK_ID),
    ],
  });
  
  return tx;
}

/**
 * Build a transaction to swap token A for token B
 */
export function buildSwapAForBTx(
  coinAType: string,
  coinBType: string,
  poolId: string,
  coinInId: string,
  minAmountOut: bigint
): Transaction {
  const tx = new Transaction();
  
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULES.POOL_FACTORY}::swap_a_for_b`,
    typeArguments: [coinAType, coinBType],
    arguments: [
      tx.object(poolId),
      tx.object(coinInId),
      tx.pure.u64(minAmountOut),
    ],
  });
  
  return tx;
}

/**
 * Build a transaction to swap token B for token A
 */
export function buildSwapBForATx(
  coinAType: string,
  coinBType: string,
  poolId: string,
  coinInId: string,
  minAmountOut: bigint
): Transaction {
  const tx = new Transaction();
  
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULES.POOL_FACTORY}::swap_b_for_a`,
    typeArguments: [coinAType, coinBType],
    arguments: [
      tx.object(poolId),
      tx.object(coinInId),
      tx.pure.u64(minAmountOut),
    ],
  });
  
  return tx;
}

/**
 * Build a transaction to create a stable swap pool
 */
export function buildCreateStablePoolTx(
  coinAType: string,
  coinBType: string,
  coinAId: string,
  coinBId: string,
  amplification: number,
  feeTier: number
): Transaction {
  const tx = new Transaction();
  
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULES.STABLE_SWAP_POOL}::create_stable_pool`,
    typeArguments: [coinAType, coinBType],
    arguments: [
      tx.object(coinAId),
      tx.object(coinBId),
      tx.pure.u64(amplification),
      tx.pure.u64(feeTier),
      tx.object(CLOCK_ID),
    ],
  });
  
  return tx;
}

/**
 * Calculate the expected output amount for a swap (client-side estimation)
 * Uses the constant product formula: output = (input * fee_factor * reserve_out) / (reserve_in + input * fee_factor)
 */
export function calculateSwapOutput(
  amountIn: bigint,
  reserveIn: bigint,
  reserveOut: bigint,
  feeTierBps: number
): bigint {
  if (amountIn === 0n || reserveIn === 0n || reserveOut === 0n) {
    return 0n;
  }
  
  const feeMultiplier = 10000n - BigInt(feeTierBps);
  const amountInWithFee = amountIn * feeMultiplier;
  const numerator = amountInWithFee * reserveOut;
  const denominator = reserveIn * 10000n + amountInWithFee;
  
  return numerator / denominator;
}

/**
 * Calculate the price impact of a swap as a percentage (in basis points)
 */
export function calculatePriceImpact(
  amountIn: bigint,
  reserveIn: bigint,
  reserveOut: bigint,
  feeTierBps: number
): number {
  if (amountIn === 0n || reserveIn === 0n || reserveOut === 0n) {
    return 0;
  }
  
  // Spot price before swap
  const spotPriceBefore = (reserveOut * 10000n) / reserveIn;
  
  // Calculate output
  const amountOut = calculateSwapOutput(amountIn, reserveIn, reserveOut, feeTierBps);
  
  // Effective price
  const effectivePrice = (amountOut * 10000n) / amountIn;
  
  // Price impact in basis points
  const impact = Number(((spotPriceBefore - effectivePrice) * 10000n) / spotPriceBefore);
  
  return Math.max(0, impact);
}

/**
 * Calculate LP tokens to receive for adding liquidity
 */
export function calculateLpTokens(
  amountA: bigint,
  amountB: bigint,
  reserveA: bigint,
  reserveB: bigint,
  totalSupply: bigint
): bigint {
  if (totalSupply === 0n) {
    // Initial liquidity: sqrt(amountA * amountB) - MINIMUM_LIQUIDITY (1000)
    const product = amountA * amountB;
    const sqrt = bigIntSqrt(product);
    return sqrt - 1000n;
  }
  
  // Subsequent liquidity: min(amountA * totalSupply / reserveA, amountB * totalSupply / reserveB)
  const lpFromA = (amountA * totalSupply) / reserveA;
  const lpFromB = (amountB * totalSupply) / reserveB;
  
  return lpFromA < lpFromB ? lpFromA : lpFromB;
}

/**
 * Calculate token amounts to receive when removing liquidity
 */
export function calculateRemoveLiquidityAmounts(
  lpTokens: bigint,
  reserveA: bigint,
  reserveB: bigint,
  totalSupply: bigint
): { amountA: bigint; amountB: bigint } {
  if (totalSupply === 0n) {
    return { amountA: 0n, amountB: 0n };
  }
  
  const amountA = (lpTokens * reserveA) / totalSupply;
  const amountB = (lpTokens * reserveB) / totalSupply;
  
  return { amountA, amountB };
}

/**
 * BigInt square root using Newton's method
 */
function bigIntSqrt(value: bigint): bigint {
  if (value < 0n) {
    throw new Error("Square root of negative number");
  }
  if (value < 2n) {
    return value;
  }
  
  let x = value;
  let y = (x + 1n) / 2n;
  
  while (y < x) {
    x = y;
    y = (x + value / x) / 2n;
  }
  
  return x;
}

/**
 * Format token amount with decimals
 */
export function formatTokenAmount(amount: bigint, decimals: number, displayDecimals: number = 4): string {
  const divisor = 10n ** BigInt(decimals);
  const wholePart = amount / divisor;
  const fractionalPart = amount % divisor;
  
  const fractionalStr = fractionalPart.toString().padStart(decimals, '0');
  const displayFractional = fractionalStr.slice(0, displayDecimals);
  
  return `${wholePart.toLocaleString()}.${displayFractional}`;
}

/**
 * Parse token amount from string input
 */
export function parseTokenAmount(input: string, decimals: number): bigint {
  const [whole, fraction = ""] = input.split(".");
  const paddedFraction = fraction.padEnd(decimals, "0").slice(0, decimals);
  return BigInt(whole + paddedFraction);
}


