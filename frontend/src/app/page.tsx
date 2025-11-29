"use client";

import { 
  TrendingUp, 
  TrendingDown, 
  Activity, 
  Droplets, 
  ArrowRightLeft,
  Users,
  DollarSign,
  BarChart3,
  ArrowUpRight,
  Clock,
  Zap
} from "lucide-react";
import Link from "next/link";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  MOCK_POOLS,
  MOCK_TRANSACTIONS,
  PROTOCOL_STATS,
  formatUsd,
  formatPercent,
  getRelativeTime,
  getTokenInfo,
  shortenAddress,
} from "@/lib/mock-data";

export default function DashboardPage() {
  return (
    <div className="space-y-8">
      {/* Hero Section */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-[#0f1629] via-[#1a2035] to-[#0f1629] p-8 border border-white/5">
        <div className="absolute inset-0 bg-[radial-gradient(#ffffff10_1px,transparent_1px)] [background-size:20px_20px] opacity-30" />
        <div className="absolute top-0 right-0 w-96 h-96 bg-[#00d4aa]/10 rounded-full blur-3xl" />
        <div className="absolute bottom-0 left-0 w-64 h-64 bg-[#00a8ff]/10 rounded-full blur-3xl" />
        
        <div className="relative z-10">
          <div className="flex items-center gap-2 mb-2">
            <div className="w-2 h-2 rounded-full bg-[#00d4aa] pulse-dot" />
            <span className="text-sm text-[#00d4aa] font-medium">Live on Sui Testnet</span>
          </div>
          <h1 className="text-4xl font-bold text-white mb-3">
            Trade & Earn on <span className="gradient-text">SuiSwap</span>
          </h1>
          <p className="text-[#8b92a5] text-lg max-w-2xl mb-6">
            The most efficient AMM on Sui Network with NFT-based LP positions, 
            optimized stable swaps, and real-time fee distribution.
          </p>
          <div className="flex gap-4">
            <Link href="/swap">
              <Button className="bg-gradient-to-r from-[#00d4aa] to-[#00a8ff] text-[#0a0e1a] font-semibold px-6 py-2 rounded-lg hover:opacity-90 transition-opacity">
                <ArrowRightLeft className="w-4 h-4 mr-2" />
                Start Trading
              </Button>
            </Link>
            <Link href="/pools">
              <Button variant="outline" className="border-white/10 text-white hover:bg-white/5">
                <Droplets className="w-4 h-4 mr-2" />
                Add Liquidity
              </Button>
            </Link>
          </div>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatCard
          icon={<DollarSign className="w-5 h-5" />}
          label="Total Value Locked"
          value={formatUsd(PROTOCOL_STATS.totalValueLocked)}
          change={8.34}
        />
        <StatCard
          icon={<BarChart3 className="w-5 h-5" />}
          label="24h Volume"
          value={formatUsd(PROTOCOL_STATS.totalVolume24h)}
          change={12.56}
        />
        <StatCard
          icon={<Activity className="w-5 h-5" />}
          label="Total Swaps"
          value={PROTOCOL_STATS.totalSwaps.toLocaleString()}
          change={5.23}
        />
        <StatCard
          icon={<Users className="w-5 h-5" />}
          label="Liquidity Providers"
          value={PROTOCOL_STATS.totalLiquidityProviders.toString()}
          change={2.1}
        />
      </div>

      {/* Main Content Grid */}
      <div className="grid lg:grid-cols-3 gap-6">
        {/* Featured Pools */}
        <div className="lg:col-span-2">
          <Card className="glass-card border-white/5">
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle className="text-lg font-semibold text-white flex items-center gap-2">
                <Droplets className="w-5 h-5 text-[#00d4aa]" />
                Top Pools
              </CardTitle>
              <Link href="/pools">
                <Button variant="ghost" size="sm" className="text-[#8b92a5] hover:text-white">
                  View All
                  <ArrowUpRight className="w-4 h-4 ml-1" />
                </Button>
              </Link>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {MOCK_POOLS.slice(0, 4).map((pool) => {
                  const tokenA = getTokenInfo(pool.tokenA);
                  const tokenB = getTokenInfo(pool.tokenB);
                  
                  return (
                    <div
                      key={pool.id}
                      className="flex items-center justify-between p-4 rounded-xl bg-[#0a0e1a]/50 hover:bg-[#1a2035]/50 transition-colors border border-white/5"
                    >
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
                          <div className="text-sm text-[#8b92a5]">
                            {pool.feeTier / 100}% fee
                          </div>
                        </div>
                      </div>
                      
                      <div className="text-right">
                        <div className="font-mono font-semibold text-white">
                          {formatUsd(pool.tvlUsd)}
                        </div>
                        <div className="text-sm text-[#8b92a5]">TVL</div>
                      </div>
                      
                      <div className="text-right hidden sm:block">
                        <div className="font-mono font-semibold text-white">
                          {formatUsd(pool.volume24h)}
                        </div>
                        <div className="text-sm text-[#8b92a5]">24h Vol</div>
                      </div>
                      
                      <div className="text-right hidden md:block">
                        <div className={`font-mono font-semibold flex items-center justify-end gap-1 ${
                          pool.apr >= 15 ? 'text-[#00d4aa]' : 'text-white'
                        }`}>
                          {pool.apr >= 15 && <Zap className="w-3 h-3" />}
                          {pool.apr.toFixed(2)}%
                        </div>
                        <div className="text-sm text-[#8b92a5]">APR</div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Recent Activity */}
        <div>
          <Card className="glass-card border-white/5">
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle className="text-lg font-semibold text-white flex items-center gap-2">
                <Activity className="w-5 h-5 text-[#00d4aa]" />
                Recent Activity
              </CardTitle>
              <div className="flex items-center gap-1">
                <div className="w-2 h-2 rounded-full bg-[#00d4aa] pulse-dot" />
                <span className="text-xs text-[#8b92a5]">Live</span>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-3 max-h-[400px] overflow-y-auto pr-2">
                {MOCK_TRANSACTIONS.slice(0, 12).map((tx) => {
                  const tokenA = getTokenInfo(tx.tokenA);
                  const tokenB = getTokenInfo(tx.tokenB);
                  
                  return (
                    <div
                      key={tx.id}
                      className="flex items-center gap-3 p-3 rounded-lg bg-[#0a0e1a]/50 border border-white/5"
                    >
                      <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${
                        tx.type === "swap" 
                          ? "bg-[#00a8ff]/10 text-[#00a8ff]"
                          : tx.type === "add_liquidity"
                          ? "bg-[#00d4aa]/10 text-[#00d4aa]"
                          : "bg-[#f59e0b]/10 text-[#f59e0b]"
                      }`}>
                        {tx.type === "swap" ? (
                          <ArrowRightLeft className="w-4 h-4" />
                        ) : tx.type === "add_liquidity" ? (
                          <Droplets className="w-4 h-4" />
                        ) : (
                          <TrendingDown className="w-4 h-4" />
                        )}
                      </div>
                      
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-medium text-white capitalize">
                            {tx.type.replace("_", " ")}
                          </span>
                          <span className="text-xs text-[#8b92a5]">
                            {shortenAddress(tx.user)}
                          </span>
                        </div>
                        <div className="text-xs text-[#8b92a5] flex items-center gap-1">
                          <span>{tokenA.icon} {tx.amountA}</span>
                          <span>→</span>
                          <span>{tokenB.icon} {tx.amountB}</span>
                        </div>
                      </div>
                      
                      <div className="text-right">
                        <div className="text-xs font-mono text-white">
                          {formatUsd(tx.valueUsd)}
                        </div>
                        <div className="text-xs text-[#8b92a5] flex items-center gap-1 justify-end">
                          <Clock className="w-3 h-3" />
                          {getRelativeTime(tx.timestamp)}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <QuickActionCard
          icon={<ArrowRightLeft className="w-6 h-6" />}
          title="Swap Tokens"
          description="Trade any token pair with minimal slippage and competitive fees"
          href="/swap"
          color="#00a8ff"
        />
        <QuickActionCard
          icon={<Droplets className="w-6 h-6" />}
          title="Add Liquidity"
          description="Earn trading fees by providing liquidity to pools"
          href="/pools"
          color="#00d4aa"
        />
        <QuickActionCard
          icon={<DollarSign className="w-6 h-6" />}
          title="Get Test Tokens"
          description="Mint demo tokens to start testing the protocol"
          href="/faucet"
          color="#a855f7"
        />
      </div>
    </div>
  );
}

function StatCard({ 
  icon, 
  label, 
  value, 
  change 
}: { 
  icon: React.ReactNode; 
  label: string; 
  value: string; 
  change: number;
}) {
  const isPositive = change >= 0;
  
  return (
    <Card className="glass-card border-white/5">
      <CardContent className="p-4">
        <div className="flex items-center justify-between mb-2">
          <div className="w-10 h-10 rounded-lg bg-[#00d4aa]/10 flex items-center justify-center text-[#00d4aa]">
            {icon}
          </div>
          <div className={`flex items-center gap-1 text-sm ${
            isPositive ? 'text-[#00d4aa]' : 'text-[#ff4757]'
          }`}>
            {isPositive ? (
              <TrendingUp className="w-3 h-3" />
            ) : (
              <TrendingDown className="w-3 h-3" />
            )}
            <span className="font-mono">{formatPercent(change)}</span>
          </div>
        </div>
        <div className="font-mono text-2xl font-bold text-white mb-1">
          {value}
        </div>
        <div className="text-sm text-[#8b92a5]">{label}</div>
      </CardContent>
    </Card>
  );
}

function QuickActionCard({
  icon,
  title,
  description,
  href,
  color,
}: {
  icon: React.ReactNode;
  title: string;
  description: string;
  href: string;
  color: string;
}) {
  return (
    <Link href={href}>
      <Card className="glass-card border-white/5 hover:border-white/10 transition-all group cursor-pointer h-full">
        <CardContent className="p-6">
          <div 
            className="w-12 h-12 rounded-xl flex items-center justify-center mb-4 transition-transform group-hover:scale-110"
            style={{ backgroundColor: `${color}15`, color }}
          >
            {icon}
          </div>
          <h3 className="text-lg font-semibold text-white mb-2 group-hover:text-[#00d4aa] transition-colors">
            {title}
          </h3>
          <p className="text-sm text-[#8b92a5]">{description}</p>
        </CardContent>
      </Card>
    </Link>
  );
}
