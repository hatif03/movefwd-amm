"use client";

import { useState } from "react";
import Link from "next/link";
import { 
  Droplets, 
  Plus, 
  Search, 
  TrendingUp, 
  Zap,
  ExternalLink,
  Info,
  ChevronDown,
  BarChart3
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { DEMO_TOKENS, TokenSymbol, getObjectUrl } from "@/lib/sui/constants";
import { 
  MOCK_POOLS, 
  PROTOCOL_STATS, 
  formatUsd, 
  formatNumber, 
  formatPercent,
  getTokenInfo 
} from "@/lib/mock-data";
import { formatTokenAmount } from "@/lib/sui/transactions";

type SortOption = "tvl" | "volume" | "apr" | "fees";

export default function PoolsPage() {
  const [searchQuery, setSearchQuery] = useState("");
  const [sortBy, setSortBy] = useState<SortOption>("tvl");
  const [showAll, setShowAll] = useState(false);

  // Filter and sort pools
  const filteredPools = MOCK_POOLS
    .filter((pool) => {
      const query = searchQuery.toLowerCase();
      return (
        pool.tokenA.toLowerCase().includes(query) ||
        pool.tokenB.toLowerCase().includes(query) ||
        `${pool.tokenA}/${pool.tokenB}`.toLowerCase().includes(query)
      );
    })
    .sort((a, b) => {
      switch (sortBy) {
        case "tvl":
          return b.tvlUsd - a.tvlUsd;
        case "volume":
          return b.volume24h - a.volume24h;
        case "apr":
          return b.apr - a.apr;
        case "fees":
          return b.fees24h - a.fees24h;
        default:
          return 0;
      }
    });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white">Liquidity Pools</h1>
          <p className="text-[#8b92a5] text-sm">
            Provide liquidity to earn trading fees
          </p>
        </div>
        <Link href="/pools/add">
          <Button className="bg-gradient-to-r from-[#00d4aa] to-[#00a8ff] text-[#0a0e1a] font-semibold">
            <Plus className="w-4 h-4 mr-2" />
            New Position
          </Button>
        </Link>
      </div>

      {/* Stats Overview */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card className="glass-card border-white/5">
          <CardContent className="p-4">
            <div className="text-sm text-[#8b92a5] mb-1">Total Value Locked</div>
            <div className="text-xl font-bold font-mono text-white">
              {formatUsd(PROTOCOL_STATS.totalValueLocked)}
            </div>
          </CardContent>
        </Card>
        <Card className="glass-card border-white/5">
          <CardContent className="p-4">
            <div className="text-sm text-[#8b92a5] mb-1">24h Volume</div>
            <div className="text-xl font-bold font-mono text-white">
              {formatUsd(PROTOCOL_STATS.totalVolume24h)}
            </div>
          </CardContent>
        </Card>
        <Card className="glass-card border-white/5">
          <CardContent className="p-4">
            <div className="text-sm text-[#8b92a5] mb-1">Total Pools</div>
            <div className="text-xl font-bold font-mono text-white">
              {PROTOCOL_STATS.totalPools}
            </div>
          </CardContent>
        </Card>
        <Card className="glass-card border-white/5">
          <CardContent className="p-4">
            <div className="text-sm text-[#8b92a5] mb-1">Avg. APR</div>
            <div className="text-xl font-bold font-mono text-[#00d4aa]">
              {PROTOCOL_STATS.averageAPR.toFixed(2)}%
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <Card className="glass-card border-white/5">
        <CardContent className="p-4">
          <div className="flex flex-col sm:flex-row items-center gap-4">
            <div className="relative flex-1 w-full">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#8b92a5]" />
              <Input
                placeholder="Search pools by token..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10 bg-[#0a0e1a] border-white/10 text-white placeholder:text-[#4a5068]"
              />
            </div>
            <Select value={sortBy} onValueChange={(v) => setSortBy(v as SortOption)}>
              <SelectTrigger className="w-[180px] bg-[#0a0e1a] border-white/10 text-white">
                <SelectValue placeholder="Sort by" />
              </SelectTrigger>
              <SelectContent className="bg-[#0f1629] border-white/10">
                <SelectItem value="tvl" className="text-white">Sort by TVL</SelectItem>
                <SelectItem value="volume" className="text-white">Sort by Volume</SelectItem>
                <SelectItem value="apr" className="text-white">Sort by APR</SelectItem>
                <SelectItem value="fees" className="text-white">Sort by Fees</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Pools List */}
      <Card className="glass-card border-white/5 overflow-hidden">
        <CardContent className="p-0">
          {/* Table Header */}
          <div className="hidden md:grid grid-cols-12 gap-4 p-4 border-b border-white/5 text-sm text-[#8b92a5]">
            <div className="col-span-3">Pool</div>
            <div className="col-span-2 text-right">TVL</div>
            <div className="col-span-2 text-right">24h Volume</div>
            <div className="col-span-2 text-right">24h Fees</div>
            <div className="col-span-2 text-right">APR</div>
            <div className="col-span-1"></div>
          </div>

          {/* Pool Rows */}
          <div className="divide-y divide-white/5">
            {filteredPools.map((pool) => {
              const tokenA = getTokenInfo(pool.tokenA);
              const tokenB = getTokenInfo(pool.tokenB);

              return (
                <div
                  key={pool.id}
                  className="p-4 hover:bg-white/[0.02] transition-colors"
                >
                  {/* Desktop View */}
                  <div className="hidden md:grid grid-cols-12 gap-4 items-center">
                    <div className="col-span-3 flex items-center gap-3">
                      <div className="flex -space-x-2">
                        <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#1a2035] to-[#0f1629] flex items-center justify-center text-lg border-2 border-[#0a0e1a] z-10">
                          {tokenA.icon}
                        </div>
                        <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#1a2035] to-[#0f1629] flex items-center justify-center text-lg border-2 border-[#0a0e1a]">
                          {tokenB.icon}
                        </div>
                      </div>
                      <div>
                        <div className="font-semibold text-white">
                          {pool.tokenA}/{pool.tokenB}
                        </div>
                        <div className="flex items-center gap-2">
                          <Badge variant="secondary" className="text-xs bg-[#1a2035] text-[#8b92a5]">
                            {pool.feeTier / 100}% fee
                          </Badge>
                          {pool.tokenA === "USDC" && pool.tokenB === "USDT" && (
                            <Badge variant="secondary" className="text-xs bg-[#00d4aa]/10 text-[#00d4aa]">
                              Stable
                            </Badge>
                          )}
                        </div>
                      </div>
                    </div>
                    <div className="col-span-2 text-right font-mono text-white">
                      {formatUsd(pool.tvlUsd)}
                    </div>
                    <div className="col-span-2 text-right font-mono text-white">
                      {formatUsd(pool.volume24h)}
                    </div>
                    <div className="col-span-2 text-right font-mono text-white">
                      {formatUsd(pool.fees24h)}
                    </div>
                    <div className="col-span-2 text-right">
                      <div className={`font-mono font-semibold flex items-center justify-end gap-1 ${
                        pool.apr >= 15 ? 'text-[#00d4aa]' : 'text-white'
                      }`}>
                        {pool.apr >= 15 && <Zap className="w-3 h-3" />}
                        {pool.apr.toFixed(2)}%
                      </div>
                    </div>
                    <div className="col-span-1 flex justify-end">
                      <Link href={`/pools/add?pool=${pool.id}`}>
                        <Button size="sm" variant="outline" className="border-white/10 text-white hover:bg-white/5">
                          <Plus className="w-4 h-4" />
                        </Button>
                      </Link>
                    </div>
                  </div>

                  {/* Mobile View */}
                  <div className="md:hidden space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className="flex -space-x-2">
                          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-[#1a2035] to-[#0f1629] flex items-center justify-center text-lg border-2 border-[#0a0e1a] z-10">
                            {tokenA.icon}
                          </div>
                          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-[#1a2035] to-[#0f1629] flex items-center justify-center text-lg border-2 border-[#0a0e1a]">
                            {tokenB.icon}
                          </div>
                        </div>
                        <div>
                          <div className="font-semibold text-white">
                            {pool.tokenA}/{pool.tokenB}
                          </div>
                          <Badge variant="secondary" className="text-xs bg-[#1a2035] text-[#8b92a5]">
                            {pool.feeTier / 100}% fee
                          </Badge>
                        </div>
                      </div>
                      <div className={`font-mono font-semibold ${
                        pool.apr >= 15 ? 'text-[#00d4aa]' : 'text-white'
                      }`}>
                        {pool.apr.toFixed(2)}% APR
                      </div>
                    </div>
                    <div className="grid grid-cols-3 gap-2 text-sm">
                      <div>
                        <div className="text-[#8b92a5]">TVL</div>
                        <div className="font-mono text-white">{formatUsd(pool.tvlUsd)}</div>
                      </div>
                      <div>
                        <div className="text-[#8b92a5]">24h Vol</div>
                        <div className="font-mono text-white">{formatUsd(pool.volume24h)}</div>
                      </div>
                      <div>
                        <div className="text-[#8b92a5]">24h Fees</div>
                        <div className="font-mono text-white">{formatUsd(pool.fees24h)}</div>
                      </div>
                    </div>
                    <Link href={`/pools/add?pool=${pool.id}`} className="block">
                      <Button className="w-full" variant="outline" size="sm">
                        <Plus className="w-4 h-4 mr-2" />
                        Add Liquidity
                      </Button>
                    </Link>
                  </div>
                </div>
              );
            })}
          </div>

          {filteredPools.length === 0 && (
            <div className="p-8 text-center">
              <Droplets className="w-12 h-12 text-[#8b92a5] mx-auto mb-3" />
              <h3 className="text-lg font-semibold text-white mb-1">No pools found</h3>
              <p className="text-[#8b92a5] text-sm">
                Try adjusting your search or create a new pool
              </p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Info Section */}
      <Card className="glass-card border-white/5">
        <CardContent className="p-6">
          <div className="flex items-start gap-4">
            <div className="w-10 h-10 rounded-lg bg-[#00d4aa]/10 flex items-center justify-center text-[#00d4aa]">
              <Info className="w-5 h-5" />
            </div>
            <div>
              <h3 className="font-semibold text-white mb-2">How Liquidity Providing Works</h3>
              <p className="text-sm text-[#8b92a5] mb-4">
                When you add liquidity, you receive an NFT representing your position. 
                This NFT tracks your share of the pool, earned fees, and allows you to 
                remove liquidity at any time. You earn a portion of trading fees proportional 
                to your share of the pool.
              </p>
              <div className="grid sm:grid-cols-3 gap-4 text-sm">
                <div className="p-3 rounded-lg bg-[#0a0e1a]">
                  <div className="font-semibold text-white mb-1">Earn Fees</div>
                  <div className="text-[#8b92a5]">
                    Get a share of all swap fees based on your liquidity
                  </div>
                </div>
                <div className="p-3 rounded-lg bg-[#0a0e1a]">
                  <div className="font-semibold text-white mb-1">NFT Positions</div>
                  <div className="text-[#8b92a5]">
                    Your position is an NFT that can be transferred or sold
                  </div>
                </div>
                <div className="p-3 rounded-lg bg-[#0a0e1a]">
                  <div className="font-semibold text-white mb-1">Flexible Exit</div>
                  <div className="text-[#8b92a5]">
                    Remove liquidity anytime with no lock-up periods
                  </div>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

