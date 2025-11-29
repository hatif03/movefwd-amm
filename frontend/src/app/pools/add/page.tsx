"use client";

import { useState, useMemo, Suspense } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import Link from "next/link";
import { 
  ArrowLeft, 
  Plus, 
  Info, 
  AlertTriangle,
  Loader2,
  Check,
  Settings,
  Zap
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { useCurrentAccount, useSignAndExecuteTransaction } from "@mysten/dapp-kit";
import { toast } from "sonner";
import { 
  DEMO_TOKENS, 
  TokenSymbol, 
  FEE_TIERS,
  getTxUrl 
} from "@/lib/sui/constants";
import { 
  calculateLpTokens,
  formatTokenAmount,
  parseTokenAmount,
} from "@/lib/sui/transactions";
import { useTokenBalances } from "@/lib/sui/queries";
import { MOCK_POOLS, formatUsd, formatNumber, getTokenInfo } from "@/lib/mock-data";

function AddLiquidityContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const poolIdParam = searchParams.get("pool");
  
  const account = useCurrentAccount();
  const { mutate: signAndExecute, isPending } = useSignAndExecuteTransaction();
  const { data: balances, refetch: refetchBalances } = useTokenBalances();

  const [tokenA, setTokenA] = useState<TokenSymbol>("USDC");
  const [tokenB, setTokenB] = useState<TokenSymbol>("ETH");
  const [amountA, setAmountA] = useState("");
  const [amountB, setAmountB] = useState("");
  const [feeTier, setFeeTier] = useState(30);
  const [slippage, setSlippage] = useState(0.5);
  const [isAdding, setIsAdding] = useState(false);
  const [isNewPool, setIsNewPool] = useState(false);

  // Find existing pool
  const existingPool = useMemo(() => {
    return MOCK_POOLS.find(
      (p) =>
        (p.tokenA === tokenA && p.tokenB === tokenB) ||
        (p.tokenA === tokenB && p.tokenB === tokenA)
    );
  }, [tokenA, tokenB]);

  // Calculate estimated LP tokens and share
  const { lpTokens, sharePercent } = useMemo(() => {
    if (!amountA || !amountB || isNaN(parseFloat(amountA)) || isNaN(parseFloat(amountB))) {
      return { lpTokens: 0n, sharePercent: 0 };
    }

    const tokenAInfo = DEMO_TOKENS[tokenA];
    const tokenBInfo = DEMO_TOKENS[tokenB];
    const parsedAmountA = parseTokenAmount(amountA, tokenAInfo.decimals);
    const parsedAmountB = parseTokenAmount(amountB, tokenBInfo.decimals);

    if (existingPool) {
      const lp = calculateLpTokens(
        parsedAmountA,
        parsedAmountB,
        existingPool.reserveA,
        existingPool.reserveB,
        existingPool.totalSupply
      );
      const newTotal = existingPool.totalSupply + lp;
      const share = (Number(lp) / Number(newTotal)) * 100;
      return { lpTokens: lp, sharePercent: share };
    } else {
      // New pool
      const lp = calculateLpTokens(parsedAmountA, parsedAmountB, 0n, 0n, 0n);
      return { lpTokens: lp, sharePercent: 100 };
    }
  }, [amountA, amountB, tokenA, tokenB, existingPool]);

  // Get balance for display
  const getBalance = (symbol: TokenSymbol) => {
    if (!balances || !balances[symbol]) return "0.00";
    const token = DEMO_TOKENS[symbol];
    return formatTokenAmount(balances[symbol].balance, token.decimals, 4);
  };

  // Handle max button
  const handleMaxA = () => {
    if (!balances || !balances[tokenA]) return;
    const token = DEMO_TOKENS[tokenA];
    setAmountA(formatTokenAmount(balances[tokenA].balance, token.decimals, token.decimals));
  };

  const handleMaxB = () => {
    if (!balances || !balances[tokenB]) return;
    const token = DEMO_TOKENS[tokenB];
    setAmountB(formatTokenAmount(balances[tokenB].balance, token.decimals, token.decimals));
  };

  // Auto-calculate balanced amounts for existing pools
  const handleAmountAChange = (value: string) => {
    setAmountA(value);
    if (existingPool && value && !isNaN(parseFloat(value))) {
      const tokenAInfo = DEMO_TOKENS[tokenA];
      const tokenBInfo = DEMO_TOKENS[tokenB];
      const isAFirst = existingPool.tokenA === tokenA;
      const reserveA = isAFirst ? existingPool.reserveA : existingPool.reserveB;
      const reserveB = isAFirst ? existingPool.reserveB : existingPool.reserveA;
      
      const parsedA = parseTokenAmount(value, tokenAInfo.decimals);
      const calculatedB = (parsedA * reserveB) / reserveA;
      setAmountB(formatTokenAmount(calculatedB, tokenBInfo.decimals, 6));
    }
  };

  const handleAmountBChange = (value: string) => {
    setAmountB(value);
    if (existingPool && value && !isNaN(parseFloat(value))) {
      const tokenAInfo = DEMO_TOKENS[tokenA];
      const tokenBInfo = DEMO_TOKENS[tokenB];
      const isAFirst = existingPool.tokenA === tokenA;
      const reserveA = isAFirst ? existingPool.reserveA : existingPool.reserveB;
      const reserveB = isAFirst ? existingPool.reserveB : existingPool.reserveA;
      
      const parsedB = parseTokenAmount(value, tokenBInfo.decimals);
      const calculatedA = (parsedB * reserveA) / reserveB;
      setAmountA(formatTokenAmount(calculatedA, tokenAInfo.decimals, 6));
    }
  };

  // Execute add liquidity
  const handleAddLiquidity = async () => {
    if (!account || !amountA || !amountB) return;

    setIsAdding(true);
    
    toast.info(existingPool ? "Adding Liquidity" : "Creating Pool", {
      description: "Please confirm the transaction in your wallet",
    });

    try {
      // Simulate transaction for demo
      await new Promise((resolve) => setTimeout(resolve, 2000));

      toast.success(existingPool ? "Liquidity Added!" : "Pool Created!", {
        description: `You received an LP Position NFT for ${tokenA}/${tokenB}`,
        action: {
          label: "View",
          onClick: () => window.open(getTxUrl("demo-tx-hash"), "_blank"),
        },
      });

      router.push("/positions");
    } catch (error) {
      toast.error("Transaction Failed", {
        description: error instanceof Error ? error.message : "Unknown error occurred",
      });
    } finally {
      setIsAdding(false);
    }
  };

  const tokenAInfo = DEMO_TOKENS[tokenA];
  const tokenBInfo = DEMO_TOKENS[tokenB];

  const isValidAdd = 
    account && 
    amountA && 
    amountB && 
    parseFloat(amountA) > 0 && 
    parseFloat(amountB) > 0;

  return (
    <div className="max-w-xl mx-auto">
      {/* Header */}
      <div className="flex items-center gap-4 mb-6">
        <Link href="/pools">
          <Button variant="ghost" size="icon" className="text-[#8b92a5] hover:text-white">
            <ArrowLeft className="w-5 h-5" />
          </Button>
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-white">
            {existingPool ? "Add Liquidity" : "Create Pool"}
          </h1>
          <p className="text-[#8b92a5] text-sm">
            {existingPool 
              ? "Add tokens to an existing pool" 
              : "Create a new liquidity pool"
            }
          </p>
        </div>
      </div>

      {/* Token Selection & Amounts */}
      <Card className="glass-card border-white/5 mb-4">
        <CardContent className="p-4 space-y-4">
          {/* Token A */}
          <div className="p-4 rounded-xl bg-[#0a0e1a] border border-white/5">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-[#8b92a5]">Token A</span>
              <span className="text-sm text-[#8b92a5]">
                Balance: <span className="font-mono">{getBalance(tokenA)}</span>
                {account && (
                  <button 
                    onClick={handleMaxA}
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
                value={amountA}
                onChange={(e) => handleAmountAChange(e.target.value)}
                className="flex-1 bg-transparent border-none text-2xl font-mono text-white placeholder:text-[#4a5068] focus-visible:ring-0 p-0"
              />
              <Select value={tokenA} onValueChange={(v) => {
                if (v === tokenB) setTokenB(tokenA);
                setTokenA(v as TokenSymbol);
                setAmountA("");
                setAmountB("");
              }}>
                <SelectTrigger className="w-auto min-w-[140px] bg-[#1a2035] border-white/10 text-white">
                  <div className="flex items-center gap-2">
                    <span className="text-xl">{tokenAInfo.icon}</span>
                    <span className="font-semibold">{tokenAInfo.symbol}</span>
                  </div>
                </SelectTrigger>
                <SelectContent className="bg-[#0f1629] border-white/10">
                  {Object.keys(DEMO_TOKENS).map((symbol) => {
                    const t = DEMO_TOKENS[symbol as TokenSymbol];
                    return (
                      <SelectItem 
                        key={symbol} 
                        value={symbol}
                        className="text-white hover:bg-white/5"
                      >
                        <div className="flex items-center gap-2">
                          <span className="text-xl">{t.icon}</span>
                          <span>{t.symbol}</span>
                        </div>
                      </SelectItem>
                    );
                  })}
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Plus Icon */}
          <div className="flex justify-center">
            <div className="w-10 h-10 rounded-xl bg-[#1a2035] border border-white/10 flex items-center justify-center">
              <Plus className="w-4 h-4 text-[#8b92a5]" />
            </div>
          </div>

          {/* Token B */}
          <div className="p-4 rounded-xl bg-[#0a0e1a] border border-white/5">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-[#8b92a5]">Token B</span>
              <span className="text-sm text-[#8b92a5]">
                Balance: <span className="font-mono">{getBalance(tokenB)}</span>
                {account && (
                  <button 
                    onClick={handleMaxB}
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
                value={amountB}
                onChange={(e) => handleAmountBChange(e.target.value)}
                className="flex-1 bg-transparent border-none text-2xl font-mono text-white placeholder:text-[#4a5068] focus-visible:ring-0 p-0"
              />
              <Select value={tokenB} onValueChange={(v) => {
                if (v === tokenA) setTokenA(tokenB);
                setTokenB(v as TokenSymbol);
                setAmountA("");
                setAmountB("");
              }}>
                <SelectTrigger className="w-auto min-w-[140px] bg-[#1a2035] border-white/10 text-white">
                  <div className="flex items-center gap-2">
                    <span className="text-xl">{tokenBInfo.icon}</span>
                    <span className="font-semibold">{tokenBInfo.symbol}</span>
                  </div>
                </SelectTrigger>
                <SelectContent className="bg-[#0f1629] border-white/10">
                  {Object.keys(DEMO_TOKENS).map((symbol) => {
                    const t = DEMO_TOKENS[symbol as TokenSymbol];
                    return (
                      <SelectItem 
                        key={symbol} 
                        value={symbol}
                        className="text-white hover:bg-white/5"
                      >
                        <div className="flex items-center gap-2">
                          <span className="text-xl">{t.icon}</span>
                          <span>{t.symbol}</span>
                        </div>
                      </SelectItem>
                    );
                  })}
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Fee Tier (for new pools) */}
      {!existingPool && (
        <Card className="glass-card border-white/5 mb-4">
          <CardContent className="p-4">
            <div className="flex items-center justify-between mb-3">
              <span className="text-sm text-white font-medium">Fee Tier</span>
              <span className="text-xs text-[#8b92a5]">
                Higher fees = more earnings per trade
              </span>
            </div>
            <div className="grid grid-cols-3 gap-2">
              {[
                { value: 5, label: "0.05%", desc: "Best for stable pairs" },
                { value: 30, label: "0.3%", desc: "Standard pairs" },
                { value: 100, label: "1%", desc: "Exotic pairs" },
              ].map((tier) => (
                <button
                  key={tier.value}
                  onClick={() => setFeeTier(tier.value)}
                  className={`p-3 rounded-xl border transition-all ${
                    feeTier === tier.value
                      ? "bg-[#00d4aa]/10 border-[#00d4aa]/30 text-white"
                      : "bg-[#0a0e1a] border-white/5 text-[#8b92a5] hover:border-white/10"
                  }`}
                >
                  <div className="text-lg font-bold">{tier.label}</div>
                  <div className="text-xs">{tier.desc}</div>
                </button>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Position Preview */}
      {amountA && amountB && parseFloat(amountA) > 0 && parseFloat(amountB) > 0 && (
        <Card className="glass-card border-white/5 mb-4">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-[#8b92a5]">Position Preview</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-[#8b92a5]">Pool</span>
              <span className="text-white font-semibold">
                {tokenA}/{tokenB}
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-[#8b92a5]">Fee Tier</span>
              <span className="text-white font-mono">
                {(existingPool?.feeTier || feeTier) / 100}%
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-[#8b92a5]">Your Share</span>
              <span className="text-[#00d4aa] font-mono">
                {sharePercent.toFixed(4)}%
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-[#8b92a5]">Est. LP Tokens</span>
              <span className="text-white font-mono">
                {formatTokenAmount(lpTokens, 6, 4)}
              </span>
            </div>
            {existingPool && (
              <div className="flex items-center justify-between">
                <span className="text-[#8b92a5]">Est. APR</span>
                <span className={`font-mono flex items-center gap-1 ${
                  existingPool.apr >= 15 ? 'text-[#00d4aa]' : 'text-white'
                }`}>
                  {existingPool.apr >= 15 && <Zap className="w-3 h-3" />}
                  {existingPool.apr.toFixed(2)}%
                </span>
              </div>
            )}

            <div className="p-3 rounded-lg bg-[#00d4aa]/10 border border-[#00d4aa]/20 mt-4">
              <div className="flex items-start gap-2">
                <Info className="w-4 h-4 text-[#00d4aa] mt-0.5" />
                <p className="text-sm text-[#00d4aa]">
                  You will receive an NFT representing your liquidity position. 
                  This NFT can be transferred and tracks your earned fees.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Add Button */}
      <div>
        {!account ? (
          <Button 
            className="w-full h-14 text-lg font-semibold bg-[#1a2035] text-[#8b92a5]"
            disabled
          >
            Connect Wallet
          </Button>
        ) : !amountA || !amountB || parseFloat(amountA) === 0 || parseFloat(amountB) === 0 ? (
          <Button 
            className="w-full h-14 text-lg font-semibold bg-[#1a2035] text-[#8b92a5]"
            disabled
          >
            Enter Amounts
          </Button>
        ) : (
          <Button 
            onClick={handleAddLiquidity}
            disabled={isAdding || isPending}
            className="w-full h-14 text-lg font-semibold bg-gradient-to-r from-[#00d4aa] to-[#00a8ff] text-[#0a0e1a] hover:opacity-90 transition-opacity"
          >
            {isAdding || isPending ? (
              <>
                <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                {existingPool ? "Adding Liquidity..." : "Creating Pool..."}
              </>
            ) : (
              <>
                <Plus className="w-5 h-5 mr-2" />
                {existingPool ? "Add Liquidity" : "Create Pool & Add Liquidity"}
              </>
            )}
          </Button>
        )}
      </div>
    </div>
  );
}

function AddLiquidityLoading() {
  return (
    <div className="max-w-xl mx-auto">
      <div className="flex items-center gap-4 mb-6">
        <div className="w-10 h-10 rounded-lg bg-[#1a2035] animate-pulse" />
        <div>
          <div className="h-6 w-32 bg-[#1a2035] rounded animate-pulse mb-2" />
          <div className="h-4 w-48 bg-[#1a2035] rounded animate-pulse" />
        </div>
      </div>
      <Card className="glass-card border-white/5">
        <CardContent className="p-4">
          <div className="h-32 bg-[#1a2035] rounded-xl animate-pulse mb-4" />
          <div className="h-10 bg-[#1a2035] rounded-xl animate-pulse mb-4" />
          <div className="h-32 bg-[#1a2035] rounded-xl animate-pulse" />
        </CardContent>
      </Card>
    </div>
  );
}

export default function AddLiquidityPage() {
  return (
    <Suspense fallback={<AddLiquidityLoading />}>
      <AddLiquidityContent />
    </Suspense>
  );
}

