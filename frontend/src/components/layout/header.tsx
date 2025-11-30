"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { ConnectButton, useCurrentAccount } from "@mysten/dapp-kit";
import { 
  ArrowLeftRight, 
  Droplets, 
  LayoutDashboard, 
  Wallet,
  Coins,
  Menu,
  X
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { useState } from "react";

const navLinks = [
  { href: "/", label: "Dashboard", icon: LayoutDashboard },
  { href: "/swap", label: "Swap", icon: ArrowLeftRight },
  { href: "/pools", label: "Pools", icon: Droplets },
  { href: "/positions", label: "Positions", icon: Wallet },
  { href: "/faucet", label: "Faucet", icon: Coins },
];

export function Header() {
  const pathname = usePathname();
  const account = useCurrentAccount();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  return (
    <header className="fixed top-0 left-0 right-0 z-50 glass-card">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-[#00d4aa] to-[#00a8ff] flex items-center justify-center">
              <Droplets className="w-5 h-5 text-[#0a0e1a]" />
            </div>
            <span className="text-xl font-bold gradient-text hidden sm:block">
              SuiSwap
            </span>
          </Link>

          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center gap-1">
            {navLinks.map((link) => {
              const isActive = pathname === link.href;
              const Icon = link.icon;
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${
                    isActive
                      ? "bg-[#00d4aa]/10 text-[#00d4aa]"
                      : "text-[#8b92a5] hover:text-[#e8eaed] hover:bg-white/5"
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  {link.label}
                </Link>
              );
            })}
          </nav>

          {/* Wallet Connection */}
          <div className="flex items-center gap-3">
            {/* Network Badge */}
            <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-lg bg-[#1a2035] border border-[#00d4aa]/20">
              <div className="w-2 h-2 rounded-full bg-[#00d4aa] pulse-dot" />
              <span className="text-xs font-medium text-[#00d4aa]">Testnet</span>
            </div>

            {/* Connect Button - Styled */}
            <div className="connect-button-wrapper">
              <ConnectButton 
                connectText="Connect Wallet"
              />
            </div>

            {/* Mobile Menu Button */}
            <Button
              variant="ghost"
              size="icon"
              className="md:hidden"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            >
              {mobileMenuOpen ? (
                <X className="w-5 h-5" />
              ) : (
                <Menu className="w-5 h-5" />
              )}
            </Button>
          </div>
        </div>

        {/* Mobile Navigation */}
        {mobileMenuOpen && (
          <div className="md:hidden py-4 border-t border-white/5">
            <nav className="flex flex-col gap-1">
              {navLinks.map((link) => {
                const isActive = pathname === link.href;
                const Icon = link.icon;
                return (
                  <Link
                    key={link.href}
                    href={link.href}
                    onClick={() => setMobileMenuOpen(false)}
                    className={`flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition-all ${
                      isActive
                        ? "bg-[#00d4aa]/10 text-[#00d4aa]"
                        : "text-[#8b92a5] hover:text-[#e8eaed] hover:bg-white/5"
                    }`}
                  >
                    <Icon className="w-5 h-5" />
                    {link.label}
                  </Link>
                );
              })}
            </nav>
          </div>
        )}
      </div>

      <style jsx global>{`
        .connect-button-wrapper button {
          background: linear-gradient(135deg, #00d4aa 0%, #00a8ff 100%) !important;
          color: #0a0e1a !important;
          font-weight: 600 !important;
          padding: 8px 16px !important;
          border-radius: 8px !important;
          border: none !important;
          font-size: 14px !important;
          transition: all 0.2s ease !important;
        }
        .connect-button-wrapper button:hover {
          opacity: 0.9 !important;
          transform: translateY(-1px) !important;
        }
      `}</style>
    </header>
  );
}


