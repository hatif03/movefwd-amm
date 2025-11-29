import { useSuiClient, useCurrentAccount } from "@mysten/dapp-kit";
import { useQuery } from "@tanstack/react-query";
import { 
  PACKAGE_ID, 
  POOL_FACTORY_ID, 
  LP_POSITION_NFT_TYPE,
  DEMO_TOKENS,
  TokenSymbol,
  TREASURY_CAP_TYPES,
} from "./constants";

/**
 * Hook to fetch user's coin balances for demo tokens
 */
export function useTokenBalances() {
  const client = useSuiClient();
  const account = useCurrentAccount();
  
  return useQuery({
    queryKey: ["tokenBalances", account?.address],
    queryFn: async () => {
      if (!account?.address) return null;
      
      const balances: Record<TokenSymbol, { balance: bigint; objects: string[] }> = {
        USDC: { balance: 0n, objects: [] },
        USDT: { balance: 0n, objects: [] },
        ETH: { balance: 0n, objects: [] },
        BTC: { balance: 0n, objects: [] },
        WSUI: { balance: 0n, objects: [] },
      };
      
      for (const [symbol, token] of Object.entries(DEMO_TOKENS)) {
        try {
          const coins = await client.getCoins({
            owner: account.address,
            coinType: token.type,
          });
          
          let totalBalance = 0n;
          const objectIds: string[] = [];
          
          for (const coin of coins.data) {
            totalBalance += BigInt(coin.balance);
            objectIds.push(coin.coinObjectId);
          }
          
          balances[symbol as TokenSymbol] = {
            balance: totalBalance,
            objects: objectIds,
          };
        } catch (error) {
          console.error(`Error fetching ${symbol} balance:`, error);
        }
      }
      
      return balances;
    },
    enabled: !!account?.address,
    refetchInterval: 10000, // Refetch every 10 seconds
  });
}

/**
 * Hook to fetch user's LP Position NFTs
 */
export function useLPPositions() {
  const client = useSuiClient();
  const account = useCurrentAccount();
  
  return useQuery({
    queryKey: ["lpPositions", account?.address],
    queryFn: async () => {
      if (!account?.address) return [];
      
      const objects = await client.getOwnedObjects({
        owner: account.address,
        filter: {
          StructType: LP_POSITION_NFT_TYPE,
        },
        options: {
          showContent: true,
          showType: true,
        },
      });
      
      return objects.data.map((obj) => {
        const content = obj.data?.content;
        if (content?.dataType !== "moveObject") return null;
        
        const fields = content.fields as Record<string, unknown>;
        
        return {
          id: obj.data?.objectId,
          poolId: fields.pool_id as string,
          lpTokens: BigInt(fields.lp_tokens as string),
          initialAmountA: BigInt(fields.initial_amount_a as string),
          initialAmountB: BigInt(fields.initial_amount_b as string),
          feesEarnedA: BigInt(fields.fees_earned_a as string || "0"),
          feesEarnedB: BigInt(fields.fees_earned_b as string || "0"),
          createdAt: Number(fields.created_at as string),
        };
      }).filter(Boolean);
    },
    enabled: !!account?.address,
    refetchInterval: 15000,
  });
}

/**
 * Hook to fetch the Pool Factory object
 */
export function usePoolFactory() {
  const client = useSuiClient();
  
  return useQuery({
    queryKey: ["poolFactory"],
    queryFn: async () => {
      const object = await client.getObject({
        id: POOL_FACTORY_ID,
        options: {
          showContent: true,
        },
      });
      
      if (object.data?.content?.dataType !== "moveObject") {
        return null;
      }
      
      const fields = object.data.content.fields as Record<string, unknown>;
      
      return {
        id: POOL_FACTORY_ID,
        totalPools: Number(fields.total_pools as string || "0"),
        creationPaused: fields.creation_paused as boolean,
        protocolFeeRecipient: fields.protocol_fee_recipient as string,
      };
    },
    refetchInterval: 30000,
  });
}

/**
 * Hook to fetch a specific liquidity pool
 */
export function usePool(poolId: string | undefined) {
  const client = useSuiClient();
  
  return useQuery({
    queryKey: ["pool", poolId],
    queryFn: async () => {
      if (!poolId) return null;
      
      const object = await client.getObject({
        id: poolId,
        options: {
          showContent: true,
          showType: true,
        },
      });
      
      if (object.data?.content?.dataType !== "moveObject") {
        return null;
      }
      
      const fields = object.data.content.fields as Record<string, unknown>;
      const type = object.data.content.type;
      
      // Extract token types from the pool type
      // e.g., "0x...::pool_factory::LiquidityPool<0x...::demo_tokens::DEMO_USDC, 0x...::demo_tokens::DEMO_ETH>"
      const typeMatch = type.match(/<(.+),\s*(.+)>/);
      const coinAType = typeMatch?.[1] || "";
      const coinBType = typeMatch?.[2] || "";
      
      return {
        id: poolId,
        type,
        coinAType,
        coinBType,
        reserveA: BigInt((fields.reserve_a as { fields?: { value?: string } })?.fields?.value || "0"),
        reserveB: BigInt((fields.reserve_b as { fields?: { value?: string } })?.fields?.value || "0"),
        feeTier: Number(fields.fee_tier as string || "30"),
        totalSupply: BigInt(fields.total_supply as string || "0"),
        isPaused: fields.is_paused as boolean,
        feeGrowthGlobalA: BigInt(fields.fee_growth_global_a as string || "0"),
        feeGrowthGlobalB: BigInt(fields.fee_growth_global_b as string || "0"),
      };
    },
    enabled: !!poolId,
    refetchInterval: 10000,
  });
}

/**
 * Hook to find treasury caps owned by a specific address
 */
export function useTreasuryCaps() {
  const client = useSuiClient();
  const account = useCurrentAccount();
  
  return useQuery({
    queryKey: ["treasuryCaps", account?.address],
    queryFn: async () => {
      if (!account?.address) return null;
      
      const caps: Partial<Record<TokenSymbol, string>> = {};
      
      for (const [symbol, capType] of Object.entries(TREASURY_CAP_TYPES)) {
        try {
          const objects = await client.getOwnedObjects({
            owner: account.address,
            filter: {
              StructType: capType,
            },
          });
          
          if (objects.data.length > 0) {
            caps[symbol as TokenSymbol] = objects.data[0].data?.objectId;
          }
        } catch (error) {
          console.error(`Error fetching ${symbol} treasury cap:`, error);
        }
      }
      
      return caps;
    },
    enabled: !!account?.address,
    staleTime: 60000, // Cache for 1 minute
  });
}

/**
 * Hook to fetch all liquidity pools from the blockchain
 */
export function useAllPools() {
  const client = useSuiClient();
  
  return useQuery({
    queryKey: ["allPools"],
    queryFn: async () => {
      try {
        // Query for all LiquidityPool objects owned by anyone (shared objects)
        const poolType = `${PACKAGE_ID}::pool_factory::LiquidityPool`;
        
        const objects = await client.queryEvents({
          query: {
            MoveEventType: `${PACKAGE_ID}::events::PoolCreated`,
          },
          limit: 50,
          order: "descending",
        });
        
        const pools: Array<{
          id: string;
          tokenA: TokenSymbol;
          tokenB: TokenSymbol;
          reserveA: bigint;
          reserveB: bigint;
          feeTier: number;
          totalSupply: bigint;
        }> = [];
        
        for (const event of objects.data) {
          const parsed = event.parsedJson as Record<string, unknown>;
          const poolId = parsed.pool_id as string;
          
          if (poolId) {
            try {
              const poolObj = await client.getObject({
                id: poolId,
                options: { showContent: true, showType: true },
              });
              
              if (poolObj.data?.content?.dataType === "moveObject") {
                const fields = poolObj.data.content.fields as Record<string, unknown>;
                const type = poolObj.data.content.type;
                
                // Extract token types
                const typeMatch = type.match(/<(.+),\s*(.+)>/);
                const coinAType = typeMatch?.[1] || "";
                const coinBType = typeMatch?.[2] || "";
                
                // Map type to symbol
                const tokenA = Object.entries(DEMO_TOKENS).find(([, t]) => coinAType.includes(t.type.split("::").pop() || ""))?.[0] as TokenSymbol;
                const tokenB = Object.entries(DEMO_TOKENS).find(([, t]) => coinBType.includes(t.type.split("::").pop() || ""))?.[0] as TokenSymbol;
                
                if (tokenA && tokenB) {
                  pools.push({
                    id: poolId,
                    tokenA,
                    tokenB,
                    reserveA: BigInt((fields.reserve_a as { fields?: { value?: string } })?.fields?.value || "0"),
                    reserveB: BigInt((fields.reserve_b as { fields?: { value?: string } })?.fields?.value || "0"),
                    feeTier: Number(fields.fee_tier || "30"),
                    totalSupply: BigInt(fields.total_supply as string || "0"),
                  });
                }
              }
            } catch (e) {
              console.error(`Error fetching pool ${poolId}:`, e);
            }
          }
        }
        
        return pools;
      } catch (error) {
        console.error("Error fetching pools:", error);
        return [];
      }
    },
    refetchInterval: 30000,
  });
}

/**
 * Hook to fetch events from the package
 */
export function useRecentEvents(limit: number = 20) {
  const client = useSuiClient();
  
  return useQuery({
    queryKey: ["recentEvents", limit],
    queryFn: async () => {
      try {
        const events = await client.queryEvents({
          query: {
            MoveModule: {
              package: PACKAGE_ID,
              module: "events",
            },
          },
          limit,
          order: "descending",
        });
        
        return events.data.map((event) => ({
          id: event.id.txDigest,
          type: event.type.split("::").pop() || "Unknown",
          timestamp: Number(event.timestampMs || Date.now()),
          parsedJson: event.parsedJson as Record<string, unknown>,
        }));
      } catch (error) {
        console.error("Error fetching events:", error);
        return [];
      }
    },
    refetchInterval: 15000,
  });
}

/**
 * Get token info from type string
 */
export function getTokenFromType(type: string): typeof DEMO_TOKENS[TokenSymbol] | null {
  for (const [, token] of Object.entries(DEMO_TOKENS)) {
    if (type.includes(token.type) || type.endsWith(token.symbol)) {
      return token;
    }
  }
  return null;
}

