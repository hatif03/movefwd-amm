"use client";

import { useState, useMemo, useEffect } from "react";
import { 
  ArrowDownUp, 
  Settings, 
  Info, 
  ChevronDown,
  Loader2,
  AlertTriangle,
  Check,
  ExternalLink
} from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useCurrentAccount, useSignAndExecuteTransaction, useSuiClient } from "@mysten/dapp-kit";
import { Transaction } from "@mysten/sui/transactions";
import { toast } from "sonner";
import { 
  DEMO_TOKENS, 
  TokenSymbol,
  PACKAGE_ID,
  MODULES,
  getObjectUrl,
  getTxUrl,
} from "@/lib/sui/constants";
import { 
  calculateSwapOutput, 
  calculatePriceImpact,
  formatTokenAmount,
  parseTokenAmount,
} from "@/lib/sui/transactions";
import { useTokenBalances, useAllPools } from "@/lib/sui/queries";
import { MOCK_POOLS, formatUsd, formatNumber } from "@/lib/mock-data";

const SLIPPAGE_OPTIONS = [0.1, 0.5, 1.0, 3.0];

export default function SwapPage() {
  const account = useCurrentAccount();
  const client = useSuiClient();
  const { mutate: signAndExecute, isPending } = useSignAndExecuteTransaction();
  const { data: balances, refetch: refetchBalances } = useTokenBalances();
  const { data: realPools } = useAllPools();

  const [tokenFrom, setTokenFrom] = useState<TokenSymbol>("USDC");
  const [tokenTo, setTokenTo] = useState<TokenSymbol>("ETH");
  const [amountFrom, setAmountFrom] = useState("");
  const [slippage, setSlippage] = useState(0.5);
  const [showSettings, setShowSettings] = useState(false);
  const [isSwapping, setIsSwapping] = useState(false);

  // Find the relevant pool - prefer real pools, fallback to mock
  const pool = useMemo(() => {
    // First try to find a real pool from the blockchain
    const realPool = realPools?.find(
      (p) =>
        (p.tokenA === tokenFrom && p.tokenB === tokenTo) ||
        (p.tokenA === tokenTo && p.tokenB === tokenFrom)
    );
    if (realPool) return realPool;
    
    // Fallback to mock pool for demo
    return MOCK_POOLS.find(
      (p) =>
        (p.tokenA === tokenFrom && p.tokenB === tokenTo) ||
        (p.tokenA === tokenTo && p.tokenB === tokenFrom)
    );
  }, [tokenFrom, tokenTo, realPools]);
  
  // Check if this is a real on-chain pool
  const isRealPool = realPools?.some(p => p.id === pool?.id) ?? false;

  // Calculate output amount
  const { amountOut, priceImpact, rate } = useMemo(() => {
    if (!pool || !amountFrom || isNaN(parseFloat(amountFrom))) {
      return { amountOut: "0", priceImpact: 0, rate: 0 };
    }

    const tokenFromInfo = DEMO_TOKENS[tokenFrom];
    const tokenToInfo = DEMO_TOKENS[tokenTo];
    const amountIn = parseTokenAmount(amountFrom, tokenFromInfo.decimals);

    const isAToB = pool.tokenA === tokenFrom;
    const reserveIn = isAToB ? pool.reserveA : pool.reserveB;
    const reserveOut = isAToB ? pool.reserveB : pool.reserveA;

    const output = calculateSwapOutput(amountIn, reserveIn, reserveOut, pool.feeTier);
    const impact = calculatePriceImpact(amountIn, reserveIn, reserveOut, pool.feeTier);

    // Calculate rate
    const rateValue = Number(reserveOut) / Number(reserveIn);

    return {
      amountOut: formatTokenAmount(output, tokenToInfo.decimals, 6),
      priceImpact: impact / 100, // Convert from basis points to percentage
      rate: rateValue,
    };
  }, [pool, amountFrom, tokenFrom, tokenTo]);

  // Swap tokens direction
  const handleSwapDirection = () => {
    setTokenFrom(tokenTo);
    setTokenTo(tokenFrom);
    setAmountFrom("");
  };

  // Get balance for display
  const getBalance = (symbol: TokenSymbol) => {
    if (!balances || !balances[symbol]) return "0.00";
    const token = DEMO_TOKENS[symbol];
    return formatTokenAmount(balances[symbol].balance, token.decimals, 4);
  };

  // Handle max button
  const handleMax = () => {
    if (!balances || !balances[tokenFrom]) return;
    const token = DEMO_TOKENS[tokenFrom];
    setAmountFrom(formatTokenAmount(balances[tokenFrom].balance, token.decimals, token.decimals));
  };

  // Execute swap
  const handleSwap = async () => {
    if (!account || !pool || !amountFrom) return;

    setIsSwapping(true);
    
    toast.info("Swap", {
      description: "Please confirm the transaction in your wallet",
    });

    try {
      // Check if this is a real on-chain pool
      if (isRealPool && balances?.[tokenFrom]?.objects.length) {
        // Build real transaction
        const tokenFromInfo = DEMO_TOKENS[tokenFrom];
        const tokenToInfo = DEMO_TOKENS[tokenTo];
        const amountIn = parseTokenAmount(amountFrom, tokenFromInfo.decimals);
        
        // Calculate minimum output with slippage
        const expectedOut = parseTokenAmount(amountOut, tokenToInfo.decimals);
        const minAmountOut = expectedOut - (expectedOut * BigInt(Math.floor(slippage * 100))) / 10000n;
        
        const isAToB = pool.tokenA === tokenFrom;
        
        const tx = new Transaction();
        
        // Get the user's coin objects for the input token
        const coinObjects = balances[tokenFrom].objects;
        
        // Merge coins if needed and split exact amount
        if (coinObjects.length > 1) {
          const [primaryCoin, ...otherCoins] = coinObjects;
          tx.mergeCoins(tx.object(primaryCoin), otherCoins.map(id => tx.object(id)));
        }
        
        const coinToSwap = tx.splitCoins(tx.object(coinObjects[0]), [tx.pure.u64(amountIn)]);
        
        // Call the swap function
        const swapFunction = isAToB ? "swap_a_for_b" : "swap_b_for_a";
        const coinOut = tx.moveCall({
          target: `${PACKAGE_ID}::${MODULES.POOL_FACTORY}::${swapFunction}`,
          typeArguments: [
            DEMO_TOKENS[pool.tokenA].type,
            DEMO_TOKENS[pool.tokenB].type,
          ],
          arguments: [
            tx.object(pool.id),
            coinToSwap,
            tx.pure.u64(minAmountOut),
          ],
        });
        
        // Transfer the output coin to the user
        tx.transferObjects([coinOut], tx.pure.address(account.address));
        
        // Execute the transaction
        signAndExecute(
          { transaction: tx },
          {
            onSuccess: (result) => {
              toast.success("Swap Successful!", {
                description: `Swapped ${amountFrom} ${tokenFrom} for ~${amountOut} ${tokenTo}`,
                action: {
                  label: "View",
                  onClick: () => window.open(getTxUrl(result.digest), "_blank"),
                },
              });
              setAmountFrom("");
              refetchBalances();
              setIsSwapping(false);
            },
            onError: (error) => {
              toast.error("Swap Failed", {
                description: error.message || "Transaction failed",
              });
              setIsSwapping(false);
            },
          }
        );
        return;
      }
      
      // Fallback: Simulate for demo/mock pools
      await new Promise((resolve) => setTimeout(resolve, 2000));

      toast.success("Swap Simulated!", {
        description: `Demo: ${amountFrom} ${tokenFrom} → ${amountOut} ${tokenTo}. Connect to a real pool for actual swaps.`,
      });

      setAmountFrom("");
      refetchBalances();
    } catch (error) {
      toast.error("Swap Failed", {
        description: error instanceof Error ? error.message : "Unknown error occurred",
      });
    } finally {
      setIsSwapping(false);
    }
  };

  const tokenFromInfo = DEMO_TOKENS[tokenFrom];
  const tokenToInfo = DEMO_TOKENS[tokenTo];

  const isValidSwap = 
    account && 
    pool && 
    amountFrom && 
    parseFloat(amountFrom) > 0 && 
    priceImpact < 15;

  return (
    <div className="max-w-lg mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-white">Swap</h1>
          <p className="text-[#8b92a5] text-sm">Trade tokens instantly</p>
        </div>
        <Dialog open={showSettings} onOpenChange={setShowSettings}>
          <DialogTrigger asChild>
            <Button variant="ghost" size="icon" className="text-[#8b92a5] hover:text-white">
              <Settings className="w-5 h-5" />
            </Button>
          </DialogTrigger>
          <DialogContent className="glass-card border-white/10">
            <DialogHeader>
              <DialogTitle className="text-white">Swap Settings</DialogTitle>
            </DialogHeader>
            <div className="space-y-4">
              <div>
                <label className="text-sm text-[#8b92a5] mb-2 block">Slippage Tolerance</label>
                <div className="flex gap-2">
                  {SLIPPAGE_OPTIONS.map((option) => (
                    <Button
                      key={option}
                      variant={slippage === option ? "default" : "outline"}
                      size="sm"
                      onClick={() => setSlippage(option)}
                      className={slippage === option 
                        ? "bg-[#00d4aa] text-[#0a0e1a]" 
                        : "border-white/10 text-white hover:bg-white/5"
                      }
                    >
                      {option}%
                    </Button>
                  ))}
                </div>
              </div>
              <div className="p-3 rounded-lg bg-[#1a2035] border border-white/5">
                <div className="flex items-start gap-2">
                  <Info className="w-4 h-4 text-[#8b92a5] mt-0.5" />
                  <p className="text-xs text-[#8b92a5]">
                    Your transaction will revert if the price changes unfavorably by more than this percentage.
                  </p>
                </div>
              </div>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      {/* Swap Card */}
      <Card className="glass-card border-white/5">
        <CardContent className="p-4 space-y-2">
          {/* From Token */}
          <div className="p-4 rounded-xl bg-[#0a0e1a] border border-white/5">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-[#8b92a5]">From</span>
              <span className="text-sm text-[#8b92a5]">
                Balance: <span className="font-mono">{getBalance(tokenFrom)}</span>
                {account && (
                  <button 
                    onClick={handleMax}
                    className="ml-2 text-[#00d4aa] hover:underline"
                  >
                    MAX
                  </button>
                )}
              </span>
            </div>
            <div className="flex items-center gap-3">
              <Input
                type="text"
                placeholder="0.00"
                value={amountFrom}
                onChange={(e) => setAmountFrom(e.target.value)}
                className="flex-1 bg-transparent border-none text-2xl font-mono text-white placeholder:text-[#4a5068] focus-visible:ring-0 p-0"
              />
              <TokenSelector
                value={tokenFrom}
                onChange={setTokenFrom}
                exclude={tokenTo}
              />
            </div>
          </div>

          {/* Swap Direction Button */}
          <div className="flex justify-center -my-4 relative z-10">
            <Button
              variant="ghost"
              size="icon"
              onClick={handleSwapDirection}
              className="w-10 h-10 rounded-xl bg-[#1a2035] border border-white/10 hover:bg-[#00d4aa]/10 hover:border-[#00d4aa]/30 transition-all"
            >
              <ArrowDownUp className="w-4 h-4 text-[#8b92a5]" />
            </Button>
          </div>

          {/* To Token */}
          <div className="p-4 rounded-xl bg-[#0a0e1a] border border-white/5">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-[#8b92a5]">To</span>
              <span className="text-sm text-[#8b92a5]">
                Balance: <span className="font-mono">{getBalance(tokenTo)}</span>
              </span>
            </div>
            <div className="flex items-center gap-3">
              <div className="flex-1 text-2xl font-mono text-white">
                {amountOut !== "0" ? amountOut : "0.00"}
              </div>
              <TokenSelector
                value={tokenTo}
                onChange={setTokenTo}
                exclude={tokenFrom}
              />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Swap Details */}
      {pool && amountFrom && parseFloat(amountFrom) > 0 && (
        <Card className="glass-card border-white/5 mt-4">
          <CardContent className="p-4 space-y-3">
            <div className="flex items-center justify-between text-sm">
              <span className="text-[#8b92a5]">Rate</span>
              <span className="text-white font-mono">
                1 {tokenFrom} = {formatNumber(rate, 6)} {tokenTo}
              </span>
            </div>
            
            <div className="flex items-center justify-between text-sm">
              <span className="text-[#8b92a5]">Price Impact</span>
              <span className={`font-mono ${
                priceImpact > 5 ? 'text-[#ff4757]' : 
                priceImpact > 1 ? 'text-[#f59e0b]' : 
                'text-[#00d4aa]'
              }`}>
                {priceImpact.toFixed(2)}%
              </span>
            </div>
            
            <div className="flex items-center justify-between text-sm">
              <span className="text-[#8b92a5]">Slippage Tolerance</span>
              <span className="text-white font-mono">{slippage}%</span>
            </div>
            
            <div className="flex items-center justify-between text-sm">
              <span className="text-[#8b92a5]">Fee</span>
              <span className="text-white font-mono">{pool.feeTier / 100}%</span>
            </div>

            <div className="flex items-center justify-between text-sm">
              <span className="text-[#8b92a5]">Minimum Received</span>
              <span className="text-white font-mono">
                {formatNumber(parseFloat(amountOut) * (1 - slippage / 100), 6)} {tokenTo}
              </span>
            </div>

            {priceImpact > 5 && (
              <div className="flex items-start gap-2 p-3 rounded-lg bg-[#ff4757]/10 border border-[#ff4757]/20">
                <AlertTriangle className="w-4 h-4 text-[#ff4757] mt-0.5" />
                <div className="text-sm text-[#ff4757]">
                  High price impact! You may receive significantly less tokens.
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Swap Button */}
      <div className="mt-4">
        {!account ? (
          <Button 
            className="w-full h-14 text-lg font-semibold bg-[#1a2035] text-[#8b92a5] hover:bg-[#1a2035]"
            disabled
          >
            Connect Wallet to Swap
          </Button>
        ) : !pool ? (
          <Button 
            className="w-full h-14 text-lg font-semibold bg-[#1a2035] text-[#8b92a5]"
            disabled
          >
            Pool Not Found
          </Button>
        ) : !amountFrom || parseFloat(amountFrom) === 0 ? (
          <Button 
            className="w-full h-14 text-lg font-semibold bg-[#1a2035] text-[#8b92a5]"
            disabled
          >
            Enter Amount
          </Button>
        ) : priceImpact > 15 ? (
          <Button 
            className="w-full h-14 text-lg font-semibold bg-[#ff4757]/20 text-[#ff4757] hover:bg-[#ff4757]/30"
            disabled
          >
            Price Impact Too High
          </Button>
        ) : (
          <Button 
            onClick={handleSwap}
            disabled={isSwapping || isPending}
            className="w-full h-14 text-lg font-semibold bg-gradient-to-r from-[#00d4aa] to-[#00a8ff] text-[#0a0e1a] hover:opacity-90 transition-opacity"
          >
            {isSwapping || isPending ? (
              <>
                <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                Swapping...
              </>
            ) : (
              `Swap ${tokenFrom} for ${tokenTo}`
            )}
          </Button>
        )}
      </div>

      {/* Pool Info */}
      {pool && (
        <div className="mt-4 text-center">
          <a 
            href={getObjectUrl(pool.id)}
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm text-[#8b92a5] hover:text-[#00d4aa] inline-flex items-center gap-1"
          >
            View Pool on Explorer
            <ExternalLink className="w-3 h-3" />
          </a>
        </div>
      )}
    </div>
  );
}

function TokenSelector({
  value,
  onChange,
  exclude,
}: {
  value: TokenSymbol;
  onChange: (value: TokenSymbol) => void;
  exclude: TokenSymbol;
}) {
  const token = DEMO_TOKENS[value];
  const availableTokens = Object.keys(DEMO_TOKENS).filter(
    (t) => t !== exclude
  ) as TokenSymbol[];

  return (
    <Select value={value} onValueChange={onChange}>
      <SelectTrigger className="w-auto min-w-[140px] bg-[#1a2035] border-white/10 text-white">
        <div className="flex items-center gap-2">
          <span className="text-xl">{token.icon}</span>
          <span className="font-semibold">{token.symbol}</span>
        </div>
      </SelectTrigger>
      <SelectContent className="bg-[#0f1629] border-white/10">
        {availableTokens.map((symbol) => {
          const t = DEMO_TOKENS[symbol];
          return (
            <SelectItem 
              key={symbol} 
              value={symbol}
              className="text-white hover:bg-white/5 focus:bg-white/5"
            >
              <div className="flex items-center gap-2">
                <span className="text-xl">{t.icon}</span>
                <div>
                  <div className="font-semibold">{t.symbol}</div>
                  <div className="text-xs text-[#8b92a5]">{t.name}</div>
                </div>
              </div>
            </SelectItem>
          );
        })}
      </SelectContent>
    </Select>
  );
}

