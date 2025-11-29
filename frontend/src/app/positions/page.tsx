"use client";

import { useState, useMemo } from "react";
import Link from "next/link";
import { 
  Wallet, 
  Plus, 
  Minus,
  ExternalLink,
  TrendingUp,
  TrendingDown,
  Clock,
  Coins,
  Info,
  AlertCircle,
  Loader2,
  ChevronDown,
  ChevronUp
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Separator } from "@/components/ui/separator";
import { useCurrentAccount, useSignAndExecuteTransaction } from "@mysten/dapp-kit";
import { toast } from "sonner";
import { DEMO_TOKENS, TokenSymbol, getObjectUrl, getTxUrl } from "@/lib/sui/constants";
import { formatTokenAmount, calculateRemoveLiquidityAmounts } from "@/lib/sui/transactions";
import { useLPPositions } from "@/lib/sui/queries";
import { MOCK_POOLS, formatUsd, formatNumber, getTokenInfo, getRelativeTime } from "@/lib/mock-data";

// Mock positions for demo (since real positions would require actual transactions)
const MOCK_POSITIONS = [
  {
    id: "0xpos1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
    poolId: MOCK_POOLS[0].id,
    tokenA: "USDC" as TokenSymbol,
    tokenB: "ETH" as TokenSymbol,
    lpTokens: 15000_000000n,
    initialAmountA: 25000_000000n,
    initialAmountB: 7_600000000000000000n,
    currentAmountA: 26250_000000n,
    currentAmountB: 7_980000000000000000n,
    feesEarnedA: 125_000000n,
    feesEarnedB: 38_000000000000000n,
    createdAt: Date.now() - 14 * 24 * 60 * 60 * 1000, // 14 days ago
    valueUsd: 52500,
    pnlPercent: 5.0,
    ilPercent: -0.8,
  },
  {
    id: "0xpos234567890abcdef1234567890abcdef1234567890abcdef1234567890ab",
    poolId: MOCK_POOLS[1].id,
    tokenA: "USDC" as TokenSymbol,
    tokenB: "USDT" as TokenSymbol,
    lpTokens: 50000_000000n,
    initialAmountA: 50000_000000n,
    initialAmountB: 49950_000000n,
    currentAmountA: 50000_000000n,
    currentAmountB: 49950_000000n,
    feesEarnedA: 15_600000n,
    feesEarnedB: 15_550000n,
    createdAt: Date.now() - 30 * 24 * 60 * 60 * 1000, // 30 days ago
    valueUsd: 99950,
    pnlPercent: 0.03,
    ilPercent: 0,
  },
];

export default function PositionsPage() {
  const account = useCurrentAccount();
  const { mutate: signAndExecute, isPending } = useSignAndExecuteTransaction();
  
  const [selectedPosition, setSelectedPosition] = useState<typeof MOCK_POSITIONS[0] | null>(null);
  const [removeAmount, setRemoveAmount] = useState("");
  const [isRemoving, setIsRemoving] = useState(false);
  const [expandedPosition, setExpandedPosition] = useState<string | null>(null);

  // Calculate total portfolio value
  const totalValue = MOCK_POSITIONS.reduce((sum, pos) => sum + pos.valueUsd, 0);
  const totalPnl = MOCK_POSITIONS.reduce((sum, pos) => sum + (pos.valueUsd * pos.pnlPercent / 100), 0);

  // Handle remove liquidity
  const handleRemoveLiquidity = async () => {
    if (!selectedPosition || !removeAmount) return;

    setIsRemoving(true);
    
    toast.info("Removing Liquidity", {
      description: "Please confirm the transaction in your wallet",
    });

    try {
      await new Promise((resolve) => setTimeout(resolve, 2000));

      toast.success("Liquidity Removed!", {
        description: `Successfully removed ${removeAmount}% of your position`,
        action: {
          label: "View",
          onClick: () => window.open(getTxUrl("demo-tx-hash"), "_blank"),
        },
      });

      setSelectedPosition(null);
      setRemoveAmount("");
    } catch (error) {
      toast.error("Transaction Failed", {
        description: error instanceof Error ? error.message : "Unknown error occurred",
      });
    } finally {
      setIsRemoving(false);
    }
  };

  if (!account) {
    return (
      <div className="max-w-4xl mx-auto">
        <Card className="glass-card border-white/5">
          <CardContent className="py-16 text-center">
            <Wallet className="w-16 h-16 text-[#8b92a5] mx-auto mb-4" />
            <h2 className="text-xl font-bold text-white mb-2">Connect Your Wallet</h2>
            <p className="text-[#8b92a5] mb-6">
              Connect your wallet to view your liquidity positions
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white">My Positions</h1>
          <p className="text-[#8b92a5] text-sm">
            Manage your liquidity positions and earned fees
          </p>
        </div>
        <Link href="/pools/add">
          <Button className="bg-gradient-to-r from-[#00d4aa] to-[#00a8ff] text-[#0a0e1a] font-semibold">
            <Plus className="w-4 h-4 mr-2" />
            New Position
          </Button>
        </Link>
      </div>

      {/* Portfolio Overview */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="glass-card border-white/5">
          <CardContent className="p-4">
            <div className="text-sm text-[#8b92a5] mb-1">Total Value</div>
            <div className="text-2xl font-bold font-mono text-white">
              {formatUsd(totalValue)}
            </div>
          </CardContent>
        </Card>
        <Card className="glass-card border-white/5">
          <CardContent className="p-4">
            <div className="text-sm text-[#8b92a5] mb-1">Total P&L</div>
            <div className={`text-2xl font-bold font-mono flex items-center gap-2 ${
              totalPnl >= 0 ? 'text-[#00d4aa]' : 'text-[#ff4757]'
            }`}>
              {totalPnl >= 0 ? <TrendingUp className="w-5 h-5" /> : <TrendingDown className="w-5 h-5" />}
              {totalPnl >= 0 ? '+' : ''}{formatUsd(totalPnl)}
            </div>
          </CardContent>
        </Card>
        <Card className="glass-card border-white/5">
          <CardContent className="p-4">
            <div className="text-sm text-[#8b92a5] mb-1">Active Positions</div>
            <div className="text-2xl font-bold font-mono text-white">
              {MOCK_POSITIONS.length}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Positions List */}
      <div className="space-y-4">
        {MOCK_POSITIONS.map((position) => {
          const tokenA = getTokenInfo(position.tokenA);
          const tokenB = getTokenInfo(position.tokenB);
          const pool = MOCK_POOLS.find(p => p.id === position.poolId);
          const isExpanded = expandedPosition === position.id;

          return (
            <Card key={position.id} className="glass-card border-white/5 overflow-hidden">
              <CardContent className="p-0">
                {/* Main Row */}
                <div 
                  className="p-4 cursor-pointer hover:bg-white/[0.02] transition-colors"
                  onClick={() => setExpandedPosition(isExpanded ? null : position.id)}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                      <div className="flex -space-x-2">
                        <div className="w-12 h-12 rounded-full bg-gradient-to-br from-[#1a2035] to-[#0f1629] flex items-center justify-center text-xl border-2 border-[#0a0e1a] z-10">
                          {tokenA.icon}
                        </div>
                        <div className="w-12 h-12 rounded-full bg-gradient-to-br from-[#1a2035] to-[#0f1629] flex items-center justify-center text-xl border-2 border-[#0a0e1a]">
                          {tokenB.icon}
                        </div>
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-bold text-lg text-white">
                            {position.tokenA}/{position.tokenB}
                          </span>
                          <Badge variant="secondary" className="bg-[#00d4aa]/10 text-[#00d4aa] text-xs">
                            NFT
                          </Badge>
                        </div>
                        <div className="flex items-center gap-2 text-sm text-[#8b92a5]">
                          <Clock className="w-3 h-3" />
                          Created {getRelativeTime(position.createdAt)}
                          <span className="mx-1">•</span>
                          <span>{pool?.feeTier ? pool.feeTier / 100 : 0.3}% fee</span>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-6">
                      <div className="text-right hidden sm:block">
                        <div className="text-lg font-mono font-bold text-white">
                          {formatUsd(position.valueUsd)}
                        </div>
                        <div className={`text-sm font-mono flex items-center justify-end gap-1 ${
                          position.pnlPercent >= 0 ? 'text-[#00d4aa]' : 'text-[#ff4757]'
                        }`}>
                          {position.pnlPercent >= 0 ? '+' : ''}{position.pnlPercent.toFixed(2)}%
                        </div>
                      </div>
                      <Button variant="ghost" size="icon">
                        {isExpanded ? (
                          <ChevronUp className="w-5 h-5 text-[#8b92a5]" />
                        ) : (
                          <ChevronDown className="w-5 h-5 text-[#8b92a5]" />
                        )}
                      </Button>
                    </div>
                  </div>
                </div>

                {/* Expanded Details */}
                {isExpanded && (
                  <div className="border-t border-white/5 p-4 bg-[#0a0e1a]/50">
                    <div className="grid md:grid-cols-2 gap-6">
                      {/* Position Details */}
                      <div className="space-y-4">
                        <h4 className="font-semibold text-white flex items-center gap-2">
                          <Coins className="w-4 h-4 text-[#00d4aa]" />
                          Position Details
                        </h4>
                        
                        <div className="space-y-2">
                          <div className="flex justify-between text-sm">
                            <span className="text-[#8b92a5]">{tokenA.symbol} Deposited</span>
                            <span className="font-mono text-white">
                              {formatTokenAmount(position.currentAmountA, tokenA.decimals, 4)}
                            </span>
                          </div>
                          <div className="flex justify-between text-sm">
                            <span className="text-[#8b92a5]">{tokenB.symbol} Deposited</span>
                            <span className="font-mono text-white">
                              {formatTokenAmount(position.currentAmountB, tokenB.decimals, 4)}
                            </span>
                          </div>
                          <div className="flex justify-between text-sm">
                            <span className="text-[#8b92a5]">LP Tokens</span>
                            <span className="font-mono text-white">
                              {formatTokenAmount(position.lpTokens, 6, 4)}
                            </span>
                          </div>
                          <div className="flex justify-between text-sm">
                            <span className="text-[#8b92a5]">Pool Share</span>
                            <span className="font-mono text-[#00d4aa]">
                              {pool ? (Number(position.lpTokens) / Number(pool.totalSupply) * 100).toFixed(4) : 0}%
                            </span>
                          </div>
                        </div>

                        <Separator className="bg-white/5" />

                        <div className="space-y-2">
                          <div className="flex justify-between text-sm">
                            <span className="text-[#8b92a5]">Impermanent Loss</span>
                            <span className={`font-mono ${
                              position.ilPercent <= 0 ? 'text-[#00d4aa]' : 'text-[#ff4757]'
                            }`}>
                              {position.ilPercent.toFixed(2)}%
                            </span>
                          </div>
                        </div>
                      </div>

                      {/* Fees Earned */}
                      <div className="space-y-4">
                        <h4 className="font-semibold text-white flex items-center gap-2">
                          <TrendingUp className="w-4 h-4 text-[#00d4aa]" />
                          Fees Earned
                        </h4>
                        
                        <div className="p-4 rounded-xl bg-[#00d4aa]/5 border border-[#00d4aa]/20">
                          <div className="space-y-2">
                            <div className="flex justify-between">
                              <span className="text-[#8b92a5]">{tokenA.symbol} Earned</span>
                              <span className="font-mono text-[#00d4aa]">
                                +{formatTokenAmount(position.feesEarnedA, tokenA.decimals, 4)}
                              </span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-[#8b92a5]">{tokenB.symbol} Earned</span>
                              <span className="font-mono text-[#00d4aa]">
                                +{formatTokenAmount(position.feesEarnedB, tokenB.decimals, 6)}
                              </span>
                            </div>
                          </div>
                        </div>

                        <div className="p-3 rounded-lg bg-[#1a2035] border border-white/5">
                          <div className="flex items-start gap-2">
                            <Info className="w-4 h-4 text-[#8b92a5] mt-0.5" />
                            <p className="text-xs text-[#8b92a5]">
                              Fees are automatically compounded into your position. 
                              You receive them when you remove liquidity.
                            </p>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="flex gap-3 mt-6 pt-4 border-t border-white/5">
                      <Dialog>
                        <DialogTrigger asChild>
                          <Button 
                            variant="outline" 
                            className="flex-1 border-white/10 text-white hover:bg-white/5"
                            onClick={() => setSelectedPosition(position)}
                          >
                            <Minus className="w-4 h-4 mr-2" />
                            Remove Liquidity
                          </Button>
                        </DialogTrigger>
                        <DialogContent className="glass-card border-white/10">
                          <DialogHeader>
                            <DialogTitle className="text-white">Remove Liquidity</DialogTitle>
                            <DialogDescription className="text-[#8b92a5]">
                              Choose how much liquidity you want to remove from your position.
                            </DialogDescription>
                          </DialogHeader>
                          
                          <div className="space-y-4 py-4">
                            <div className="flex items-center gap-2">
                              <span className="text-xl">{tokenA.icon}</span>
                              <span className="text-xl">{tokenB.icon}</span>
                              <span className="font-semibold text-white">
                                {position.tokenA}/{position.tokenB}
                              </span>
                            </div>

                            <div>
                              <label className="text-sm text-[#8b92a5] mb-2 block">
                                Amount to Remove
                              </label>
                              <div className="flex gap-2">
                                {[25, 50, 75, 100].map((pct) => (
                                  <Button
                                    key={pct}
                                    size="sm"
                                    variant={removeAmount === String(pct) ? "default" : "outline"}
                                    onClick={() => setRemoveAmount(String(pct))}
                                    className={removeAmount === String(pct)
                                      ? "bg-[#00d4aa] text-[#0a0e1a]"
                                      : "border-white/10 text-white"
                                    }
                                  >
                                    {pct}%
                                  </Button>
                                ))}
                              </div>
                            </div>

                            {removeAmount && (
                              <div className="p-4 rounded-xl bg-[#0a0e1a] border border-white/5 space-y-2">
                                <div className="flex justify-between text-sm">
                                  <span className="text-[#8b92a5]">You will receive</span>
                                </div>
                                <div className="flex justify-between">
                                  <span className="text-white">{tokenA.symbol}</span>
                                  <span className="font-mono text-white">
                                    {formatTokenAmount(
                                      (position.currentAmountA * BigInt(removeAmount)) / 100n,
                                      tokenA.decimals,
                                      4
                                    )}
                                  </span>
                                </div>
                                <div className="flex justify-between">
                                  <span className="text-white">{tokenB.symbol}</span>
                                  <span className="font-mono text-white">
                                    {formatTokenAmount(
                                      (position.currentAmountB * BigInt(removeAmount)) / 100n,
                                      tokenB.decimals,
                                      6
                                    )}
                                  </span>
                                </div>
                              </div>
                            )}

                            {removeAmount === "100" && (
                              <div className="p-3 rounded-lg bg-[#f59e0b]/10 border border-[#f59e0b]/20">
                                <div className="flex items-start gap-2">
                                  <AlertCircle className="w-4 h-4 text-[#f59e0b] mt-0.5" />
                                  <p className="text-sm text-[#f59e0b]">
                                    Removing 100% will burn your LP Position NFT.
                                  </p>
                                </div>
                              </div>
                            )}
                          </div>

                          <DialogFooter>
                            <Button
                              onClick={handleRemoveLiquidity}
                              disabled={!removeAmount || isRemoving}
                              className="w-full bg-gradient-to-r from-[#00d4aa] to-[#00a8ff] text-[#0a0e1a] font-semibold"
                            >
                              {isRemoving ? (
                                <>
                                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                                  Removing...
                                </>
                              ) : (
                                "Confirm Remove"
                              )}
                            </Button>
                          </DialogFooter>
                        </DialogContent>
                      </Dialog>

                      <Link href="/pools/add" className="flex-1">
                        <Button className="w-full bg-gradient-to-r from-[#00d4aa] to-[#00a8ff] text-[#0a0e1a] font-semibold">
                          <Plus className="w-4 h-4 mr-2" />
                          Add More
                        </Button>
                      </Link>

                      <Button
                        variant="ghost"
                        size="icon"
                        asChild
                      >
                        <a
                          href={getObjectUrl(position.id)}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-[#8b92a5] hover:text-white"
                        >
                          <ExternalLink className="w-4 h-4" />
                        </a>
                      </Button>
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          );
        })}
      </div>

      {MOCK_POSITIONS.length === 0 && (
        <Card className="glass-card border-white/5">
          <CardContent className="py-16 text-center">
            <Wallet className="w-16 h-16 text-[#8b92a5] mx-auto mb-4" />
            <h2 className="text-xl font-bold text-white mb-2">No Positions Found</h2>
            <p className="text-[#8b92a5] mb-6">
              You don&apos;t have any liquidity positions yet
            </p>
            <Link href="/pools/add">
              <Button className="bg-gradient-to-r from-[#00d4aa] to-[#00a8ff] text-[#0a0e1a] font-semibold">
                <Plus className="w-4 h-4 mr-2" />
                Create Position
              </Button>
            </Link>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

