/// Demo tokens for testing the AMM
/// These are test tokens that can be minted freely for demo purposes
module sui_amm::demo_tokens {
    use sui::coin::{Self, TreasuryCap, Coin};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::url::{Self, Url};
    use std::option;

    // ============ Demo Token Types ============

    /// Demo USDC stablecoin
    public struct DEMO_USDC has drop {}

    /// Demo USDT stablecoin
    public struct DEMO_USDT has drop {}

    /// Demo ETH token
    public struct DEMO_ETH has drop {}

    /// Demo BTC token
    public struct DEMO_BTC has drop {}

    /// Demo SUI token (wrapped)
    public struct DEMO_WSUI has drop {}

    // ============ Init Functions ============

    fun init(ctx: &mut TxContext) {
        // Create DEMO_USDC
        let (usdc_treasury, usdc_metadata) = coin::create_currency(
            DEMO_USDC {},
            6, // decimals
            b"USDC",
            b"Demo USD Coin",
            b"Demo USDC token for testing Sui AMM",
            option::some(url::new_unsafe_from_bytes(b"https://sui-amm.io/tokens/usdc.png")),
            ctx,
        );
        transfer::public_freeze_object(usdc_metadata);
        transfer::public_transfer(usdc_treasury, tx_context::sender(ctx));

        // Create DEMO_USDT
        let (usdt_treasury, usdt_metadata) = coin::create_currency(
            DEMO_USDT {},
            6,
            b"USDT",
            b"Demo Tether USD",
            b"Demo USDT token for testing Sui AMM",
            option::some(url::new_unsafe_from_bytes(b"https://sui-amm.io/tokens/usdt.png")),
            ctx,
        );
        transfer::public_freeze_object(usdt_metadata);
        transfer::public_transfer(usdt_treasury, tx_context::sender(ctx));

        // Create DEMO_ETH
        let (eth_treasury, eth_metadata) = coin::create_currency(
            DEMO_ETH {},
            18,
            b"ETH",
            b"Demo Ethereum",
            b"Demo ETH token for testing Sui AMM",
            option::some(url::new_unsafe_from_bytes(b"https://sui-amm.io/tokens/eth.png")),
            ctx,
        );
        transfer::public_freeze_object(eth_metadata);
        transfer::public_transfer(eth_treasury, tx_context::sender(ctx));

        // Create DEMO_BTC
        let (btc_treasury, btc_metadata) = coin::create_currency(
            DEMO_BTC {},
            8,
            b"BTC",
            b"Demo Bitcoin",
            b"Demo BTC token for testing Sui AMM",
            option::some(url::new_unsafe_from_bytes(b"https://sui-amm.io/tokens/btc.png")),
            ctx,
        );
        transfer::public_freeze_object(btc_metadata);
        transfer::public_transfer(btc_treasury, tx_context::sender(ctx));

        // Create DEMO_WSUI
        let (wsui_treasury, wsui_metadata) = coin::create_currency(
            DEMO_WSUI {},
            9,
            b"WSUI",
            b"Demo Wrapped SUI",
            b"Demo wrapped SUI token for testing Sui AMM",
            option::some(url::new_unsafe_from_bytes(b"https://sui-amm.io/tokens/sui.png")),
            ctx,
        );
        transfer::public_freeze_object(wsui_metadata);
        transfer::public_transfer(wsui_treasury, tx_context::sender(ctx));
    }

    // ============ Mint Functions ============

    /// Mint DEMO_USDC tokens
    public entry fun mint_usdc(
        treasury: &mut TreasuryCap<DEMO_USDC>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let coin = coin::mint(treasury, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }

    /// Mint DEMO_USDT tokens
    public entry fun mint_usdt(
        treasury: &mut TreasuryCap<DEMO_USDT>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let coin = coin::mint(treasury, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }

    /// Mint DEMO_ETH tokens
    public entry fun mint_eth(
        treasury: &mut TreasuryCap<DEMO_ETH>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let coin = coin::mint(treasury, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }

    /// Mint DEMO_BTC tokens
    public entry fun mint_btc(
        treasury: &mut TreasuryCap<DEMO_BTC>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let coin = coin::mint(treasury, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }

    /// Mint DEMO_WSUI tokens
    public entry fun mint_wsui(
        treasury: &mut TreasuryCap<DEMO_WSUI>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let coin = coin::mint(treasury, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }

    // ============ Batch Mint Functions ============

    /// Mint a bundle of all demo tokens for testing
    public entry fun mint_demo_bundle(
        usdc_treasury: &mut TreasuryCap<DEMO_USDC>,
        usdt_treasury: &mut TreasuryCap<DEMO_USDT>,
        eth_treasury: &mut TreasuryCap<DEMO_ETH>,
        btc_treasury: &mut TreasuryCap<DEMO_BTC>,
        wsui_treasury: &mut TreasuryCap<DEMO_WSUI>,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        // Mint 1 million USDC (6 decimals)
        let usdc = coin::mint(usdc_treasury, 1000000_000000, ctx);
        transfer::public_transfer(usdc, recipient);
        
        // Mint 1 million USDT (6 decimals)
        let usdt = coin::mint(usdt_treasury, 1000000_000000, ctx);
        transfer::public_transfer(usdt, recipient);
        
        // Mint 100 ETH (18 decimals)
        let eth = coin::mint(eth_treasury, 100_000000000000000000, ctx);
        transfer::public_transfer(eth, recipient);
        
        // Mint 10 BTC (8 decimals)
        let btc = coin::mint(btc_treasury, 10_00000000, ctx);
        transfer::public_transfer(btc, recipient);
        
        // Mint 10000 WSUI (9 decimals)
        let wsui = coin::mint(wsui_treasury, 10000_000000000, ctx);
        transfer::public_transfer(wsui, recipient);
    }
}

