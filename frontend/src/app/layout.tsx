import type { Metadata } from "next";
import { Outfit, JetBrains_Mono } from "next/font/google";
import "./globals.css";
import "@mysten/dapp-kit/dist/index.css";
import { SuiProvider } from "@/components/providers/sui-provider";
import { Header } from "@/components/layout/header";
import { Footer } from "@/components/layout/footer";
import { Toaster } from "@/components/ui/sonner";

const outfit = Outfit({
  variable: "--font-outfit",
  subsets: ["latin"],
  display: "swap",
});

const jetbrainsMono = JetBrains_Mono({
  variable: "--font-jetbrains",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "SuiSwap AMM | Decentralized Exchange on Sui",
  description: "Trade, provide liquidity, and earn fees on the most efficient AMM built on Sui Network. Features NFT-based LP positions and optimized stable swaps.",
  keywords: ["Sui", "DEX", "AMM", "DeFi", "Swap", "Liquidity", "NFT"],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark" suppressHydrationWarning>
      <body className={`${outfit.variable} ${jetbrainsMono.variable} min-h-screen flex flex-col antialiased`} suppressHydrationWarning>
        <SuiProvider>
          <Header />
          <main className="flex-1 pt-20 pb-8">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
              {children}
            </div>
          </main>
          <Footer />
          <Toaster position="bottom-right" />
        </SuiProvider>
      </body>
    </html>
  );
}
