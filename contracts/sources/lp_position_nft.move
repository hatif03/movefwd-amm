/// LP Position NFT Contract
/// Represents liquidity provider positions as NFTs with dynamic metadata
module sui_amm::lp_position_nft {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::clock::{Self, Clock};
    use sui::display::{Self, Display};
    use sui::package::{Self, Publisher};
    use std::string::{Self, String};
    
    use sui_amm::events;
    use sui_amm::errors;
    use sui_amm::math;

    // ============ Structs ============

    /// One-time witness for the module
    public struct LP_POSITION_NFT has drop {}

    /// LP Position NFT representing a liquidity provider's position
    public struct LPPositionNFT has key, store {
        id: UID,
        /// The pool this position belongs to
        pool_id: ID,
        /// Amount of LP tokens this position represents
        lp_tokens: u64,
        /// Accumulated fees in token A (claimable)
        accumulated_fees_a: u64,
        /// Accumulated fees in token B (claimable)
        accumulated_fees_b: u64,
        /// Fee growth snapshot at last update (for calculating new fees)
        fee_growth_a_last: u128,
        /// Fee growth snapshot at last update
        fee_growth_b_last: u128,
        /// Timestamp when position was created
        created_at: u64,
        /// Timestamp of last update
        last_updated: u64,
        /// Initial amounts deposited (for IL calculation)
        initial_amount_a: u64,
        initial_amount_b: u64,
        /// Name for display
        name: String,
        /// Description for display
        description: String,
        /// Image URL for display
        image_url: String,
    }

    /// Capability to mint/burn LP Position NFTs (held by pool)
    public struct LPPositionManager has key, store {
        id: UID,
        /// Pool ID this manager is associated with
        pool_id: ID,
        /// Total positions created
        total_positions: u64,
    }

    // ============ Init ============

    /// Initialize the display for LP Position NFTs
    fun init(otw: LP_POSITION_NFT, ctx: &mut TxContext) {
        let keys = vector[
            string::utf8(b"name"),
            string::utf8(b"description"),
            string::utf8(b"image_url"),
            string::utf8(b"pool_id"),
            string::utf8(b"lp_tokens"),
            string::utf8(b"project_url"),
        ];

        let values = vector[
            string::utf8(b"{name}"),
            string::utf8(b"{description}"),
            string::utf8(b"{image_url}"),
            string::utf8(b"{pool_id}"),
            string::utf8(b"{lp_tokens}"),
            string::utf8(b"https://sui-amm.io"),
        ];

        let publisher = package::claim(otw, ctx);
        let mut display = display::new_with_fields<LPPositionNFT>(
            &publisher, keys, values, ctx
        );
        
        display::update_version(&mut display);
        
        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }

    // ============ Manager Functions ============

    /// Create a new LP Position Manager for a pool
    public fun create_manager(
        pool_id: ID,
        ctx: &mut TxContext,
    ): LPPositionManager {
        LPPositionManager {
            id: object::new(ctx),
            pool_id,
            total_positions: 0,
        }
    }

    /// Get the pool ID from manager
    public fun manager_pool_id(manager: &LPPositionManager): ID {
        manager.pool_id
    }

    /// Get total positions created
    public fun manager_total_positions(manager: &LPPositionManager): u64 {
        manager.total_positions
    }

    // ============ Mint/Burn Functions ============

    /// Mint a new LP Position NFT
    /// Only callable by the liquidity pool contract
    public fun mint(
        manager: &mut LPPositionManager,
        pool_id: ID,
        lp_tokens: u64,
        initial_amount_a: u64,
        initial_amount_b: u64,
        fee_growth_a: u128,
        fee_growth_b: u128,
        clock: &Clock,
        ctx: &mut TxContext,
    ): LPPositionNFT {
        assert!(manager.pool_id == pool_id, errors::invalid_position_owner());
        assert!(lp_tokens > 0, errors::zero_amount());

        manager.total_positions = manager.total_positions + 1;
        
        let position_number = manager.total_positions;
        let timestamp = clock::timestamp_ms(clock);
        
        let position = LPPositionNFT {
            id: object::new(ctx),
            pool_id,
            lp_tokens,
            accumulated_fees_a: 0,
            accumulated_fees_b: 0,
            fee_growth_a_last: fee_growth_a,
            fee_growth_b_last: fee_growth_b,
            created_at: timestamp,
            last_updated: timestamp,
            initial_amount_a,
            initial_amount_b,
            name: create_position_name(position_number),
            description: string::utf8(b"LP Position representing liquidity in Sui AMM pool"),
            image_url: string::utf8(b"https://sui-amm.io/nft/lp-position.png"),
        };

        events::emit_position_minted(
            object::id(&position),
            pool_id,
            tx_context::sender(ctx),
            lp_tokens,
        );

        position
    }

    /// Burn an LP Position NFT (when removing all liquidity)
    public fun burn(
        manager: &mut LPPositionManager,
        position: LPPositionNFT,
        ctx: &TxContext,
    ) {
        assert!(manager.pool_id == position.pool_id, errors::invalid_position_owner());
        
        let LPPositionNFT {
            id,
            pool_id,
            lp_tokens: _,
            accumulated_fees_a: _,
            accumulated_fees_b: _,
            fee_growth_a_last: _,
            fee_growth_b_last: _,
            created_at: _,
            last_updated: _,
            initial_amount_a: _,
            initial_amount_b: _,
            name: _,
            description: _,
            image_url: _,
        } = position;

        events::emit_position_burned(
            object::uid_to_inner(&id),
            pool_id,
            tx_context::sender(ctx),
        );

        object::delete(id);
    }

    // ============ Update Functions ============

    /// Update LP tokens in position (when adding/removing liquidity)
    public fun update_lp_tokens(
        position: &mut LPPositionNFT,
        new_lp_tokens: u64,
        clock: &Clock,
    ) {
        position.lp_tokens = new_lp_tokens;
        position.last_updated = clock::timestamp_ms(clock);

        events::emit_position_updated(
            object::id(position),
            position.lp_tokens,
            position.accumulated_fees_a,
            position.accumulated_fees_b,
        );
    }

    /// Add LP tokens to position
    public fun add_lp_tokens(
        position: &mut LPPositionNFT,
        additional_tokens: u64,
        additional_amount_a: u64,
        additional_amount_b: u64,
        clock: &Clock,
    ) {
        position.lp_tokens = math::safe_add(position.lp_tokens, additional_tokens);
        position.initial_amount_a = math::safe_add(position.initial_amount_a, additional_amount_a);
        position.initial_amount_b = math::safe_add(position.initial_amount_b, additional_amount_b);
        position.last_updated = clock::timestamp_ms(clock);

        events::emit_position_updated(
            object::id(position),
            position.lp_tokens,
            position.accumulated_fees_a,
            position.accumulated_fees_b,
        );
    }

    /// Remove LP tokens from position
    public fun remove_lp_tokens(
        position: &mut LPPositionNFT,
        tokens_to_remove: u64,
        clock: &Clock,
    ) {
        assert!(position.lp_tokens >= tokens_to_remove, errors::insufficient_lp_tokens());
        position.lp_tokens = position.lp_tokens - tokens_to_remove;
        position.last_updated = clock::timestamp_ms(clock);

        events::emit_position_updated(
            object::id(position),
            position.lp_tokens,
            position.accumulated_fees_a,
            position.accumulated_fees_b,
        );
    }

    /// Update accumulated fees based on global fee growth
    public fun update_fees(
        position: &mut LPPositionNFT,
        global_fee_growth_a: u128,
        global_fee_growth_b: u128,
        clock: &Clock,
    ) {
        // Calculate new fees earned since last update
        let fee_growth_a_delta = global_fee_growth_a - position.fee_growth_a_last;
        let fee_growth_b_delta = global_fee_growth_b - position.fee_growth_b_last;

        // Calculate fees earned: lp_tokens * fee_growth_delta / PRECISION
        let precision = 1000000000000000000u128; // 10^18
        let new_fees_a = ((position.lp_tokens as u128) * fee_growth_a_delta / precision as u64);
        let new_fees_b = ((position.lp_tokens as u128) * fee_growth_b_delta / precision as u64);

        // Update accumulated fees
        position.accumulated_fees_a = math::safe_add(position.accumulated_fees_a, new_fees_a);
        position.accumulated_fees_b = math::safe_add(position.accumulated_fees_b, new_fees_b);

        // Update snapshots
        position.fee_growth_a_last = global_fee_growth_a;
        position.fee_growth_b_last = global_fee_growth_b;
        position.last_updated = clock::timestamp_ms(clock);

        events::emit_position_updated(
            object::id(position),
            position.lp_tokens,
            position.accumulated_fees_a,
            position.accumulated_fees_b,
        );
    }

    /// Claim accumulated fees (resets accumulated fees to 0)
    public fun claim_fees(
        position: &mut LPPositionNFT,
        clock: &Clock,
    ): (u64, u64) {
        let fees_a = position.accumulated_fees_a;
        let fees_b = position.accumulated_fees_b;

        position.accumulated_fees_a = 0;
        position.accumulated_fees_b = 0;
        position.last_updated = clock::timestamp_ms(clock);

        events::emit_position_updated(
            object::id(position),
            position.lp_tokens,
            0,
            0,
        );

        (fees_a, fees_b)
    }

    /// Set fees directly (used by fee distributor)
    public fun set_accumulated_fees(
        position: &mut LPPositionNFT,
        fees_a: u64,
        fees_b: u64,
        clock: &Clock,
    ) {
        position.accumulated_fees_a = fees_a;
        position.accumulated_fees_b = fees_b;
        position.last_updated = clock::timestamp_ms(clock);
    }

    // ============ View Functions ============

    /// Get position ID
    public fun id(position: &LPPositionNFT): ID {
        object::id(position)
    }

    /// Get pool ID
    public fun pool_id(position: &LPPositionNFT): ID {
        position.pool_id
    }

    /// Get LP tokens amount
    public fun lp_tokens(position: &LPPositionNFT): u64 {
        position.lp_tokens
    }

    /// Get accumulated fees
    public fun accumulated_fees(position: &LPPositionNFT): (u64, u64) {
        (position.accumulated_fees_a, position.accumulated_fees_b)
    }

    /// Get accumulated fees for token A
    public fun accumulated_fees_a(position: &LPPositionNFT): u64 {
        position.accumulated_fees_a
    }

    /// Get accumulated fees for token B
    public fun accumulated_fees_b(position: &LPPositionNFT): u64 {
        position.accumulated_fees_b
    }

    /// Get fee growth snapshots
    public fun fee_growth_last(position: &LPPositionNFT): (u128, u128) {
        (position.fee_growth_a_last, position.fee_growth_b_last)
    }

    /// Get creation timestamp
    public fun created_at(position: &LPPositionNFT): u64 {
        position.created_at
    }

    /// Get last updated timestamp
    public fun last_updated(position: &LPPositionNFT): u64 {
        position.last_updated
    }

    /// Get initial deposit amounts
    public fun initial_amounts(position: &LPPositionNFT): (u64, u64) {
        (position.initial_amount_a, position.initial_amount_b)
    }

    /// Calculate current position value based on pool reserves
    public fun calculate_position_value(
        position: &LPPositionNFT,
        reserve_a: u64,
        reserve_b: u64,
        total_supply: u64,
    ): (u64, u64) {
        if (total_supply == 0) {
            return (0, 0)
        };

        let (amount_a, amount_b) = math::calculate_liquidity_removal(
            position.lp_tokens,
            reserve_a,
            reserve_b,
            total_supply,
        );

        (amount_a, amount_b)
    }

    /// Calculate impermanent loss for this position
    /// Returns IL in basis points
    public fun calculate_impermanent_loss(
        position: &LPPositionNFT,
        current_reserve_a: u64,
        current_reserve_b: u64,
        total_supply: u64,
    ): u64 {
        if (position.initial_amount_a == 0 || position.initial_amount_b == 0) {
            return 0
        };

        // Calculate current position value
        let (current_a, current_b) = calculate_position_value(
            position,
            current_reserve_a,
            current_reserve_b,
            total_supply,
        );

        // Calculate price ratio (current price / initial price)
        // Initial price = initial_amount_b / initial_amount_a
        // Current price = current_reserve_b / current_reserve_a
        // Ratio = current_price / initial_price
        let initial_price = (position.initial_amount_b as u128) * 10000 / (position.initial_amount_a as u128);
        let current_price = (current_reserve_b as u128) * 10000 / (current_reserve_a as u128);
        
        let price_ratio = if (initial_price > 0) {
            ((current_price * 10000 / initial_price) as u64)
        } else {
            10000 // 1:1 if initial price was 0
        };

        math::calculate_impermanent_loss(price_ratio)
    }

    /// Get position share of total pool (in basis points)
    public fun calculate_pool_share(
        position: &LPPositionNFT,
        total_supply: u64,
    ): u64 {
        if (total_supply == 0) {
            return 0
        };

        (((position.lp_tokens as u128) * 10000 / (total_supply as u128)) as u64)
    }

    // ============ Helper Functions ============

    /// Create position name
    fun create_position_name(position_number: u64): String {
        let mut name = string::utf8(b"Sui AMM LP Position #");
        string::append(&mut name, u64_to_string(position_number));
        name
    }

    /// Convert u64 to string
    fun u64_to_string(value: u64): String {
        if (value == 0) {
            return string::utf8(b"0")
        };
        
        let mut buffer = vector::empty<u8>();
        let mut n = value;
        
        while (n > 0) {
            let digit = ((n % 10) as u8) + 48; // ASCII '0' = 48
            vector::push_back(&mut buffer, digit);
            n = n / 10;
        };
        
        vector::reverse(&mut buffer);
        string::utf8(buffer)
    }

    // ============ Test Functions ============

    #[test_only]
    public fun create_for_testing(
        pool_id: ID,
        lp_tokens: u64,
        ctx: &mut TxContext,
    ): LPPositionNFT {
        LPPositionNFT {
            id: object::new(ctx),
            pool_id,
            lp_tokens,
            accumulated_fees_a: 0,
            accumulated_fees_b: 0,
            fee_growth_a_last: 0,
            fee_growth_b_last: 0,
            created_at: 0,
            last_updated: 0,
            initial_amount_a: 0,
            initial_amount_b: 0,
            name: string::utf8(b"Test Position"),
            description: string::utf8(b"Test"),
            image_url: string::utf8(b""),
        }
    }

    #[test_only]
    public fun destroy_for_testing(position: LPPositionNFT) {
        let LPPositionNFT {
            id,
            pool_id: _,
            lp_tokens: _,
            accumulated_fees_a: _,
            accumulated_fees_b: _,
            fee_growth_a_last: _,
            fee_growth_b_last: _,
            created_at: _,
            last_updated: _,
            initial_amount_a: _,
            initial_amount_b: _,
            name: _,
            description: _,
            image_url: _,
        } = position;
        object::delete(id);
    }
}

