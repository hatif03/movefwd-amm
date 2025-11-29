"use client";

import { Droplets, Github, Twitter, FileText } from "lucide-react";
import Link from "next/link";

export function Footer() {
  return (
    <footer className="border-t border-white/5 mt-auto">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex flex-col md:flex-row items-center justify-between gap-4">
          {/* Logo & Description */}
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-[#00d4aa] to-[#00a8ff] flex items-center justify-center">
              <Droplets className="w-5 h-5 text-[#0a0e1a]" />
            </div>
            <div>
              <span className="text-sm font-semibold text-[#e8eaed]">SuiSwap AMM</span>
              <p className="text-xs text-[#8b92a5]">Decentralized Exchange on Sui</p>
            </div>
          </div>

          {/* Links */}
          <div className="flex items-center gap-6">
            <Link
              href="https://suiscan.xyz/testnet/object/0x2ece39501958bbccee8d22cad8ed70226148da7df7e6fbc4aa20b5aeb9c0de65"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-2 text-sm text-[#8b92a5] hover:text-[#00d4aa] transition-colors"
            >
              <FileText className="w-4 h-4" />
              <span>Contract</span>
            </Link>
            <Link
              href="https://github.com"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-2 text-sm text-[#8b92a5] hover:text-[#00d4aa] transition-colors"
            >
              <Github className="w-4 h-4" />
              <span>GitHub</span>
            </Link>
            <Link
              href="https://twitter.com"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-2 text-sm text-[#8b92a5] hover:text-[#00d4aa] transition-colors"
            >
              <Twitter className="w-4 h-4" />
              <span>Twitter</span>
            </Link>
          </div>

          {/* Copyright */}
          <div className="text-xs text-[#8b92a5]">
            © 2024 SuiSwap. Built on Sui Network.
          </div>
        </div>
      </div>
    </footer>
  );
}

