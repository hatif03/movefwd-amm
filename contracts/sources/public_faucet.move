/// Public Faucet - Allows anyone to mint demo tokens
/// Rate limited to prevent abuse (once per epoch per address per token)
module sui_amm::public_faucet {
    use sui::coin::{Self, TreasuryCap};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::object::{Self, UID};
    
    use sui_amm::demo_usdc::DEMO_USDC;
    use sui_amm::demo_usdt::DEMO_USDT;
    use sui_amm::demo_eth::DEMO_ETH;
    use sui_amm::demo_btc::DEMO_BTC;
    use sui_amm::demo_wsui::DEMO_WSUI;

    // ============ Error Codes ============
    const EAlreadyClaimedThisEpoch: u64 = 1;
    const ENotAuthorized: u64 = 2;

    // ============ Constants ============
    // Mint amounts (generous for testing)
    const USDC_AMOUNT: u64 = 100_000_000000;      // 100,000 USDC (6 decimals)
    const USDT_AMOUNT: u64 = 100_000_000000;      // 100,000 USDT (6 decimals)
    const ETH_AMOUNT: u64 = 10_000000000000000000; // 10 ETH (18 decimals)
    const BTC_AMOUNT: u64 = 1_00000000;            // 1 BTC (8 decimals)
    const WSUI_AMOUNT: u64 = 10_000_000000000;     // 10,000 WSUI (9 decimals)

    // ============ Structs ============

    /// The public faucet that holds all treasury caps
    public struct PublicFaucet has key {
        id: UID,
        usdc_cap: TreasuryCap<DEMO_USDC>,
        usdt_cap: TreasuryCap<DEMO_USDT>,
        eth_cap: TreasuryCap<DEMO_ETH>,
        btc_cap: TreasuryCap<DEMO_BTC>,
        wsui_cap: TreasuryCap<DEMO_WSUI>,
        // Track claims per epoch: address -> last_claimed_epoch
        usdc_claims: Table<address, u64>,
        usdt_claims: Table<address, u64>,
        eth_claims: Table<address, u64>,
        btc_claims: Table<address, u64>,
        wsui_claims: Table<address, u64>,
    }

    /// Admin cap for faucet management
    public struct FaucetAdminCap has key, store {
        id: UID,
    }

    // ============ Init ============
    
    /// Note: This doesn't create the faucet automatically.
    /// The deployer must call `create_faucet` after deployment and provide TreasuryCaps.
    fun init(ctx: &mut TxContext) {
        let admin_cap = FaucetAdminCap {
            id: object::new(ctx),
        };
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    // ============ Admin Functions ============

    /// Create the public faucet by transferring all treasury caps to it
    public entry fun create_faucet(
        _admin: &FaucetAdminCap,
        usdc_cap: TreasuryCap<DEMO_USDC>,
        usdt_cap: TreasuryCap<DEMO_USDT>,
        eth_cap: TreasuryCap<DEMO_ETH>,
        btc_cap: TreasuryCap<DEMO_BTC>,
        wsui_cap: TreasuryCap<DEMO_WSUI>,
        ctx: &mut TxContext,
    ) {
        let faucet = PublicFaucet {
            id: object::new(ctx),
            usdc_cap,
            usdt_cap,
            eth_cap,
            btc_cap,
            wsui_cap,
            usdc_claims: table::new(ctx),
            usdt_claims: table::new(ctx),
            eth_claims: table::new(ctx),
            btc_claims: table::new(ctx),
            wsui_claims: table::new(ctx),
        };
        transfer::share_object(faucet);
    }

    // ============ Public Functions - Anyone Can Call ============

    /// Request USDC tokens (rate limited: once per epoch)
    public entry fun request_usdc(
        faucet: &mut PublicFaucet,
        ctx: &mut TxContext,
    ) {
        let sender = tx_context::sender(ctx);
        let current_epoch = tx_context::epoch(ctx);
        
        // Check if already claimed this epoch
        if (table::contains(&faucet.usdc_claims, sender)) {
            let last_epoch = *table::borrow(&faucet.usdc_claims, sender);
            assert!(current_epoch > last_epoch, EAlreadyClaimedThisEpoch);
            *table::borrow_mut(&mut faucet.usdc_claims, sender) = current_epoch;
        } else {
            table::add(&mut faucet.usdc_claims, sender, current_epoch);
        };

        let coins = coin::mint(&mut faucet.usdc_cap, USDC_AMOUNT, ctx);
        transfer::public_transfer(coins, sender);
    }

    /// Request USDT tokens (rate limited: once per epoch)
    public entry fun request_usdt(
        faucet: &mut PublicFaucet,
        ctx: &mut TxContext,
    ) {
        let sender = tx_context::sender(ctx);
        let current_epoch = tx_context::epoch(ctx);
        
        if (table::contains(&faucet.usdt_claims, sender)) {
            let last_epoch = *table::borrow(&faucet.usdt_claims, sender);
            assert!(current_epoch > last_epoch, EAlreadyClaimedThisEpoch);
            *table::borrow_mut(&mut faucet.usdt_claims, sender) = current_epoch;
        } else {
            table::add(&mut faucet.usdt_claims, sender, current_epoch);
        };

        let coins = coin::mint(&mut faucet.usdt_cap, USDT_AMOUNT, ctx);
        transfer::public_transfer(coins, sender);
    }

    /// Request ETH tokens (rate limited: once per epoch)
    public entry fun request_eth(
        faucet: &mut PublicFaucet,
        ctx: &mut TxContext,
    ) {
        let sender = tx_context::sender(ctx);
        let current_epoch = tx_context::epoch(ctx);
        
        if (table::contains(&faucet.eth_claims, sender)) {
            let last_epoch = *table::borrow(&faucet.eth_claims, sender);
            assert!(current_epoch > last_epoch, EAlreadyClaimedThisEpoch);
            *table::borrow_mut(&mut faucet.eth_claims, sender) = current_epoch;
        } else {
            table::add(&mut faucet.eth_claims, sender, current_epoch);
        };

        let coins = coin::mint(&mut faucet.eth_cap, ETH_AMOUNT, ctx);
        transfer::public_transfer(coins, sender);
    }

    /// Request BTC tokens (rate limited: once per epoch)
    public entry fun request_btc(
        faucet: &mut PublicFaucet,
        ctx: &mut TxContext,
    ) {
        let sender = tx_context::sender(ctx);
        let current_epoch = tx_context::epoch(ctx);
        
        if (table::contains(&faucet.btc_claims, sender)) {
            let last_epoch = *table::borrow(&faucet.btc_claims, sender);
            assert!(current_epoch > last_epoch, EAlreadyClaimedThisEpoch);
            *table::borrow_mut(&mut faucet.btc_claims, sender) = current_epoch;
        } else {
            table::add(&mut faucet.btc_claims, sender, current_epoch);
        };

        let coins = coin::mint(&mut faucet.btc_cap, BTC_AMOUNT, ctx);
        transfer::public_transfer(coins, sender);
    }

    /// Request WSUI tokens (rate limited: once per epoch)
    public entry fun request_wsui(
        faucet: &mut PublicFaucet,
        ctx: &mut TxContext,
    ) {
        let sender = tx_context::sender(ctx);
        let current_epoch = tx_context::epoch(ctx);
        
        if (table::contains(&faucet.wsui_claims, sender)) {
            let last_epoch = *table::borrow(&faucet.wsui_claims, sender);
            assert!(current_epoch > last_epoch, EAlreadyClaimedThisEpoch);
            *table::borrow_mut(&mut faucet.wsui_claims, sender) = current_epoch;
        } else {
            table::add(&mut faucet.wsui_claims, sender, current_epoch);
        };

        let coins = coin::mint(&mut faucet.wsui_cap, WSUI_AMOUNT, ctx);
        transfer::public_transfer(coins, sender);
    }

    /// Request ALL tokens at once (rate limited per token)
    public entry fun request_all_tokens(
        faucet: &mut PublicFaucet,
        ctx: &mut TxContext,
    ) {
        let sender = tx_context::sender(ctx);
        let current_epoch = tx_context::epoch(ctx);

        // USDC
        if (!table::contains(&faucet.usdc_claims, sender)) {
            table::add(&mut faucet.usdc_claims, sender, current_epoch);
            let coins = coin::mint(&mut faucet.usdc_cap, USDC_AMOUNT, ctx);
            transfer::public_transfer(coins, sender);
        } else {
            let last_epoch = *table::borrow(&faucet.usdc_claims, sender);
            if (current_epoch > last_epoch) {
                *table::borrow_mut(&mut faucet.usdc_claims, sender) = current_epoch;
                let coins = coin::mint(&mut faucet.usdc_cap, USDC_AMOUNT, ctx);
                transfer::public_transfer(coins, sender);
            }
        };

        // USDT
        if (!table::contains(&faucet.usdt_claims, sender)) {
            table::add(&mut faucet.usdt_claims, sender, current_epoch);
            let coins = coin::mint(&mut faucet.usdt_cap, USDT_AMOUNT, ctx);
            transfer::public_transfer(coins, sender);
        } else {
            let last_epoch = *table::borrow(&faucet.usdt_claims, sender);
            if (current_epoch > last_epoch) {
                *table::borrow_mut(&mut faucet.usdt_claims, sender) = current_epoch;
                let coins = coin::mint(&mut faucet.usdt_cap, USDT_AMOUNT, ctx);
                transfer::public_transfer(coins, sender);
            }
        };

        // ETH
        if (!table::contains(&faucet.eth_claims, sender)) {
            table::add(&mut faucet.eth_claims, sender, current_epoch);
            let coins = coin::mint(&mut faucet.eth_cap, ETH_AMOUNT, ctx);
            transfer::public_transfer(coins, sender);
        } else {
            let last_epoch = *table::borrow(&faucet.eth_claims, sender);
            if (current_epoch > last_epoch) {
                *table::borrow_mut(&mut faucet.eth_claims, sender) = current_epoch;
                let coins = coin::mint(&mut faucet.eth_cap, ETH_AMOUNT, ctx);
                transfer::public_transfer(coins, sender);
            }
        };

        // BTC
        if (!table::contains(&faucet.btc_claims, sender)) {
            table::add(&mut faucet.btc_claims, sender, current_epoch);
            let coins = coin::mint(&mut faucet.btc_cap, BTC_AMOUNT, ctx);
            transfer::public_transfer(coins, sender);
        } else {
            let last_epoch = *table::borrow(&faucet.btc_claims, sender);
            if (current_epoch > last_epoch) {
                *table::borrow_mut(&mut faucet.btc_claims, sender) = current_epoch;
                let coins = coin::mint(&mut faucet.btc_cap, BTC_AMOUNT, ctx);
                transfer::public_transfer(coins, sender);
            }
        };

        // WSUI
        if (!table::contains(&faucet.wsui_claims, sender)) {
            table::add(&mut faucet.wsui_claims, sender, current_epoch);
            let coins = coin::mint(&mut faucet.wsui_cap, WSUI_AMOUNT, ctx);
            transfer::public_transfer(coins, sender);
        } else {
            let last_epoch = *table::borrow(&faucet.wsui_claims, sender);
            if (current_epoch > last_epoch) {
                *table::borrow_mut(&mut faucet.wsui_claims, sender) = current_epoch;
                let coins = coin::mint(&mut faucet.wsui_cap, WSUI_AMOUNT, ctx);
                transfer::public_transfer(coins, sender);
            }
        };
    }

    // ============ View Functions ============

    /// Check if user can claim USDC this epoch
    public fun can_claim_usdc(faucet: &PublicFaucet, user: address, current_epoch: u64): bool {
        if (!table::contains(&faucet.usdc_claims, user)) {
            true
        } else {
            let last_epoch = *table::borrow(&faucet.usdc_claims, user);
            current_epoch > last_epoch
        }
    }

    /// Check if user can claim any tokens this epoch
    public fun can_claim_any(faucet: &PublicFaucet, user: address, current_epoch: u64): bool {
        can_claim_usdc(faucet, user, current_epoch) ||
        !table::contains(&faucet.usdt_claims, user) || *table::borrow(&faucet.usdt_claims, user) < current_epoch ||
        !table::contains(&faucet.eth_claims, user) || *table::borrow(&faucet.eth_claims, user) < current_epoch ||
        !table::contains(&faucet.btc_claims, user) || *table::borrow(&faucet.btc_claims, user) < current_epoch ||
        !table::contains(&faucet.wsui_claims, user) || *table::borrow(&faucet.wsui_claims, user) < current_epoch
    }
}

