"use client";

import { useState } from "react";
import { 
  Coins, 
  Droplet, 
  Check, 
  Loader2, 
  Wallet,
  ExternalLink,
  Info,
  Sparkles,
  RefreshCw
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { useCurrentAccount, useSignAndExecuteTransaction, useSuiClient } from "@mysten/dapp-kit";
import { Transaction } from "@mysten/sui/transactions";
import { toast } from "sonner";
import { DEMO_TOKENS, TokenSymbol, getTxUrl, PACKAGE_ID, MODULES } from "@/lib/sui/constants";
import { formatTokenAmount } from "@/lib/sui/transactions";
import { useTokenBalances, useTreasuryCaps } from "@/lib/sui/queries";

// Default mint amounts
const MINT_AMOUNTS: Record<TokenSymbol, bigint> = {
  USDC: 100000_000000n,        // 100,000 USDC
  USDT: 100000_000000n,        // 100,000 USDT
  ETH: 10_000000000000000000n, // 10 ETH
  BTC: 1_00000000n,            // 1 BTC
  WSUI: 10000_000000000n,      // 10,000 WSUI
};

export default function FaucetPage() {
  const account = useCurrentAccount();
  const client = useSuiClient();
  const { mutate: signAndExecute, isPending } = useSignAndExecuteTransaction();
  const { data: balances, refetch: refetchBalances } = useTokenBalances();
  const { data: treasuryCaps } = useTreasuryCaps();
  
  const [mintingToken, setMintingToken] = useState<TokenSymbol | null>(null);
  const [mintedTokens, setMintedTokens] = useState<Set<TokenSymbol>>(new Set());

  // Check if user has any treasury caps (only contract deployer has these)
  const hasTreasuryCaps = treasuryCaps && Object.keys(treasuryCaps).length > 0;

  const handleMint = async (symbol: TokenSymbol) => {
    if (!account) {
      toast.error("Wallet not connected");
      return;
    }

    setMintingToken(symbol);
    
    // Check if user has the treasury cap for this token
    const treasuryCapId = treasuryCaps?.[symbol];
    
    if (treasuryCapId) {
      // Real minting with treasury cap
      toast.info(`Minting ${symbol}`, {
        description: "Please confirm the transaction in your wallet",
      });

      try {
        const tx = new Transaction();
        
        const functionName = `mint_${symbol.toLowerCase()}`;
        
        tx.moveCall({
          target: `${PACKAGE_ID}::${MODULES.DEMO_TOKENS}::${functionName}`,
          arguments: [
            tx.object(treasuryCapId),
            tx.pure.u64(MINT_AMOUNTS[symbol]),
            tx.pure.address(account.address),
          ],
        });
        
        signAndExecute(
          { transaction: tx },
          {
            onSuccess: (result) => {
              setMintedTokens((prev) => new Set([...prev, symbol]));
              toast.success(`Minted ${symbol}!`, {
                description: `Successfully minted ${formatTokenAmount(MINT_AMOUNTS[symbol], DEMO_TOKENS[symbol].decimals, 2)} ${symbol}`,
                action: {
                  label: "View",
                  onClick: () => window.open(getTxUrl(result.digest), "_blank"),
                },
              });
              refetchBalances();
              setMintingToken(null);
            },
            onError: (error) => {
              toast.error("Mint Failed", {
                description: error.message || "Transaction failed",
              });
              setMintingToken(null);
            },
          }
        );
        return;
      } catch (error) {
        toast.error("Mint Failed", {
          description: error instanceof Error ? error.message : "Unknown error occurred",
        });
        setMintingToken(null);
        return;
      }
    }

    // Simulation mode for users without treasury caps
    toast.info(`Simulating ${symbol} mint`, {
      description: "Demo mode - Treasury caps owned by contract deployer",
    });

    try {
      await new Promise((resolve) => setTimeout(resolve, 1500));

      setMintedTokens((prev) => new Set([...prev, symbol]));
      
      toast.success(`${symbol} Mint Simulated`, {
        description: `Demo: Would receive ${formatTokenAmount(MINT_AMOUNTS[symbol], DEMO_TOKENS[symbol].decimals, 2)} ${symbol}. Use CLI to mint real tokens.`,
      });

      refetchBalances();
    } catch (error) {
      toast.error("Mint Failed", {
        description: error instanceof Error ? error.message : "Unknown error occurred",
      });
    } finally {
      setMintingToken(null);
    }
  };

  const handleMintAll = async () => {
    if (!account) {
      toast.error("Wallet not connected");
      return;
    }

    setMintingToken("USDC"); // Use as loading indicator

    // Check if we have all treasury caps
    const allSymbols = Object.keys(DEMO_TOKENS) as TokenSymbol[];
    const hasAllCaps = allSymbols.every(s => treasuryCaps?.[s]);

    if (hasAllCaps && treasuryCaps) {
      // Real minting with all treasury caps
      toast.info("Minting All Tokens", {
        description: "Please confirm the transaction in your wallet",
      });

      try {
        const tx = new Transaction();
        
        tx.moveCall({
          target: `${PACKAGE_ID}::${MODULES.DEMO_TOKENS}::mint_demo_bundle`,
          arguments: [
            tx.object(treasuryCaps.USDC!),
            tx.object(treasuryCaps.USDT!),
            tx.object(treasuryCaps.ETH!),
            tx.object(treasuryCaps.BTC!),
            tx.object(treasuryCaps.WSUI!),
            tx.pure.address(account.address),
          ],
        });
        
        signAndExecute(
          { transaction: tx },
          {
            onSuccess: (result) => {
              const allTokens = new Set(allSymbols);
              setMintedTokens(allTokens);
              toast.success("Minted All Tokens!", {
                description: "You received USDC, USDT, ETH, BTC, and WSUI",
                action: {
                  label: "View",
                  onClick: () => window.open(getTxUrl(result.digest), "_blank"),
                },
              });
              refetchBalances();
              setMintingToken(null);
            },
            onError: (error) => {
              toast.error("Mint Failed", {
                description: error.message || "Transaction failed",
              });
              setMintingToken(null);
            },
          }
        );
        return;
      } catch (error) {
        toast.error("Mint Failed", {
          description: error instanceof Error ? error.message : "Unknown error occurred",
        });
        setMintingToken(null);
        return;
      }
    }

    // Simulation mode
    toast.info("Simulating Bundle Mint", {
      description: "Demo mode - Treasury caps owned by contract deployer",
    });

    try {
      await new Promise((resolve) => setTimeout(resolve, 2500));

      const allTokens = new Set(allSymbols);
      setMintedTokens(allTokens);

      toast.success("Mint Simulated!", {
        description: "Demo: Would receive all tokens. Use CLI to mint real tokens.",
      });

      refetchBalances();
    } catch (error) {
      toast.error("Mint Failed", {
        description: error instanceof Error ? error.message : "Unknown error occurred",
      });
    } finally {
      setMintingToken(null);
    }
  };

  if (!account) {
    return (
      <div className="max-w-2xl mx-auto">
        <Card className="glass-card border-white/5">
          <CardContent className="py-16 text-center">
            <Wallet className="w-16 h-16 text-[#8b92a5] mx-auto mb-4" />
            <h2 className="text-xl font-bold text-white mb-2">Connect Your Wallet</h2>
            <p className="text-[#8b92a5] mb-6">
              Connect your wallet to access the demo token faucet
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      {/* Header */}
      <div className="text-center">
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-[#00d4aa] to-[#00a8ff] mb-4">
          <Droplet className="w-8 h-8 text-[#0a0e1a]" />
        </div>
        <h1 className="text-2xl font-bold text-white mb-2">Demo Token Faucet</h1>
        <p className="text-[#8b92a5]">
          Get free test tokens to explore SuiSwap on testnet
        </p>
      </div>

      {/* Treasury Cap Notice */}
      {!hasTreasuryCaps && (
        <Card className="glass-card border-[#f59e0b]/30 bg-[#f59e0b]/5">
          <CardContent className="p-4">
            <div className="flex items-start gap-3">
              <Info className="w-5 h-5 text-[#f59e0b] mt-0.5 shrink-0" />
              <div>
                <h4 className="font-semibold text-[#f59e0b] mb-1">Demo Mode</h4>
                <p className="text-sm text-[#8b92a5] mb-2">
                  Treasury caps are owned by the contract deployer. To mint real tokens, use the CLI:
                </p>
                <code className="block p-2 rounded bg-[#0a0e1a] text-xs text-[#00d4aa] font-mono overflow-x-auto">
                  sui client call --package {PACKAGE_ID.slice(0, 10)}... --module demo_tokens --function mint_usdc --args &lt;TREASURY_CAP&gt; &lt;AMOUNT&gt; &lt;RECIPIENT&gt;
                </code>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Mint All Button */}
      <Card className="glass-card border-white/5 overflow-hidden">
        <div className="p-6 bg-gradient-to-r from-[#00d4aa]/10 to-[#00a8ff]/10">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-[#00d4aa] to-[#00a8ff] flex items-center justify-center">
                <Sparkles className="w-6 h-6 text-[#0a0e1a]" />
              </div>
              <div>
                <h3 className="font-bold text-white text-lg">Mint All Tokens</h3>
                <p className="text-sm text-[#8b92a5]">
                  Get 100K USDC, 100K USDT, 10 ETH, 1 BTC, 10K WSUI
                </p>
              </div>
            </div>
            <Button
              onClick={handleMintAll}
              disabled={mintingToken !== null}
              className="bg-gradient-to-r from-[#00d4aa] to-[#00a8ff] text-[#0a0e1a] font-semibold px-6"
            >
              {mintingToken !== null ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <>
                  <Coins className="w-4 h-4 mr-2" />
                  Mint Bundle
                </>
              )}
            </Button>
          </div>
        </div>
      </Card>

      {/* Individual Token Cards */}
      <Card className="glass-card border-white/5">
        <CardHeader>
          <CardTitle className="text-lg font-semibold text-white flex items-center justify-between">
            <span className="flex items-center gap-2">
              <Coins className="w-5 h-5 text-[#00d4aa]" />
              Available Tokens
            </span>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => refetchBalances()}
              className="text-[#8b92a5] hover:text-white"
            >
              <RefreshCw className="w-4 h-4 mr-1" />
              Refresh
            </Button>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {(Object.entries(DEMO_TOKENS) as [TokenSymbol, typeof DEMO_TOKENS[TokenSymbol]][]).map(
            ([symbol, token]) => {
              const balance = balances?.[symbol]?.balance || 0n;
              const isMinting = mintingToken === symbol;
              const wasMinted = mintedTokens.has(symbol);

              return (
                <div
                  key={symbol}
                  className="flex items-center justify-between p-4 rounded-xl bg-[#0a0e1a] border border-white/5 hover:border-white/10 transition-colors"
                >
                  <div className="flex items-center gap-4">
                    <div 
                      className="w-12 h-12 rounded-full flex items-center justify-center text-2xl"
                      style={{ backgroundColor: `${token.color}15` }}
                    >
                      {token.icon}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-white">{token.symbol}</span>
                        {wasMinted && (
                          <Badge variant="secondary" className="bg-[#00d4aa]/10 text-[#00d4aa] text-xs">
                            <Check className="w-3 h-3 mr-1" />
                            Minted
                          </Badge>
                        )}
                      </div>
                      <div className="text-sm text-[#8b92a5]">{token.name}</div>
                    </div>
                  </div>

                  <div className="flex items-center gap-4">
                    <div className="text-right">
                      <div className="font-mono text-sm text-[#8b92a5]">Balance</div>
                      <div className="font-mono font-semibold text-white">
                        {formatTokenAmount(balance, token.decimals, 2)}
                      </div>
                    </div>
                    <Button
                      onClick={() => handleMint(symbol)}
                      disabled={mintingToken !== null}
                      variant="outline"
                      className="border-white/10 text-white hover:bg-white/5 min-w-[100px]"
                    >
                      {isMinting ? (
                        <Loader2 className="w-4 h-4 animate-spin" />
                      ) : (
                        <>
                          <Droplet className="w-4 h-4 mr-2" />
                          Mint
                        </>
                      )}
                    </Button>
                  </div>
                </div>
              );
            }
          )}
        </CardContent>
      </Card>

      {/* Mint Amounts Info */}
      <Card className="glass-card border-white/5">
        <CardContent className="p-4">
          <div className="flex items-start gap-3">
            <Info className="w-5 h-5 text-[#8b92a5] mt-0.5" />
            <div>
              <h4 className="font-semibold text-white mb-2">Mint Amounts</h4>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 text-sm">
                {(Object.entries(MINT_AMOUNTS) as [TokenSymbol, bigint][]).map(
                  ([symbol, amount]) => (
                    <div key={symbol} className="text-[#8b92a5]">
                      <span className="text-white font-mono">
                        {formatTokenAmount(amount, DEMO_TOKENS[symbol].decimals, 0)}
                      </span>{" "}
                      {symbol}
                    </div>
                  )
                )}
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* How It Works */}
      <Card className="glass-card border-white/5">
        <CardContent className="p-6">
          <h3 className="font-bold text-white mb-4 flex items-center gap-2">
            <Info className="w-5 h-5 text-[#00d4aa]" />
            How to Use Demo Tokens
          </h3>
          <div className="space-y-4">
            <div className="flex gap-4">
              <div className="w-8 h-8 rounded-full bg-[#00d4aa]/10 flex items-center justify-center text-[#00d4aa] font-bold shrink-0">
                1
              </div>
              <div>
                <h4 className="font-semibold text-white">Mint Tokens</h4>
                <p className="text-sm text-[#8b92a5]">
                  Click "Mint Bundle" above to receive all demo tokens, or mint individually.
                </p>
              </div>
            </div>
            <div className="flex gap-4">
              <div className="w-8 h-8 rounded-full bg-[#00d4aa]/10 flex items-center justify-center text-[#00d4aa] font-bold shrink-0">
                2
              </div>
              <div>
                <h4 className="font-semibold text-white">Try Swapping</h4>
                <p className="text-sm text-[#8b92a5]">
                  Go to the Swap page and trade between any token pairs.
                </p>
              </div>
            </div>
            <div className="flex gap-4">
              <div className="w-8 h-8 rounded-full bg-[#00d4aa]/10 flex items-center justify-center text-[#00d4aa] font-bold shrink-0">
                3
              </div>
              <div>
                <h4 className="font-semibold text-white">Provide Liquidity</h4>
                <p className="text-sm text-[#8b92a5]">
                  Add tokens to a pool to earn trading fees and receive an LP NFT.
                </p>
              </div>
            </div>
            <div className="flex gap-4">
              <div className="w-8 h-8 rounded-full bg-[#00d4aa]/10 flex items-center justify-center text-[#00d4aa] font-bold shrink-0">
                4
              </div>
              <div>
                <h4 className="font-semibold text-white">Manage Positions</h4>
                <p className="text-sm text-[#8b92a5]">
                  View your LP positions, track earned fees, and remove liquidity anytime.
                </p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Contract Link */}
      <div className="text-center">
        <a
          href={`https://suiscan.xyz/testnet/object/${PACKAGE_ID}`}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-2 text-sm text-[#8b92a5] hover:text-[#00d4aa] transition-colors"
        >
          View Contract on Explorer
          <ExternalLink className="w-4 h-4" />
        </a>
      </div>
    </div>
  );
}

