/// Pool Factory Contract
/// Creates and manages liquidity pools
#[allow(unused_variable, duplicate_alias, deprecated_usage)]
module sui_amm::pool_factory {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::table::{Self, Table};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::clock::Clock;
    use std::type_name::{Self, TypeName};
    
    use sui_amm::events;
    use sui_amm::errors;
    use sui_amm::constants;
    use sui_amm::math;
    use sui_amm::lp_position_nft::{Self, LPPositionNFT, LPPositionManager};

    // ============ Structs ============

    /// Admin capability for the pool factory
    public struct PoolFactoryAdminCap has key, store {
        id: UID,
    }

    /// Pool Factory - creates and tracks all pools
    public struct PoolFactory has key {
        id: UID,
        /// Registry mapping pool key to pool ID
        pool_registry: Table<PoolKey, ID>,
        /// Total number of pools created
        total_pools: u64,
        /// Protocol fee recipient
        protocol_fee_recipient: address,
        /// Whether pool creation is paused
        creation_paused: bool,
    }

    /// Key for pool lookup (token types + fee tier)
    public struct PoolKey has copy, drop, store {
        token_a_type: TypeName,
        token_b_type: TypeName,
        fee_tier: u64,
    }

    /// Liquidity Pool with constant product formula
    public struct LiquidityPool<phantom CoinA, phantom CoinB> has key, store {
        id: UID,
        /// Reserve of token A
        reserve_a: Balance<CoinA>,
        /// Reserve of token B
        reserve_b: Balance<CoinB>,
        /// Fee tier in basis points
        fee_tier: u64,
        /// Total LP token supply
        total_supply: u64,
        /// Protocol fees accumulated (token A)
        protocol_fees_a: Balance<CoinA>,
        /// Protocol fees accumulated (token B)
        protocol_fees_b: Balance<CoinB>,
        /// Global fee growth per LP token for token A (scaled by 10^18)
        fee_growth_global_a: u128,
        /// Global fee growth per LP token for token B (scaled by 10^18)
        fee_growth_global_b: u128,
        /// LP Position Manager for this pool
        position_manager: LPPositionManager,
        /// Whether the pool is paused
        is_paused: bool,
        /// Minimum liquidity locked forever
        minimum_liquidity: u64,
        /// K value (reserve_a * reserve_b) for invariant checking
        k_last: u128,
    }

    // ============ Init ============

    /// Initialize the pool factory
    fun init(ctx: &mut TxContext) {
        let admin_cap = PoolFactoryAdminCap {
            id: object::new(ctx),
        };

        let factory = PoolFactory {
            id: object::new(ctx),
            pool_registry: table::new(ctx),
            total_pools: 0,
            protocol_fee_recipient: tx_context::sender(ctx),
            creation_paused: false,
        };

        transfer::transfer(admin_cap, tx_context::sender(ctx));
        transfer::share_object(factory);
    }

    // ============ Pool Creation ============

    /// Create a new liquidity pool with initial liquidity
    public fun create_pool<CoinA, CoinB>(
        factory: &mut PoolFactory,
        coin_a: Coin<CoinA>,
        coin_b: Coin<CoinB>,
        fee_tier: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): LPPositionNFT {
        // Validate inputs
        assert!(!factory.creation_paused, errors::pool_paused());
        assert!(constants::is_valid_fee_tier(fee_tier), errors::invalid_fee_tier());
        
        let amount_a = coin::value(&coin_a);
        let amount_b = coin::value(&coin_b);
        assert!(amount_a > 0 && amount_b > 0, errors::zero_amount());

        // Create pool key and check if pool exists
        let type_a = type_name::get<CoinA>();
        let type_b = type_name::get<CoinB>();
        
        // Ensure consistent ordering (type_a < type_b lexicographically)
        let (ordered_type_a, ordered_type_b, ordered_coin_a, ordered_coin_b) = 
            order_types_and_coins(type_a, type_b, coin_a, coin_b);
        
        let pool_key = PoolKey {
            token_a_type: ordered_type_a,
            token_b_type: ordered_type_b,
            fee_tier,
        };
        
        assert!(!table::contains(&factory.pool_registry, pool_key), errors::pool_already_exists());

        // Create the pool
        let pool_uid = object::new(ctx);
        let pool_id = object::uid_to_inner(&pool_uid);
        
        // Create position manager
        let position_manager = lp_position_nft::create_manager(pool_id, ctx);
        
        // Calculate initial LP tokens (geometric mean minus minimum liquidity)
        let initial_lp_tokens = math::calculate_lp_tokens_to_mint(
            coin::value(&ordered_coin_a),
            coin::value(&ordered_coin_b),
            0,
            0,
            0,
        );
        
        let amount_a_final = coin::value(&ordered_coin_a);
        let amount_b_final = coin::value(&ordered_coin_b);
        
        // Create pool with ordered coins
        let mut pool = LiquidityPool<CoinA, CoinB> {
            id: pool_uid,
            reserve_a: coin::into_balance(ordered_coin_a),
            reserve_b: coin::into_balance(ordered_coin_b),
            fee_tier,
            total_supply: initial_lp_tokens + constants::minimum_liquidity(),
            protocol_fees_a: balance::zero(),
            protocol_fees_b: balance::zero(),
            fee_growth_global_a: 0,
            fee_growth_global_b: 0,
            position_manager,
            is_paused: false,
            minimum_liquidity: constants::minimum_liquidity(),
            k_last: (amount_a_final as u128) * (amount_b_final as u128),
        };

        // Mint LP Position NFT for creator
        let position = lp_position_nft::mint(
            &mut pool.position_manager,
            pool_id,
            initial_lp_tokens,
            amount_a_final,
            amount_b_final,
            0,
            0,
            clock,
            ctx,
        );

        // Register pool
        table::add(&mut factory.pool_registry, pool_key, pool_id);
        factory.total_pools = factory.total_pools + 1;

        // Emit event
        events::emit_pool_created(
            pool_id,
            type_name::into_string(ordered_type_a).into_bytes(),
            type_name::into_string(ordered_type_b).into_bytes(),
            fee_tier,
            amount_a_final,
            amount_b_final,
            tx_context::sender(ctx),
        );

        // Share the pool
        transfer::share_object(pool);

        position
    }

    // ============ Liquidity Functions ============

    /// Add liquidity to an existing pool
    public fun add_liquidity<CoinA, CoinB>(
        pool: &mut LiquidityPool<CoinA, CoinB>,
        coin_a: Coin<CoinA>,
        coin_b: Coin<CoinB>,
        min_lp_tokens: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): LPPositionNFT {
        assert!(!pool.is_paused, errors::pool_paused());
        
        let amount_a = coin::value(&coin_a);
        let amount_b = coin::value(&coin_b);
        assert!(amount_a > 0 && amount_b > 0, errors::zero_amount());

        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);

        // Validate ratio is within tolerance
        assert!(
            math::is_within_ratio_tolerance(
                amount_a,
                amount_b,
                reserve_a,
                reserve_b,
                constants::ratio_tolerance(),
            ),
            errors::ratio_out_of_tolerance()
        );

        // Calculate LP tokens to mint
        let lp_tokens = math::calculate_lp_tokens_to_mint(
            amount_a,
            amount_b,
            reserve_a,
            reserve_b,
            pool.total_supply,
        );
        
        assert!(lp_tokens >= min_lp_tokens, errors::slippage_exceeded());

        // Add liquidity to pool
        balance::join(&mut pool.reserve_a, coin::into_balance(coin_a));
        balance::join(&mut pool.reserve_b, coin::into_balance(coin_b));
        pool.total_supply = pool.total_supply + lp_tokens;
        
        // Update K
        pool.k_last = (balance::value(&pool.reserve_a) as u128) * 
                      (balance::value(&pool.reserve_b) as u128);

        // Mint new LP Position NFT
        let pool_id = object::uid_to_inner(&pool.id);
        let position = lp_position_nft::mint(
            &mut pool.position_manager,
            pool_id,
            lp_tokens,
            amount_a,
            amount_b,
            pool.fee_growth_global_a,
            pool.fee_growth_global_b,
            clock,
            ctx,
        );

        // Emit event
        events::emit_liquidity_added(
            pool_id,
            lp_position_nft::id(&position),
            tx_context::sender(ctx),
            amount_a,
            amount_b,
            lp_tokens,
            pool.total_supply,
        );

        position
    }

    /// Add liquidity to an existing position
    public fun add_liquidity_to_position<CoinA, CoinB>(
        pool: &mut LiquidityPool<CoinA, CoinB>,
        position: &mut LPPositionNFT,
        coin_a: Coin<CoinA>,
        coin_b: Coin<CoinB>,
        min_lp_tokens: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        assert!(!pool.is_paused, errors::pool_paused());
        assert!(lp_position_nft::pool_id(position) == object::uid_to_inner(&pool.id), errors::invalid_position_owner());
        
        let amount_a = coin::value(&coin_a);
        let amount_b = coin::value(&coin_b);
        assert!(amount_a > 0 && amount_b > 0, errors::zero_amount());

        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);

        // Validate ratio
        assert!(
            math::is_within_ratio_tolerance(
                amount_a,
                amount_b,
                reserve_a,
                reserve_b,
                constants::ratio_tolerance(),
            ),
            errors::ratio_out_of_tolerance()
        );

        // Calculate LP tokens
        let lp_tokens = math::calculate_lp_tokens_to_mint(
            amount_a,
            amount_b,
            reserve_a,
            reserve_b,
            pool.total_supply,
        );
        
        assert!(lp_tokens >= min_lp_tokens, errors::slippage_exceeded());

        // Update fees before modifying position
        lp_position_nft::update_fees(
            position,
            pool.fee_growth_global_a,
            pool.fee_growth_global_b,
            clock,
        );

        // Add liquidity
        balance::join(&mut pool.reserve_a, coin::into_balance(coin_a));
        balance::join(&mut pool.reserve_b, coin::into_balance(coin_b));
        pool.total_supply = pool.total_supply + lp_tokens;
        pool.k_last = (balance::value(&pool.reserve_a) as u128) * 
                      (balance::value(&pool.reserve_b) as u128);

        // Update position
        lp_position_nft::add_lp_tokens(position, lp_tokens, amount_a, amount_b, clock);

        // Emit event
        events::emit_liquidity_added(
            object::uid_to_inner(&pool.id),
            lp_position_nft::id(position),
            tx_context::sender(ctx),
            amount_a,
            amount_b,
            lp_tokens,
            pool.total_supply,
        );
    }

    /// Remove liquidity from a position
    public fun remove_liquidity<CoinA, CoinB>(
        pool: &mut LiquidityPool<CoinA, CoinB>,
        position: &mut LPPositionNFT,
        lp_tokens_to_remove: u64,
        min_amount_a: u64,
        min_amount_b: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): (Coin<CoinA>, Coin<CoinB>) {
        assert!(lp_position_nft::pool_id(position) == object::uid_to_inner(&pool.id), errors::invalid_position_owner());
        assert!(lp_tokens_to_remove > 0, errors::zero_amount());
        assert!(lp_position_nft::lp_tokens(position) >= lp_tokens_to_remove, errors::insufficient_lp_tokens());

        // Update fees first
        lp_position_nft::update_fees(
            position,
            pool.fee_growth_global_a,
            pool.fee_growth_global_b,
            clock,
        );

        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);

        // Calculate amounts to return
        let (amount_a, amount_b) = math::calculate_liquidity_removal(
            lp_tokens_to_remove,
            reserve_a,
            reserve_b,
            pool.total_supply,
        );

        // Slippage check
        assert!(amount_a >= min_amount_a, errors::slippage_exceeded());
        assert!(amount_b >= min_amount_b, errors::slippage_exceeded());

        // Update pool state
        pool.total_supply = pool.total_supply - lp_tokens_to_remove;
        pool.k_last = ((reserve_a - amount_a) as u128) * ((reserve_b - amount_b) as u128);

        // Update position
        lp_position_nft::remove_lp_tokens(position, lp_tokens_to_remove, clock);

        // Withdraw tokens
        let coin_a = coin::from_balance(balance::split(&mut pool.reserve_a, amount_a), ctx);
        let coin_b = coin::from_balance(balance::split(&mut pool.reserve_b, amount_b), ctx);

        // Emit event
        events::emit_liquidity_removed(
            object::uid_to_inner(&pool.id),
            lp_position_nft::id(position),
            tx_context::sender(ctx),
            amount_a,
            amount_b,
            lp_tokens_to_remove,
            pool.total_supply,
        );

        (coin_a, coin_b)
    }

    /// Remove all liquidity and burn the position NFT
    public fun remove_all_liquidity<CoinA, CoinB>(
        pool: &mut LiquidityPool<CoinA, CoinB>,
        position: LPPositionNFT,
        min_amount_a: u64,
        min_amount_b: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): (Coin<CoinA>, Coin<CoinB>) {
        assert!(lp_position_nft::pool_id(&position) == object::uid_to_inner(&pool.id), errors::invalid_position_owner());
        
        let lp_tokens = lp_position_nft::lp_tokens(&position);
        assert!(lp_tokens > 0, errors::position_empty());

        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);

        // Calculate amounts to return
        let (amount_a, amount_b) = math::calculate_liquidity_removal(
            lp_tokens,
            reserve_a,
            reserve_b,
            pool.total_supply,
        );

        // Slippage check
        assert!(amount_a >= min_amount_a, errors::slippage_exceeded());
        assert!(amount_b >= min_amount_b, errors::slippage_exceeded());

        // Update pool state
        pool.total_supply = pool.total_supply - lp_tokens;
        pool.k_last = ((reserve_a - amount_a) as u128) * ((reserve_b - amount_b) as u128);

        // Withdraw tokens
        let coin_a = coin::from_balance(balance::split(&mut pool.reserve_a, amount_a), ctx);
        let coin_b = coin::from_balance(balance::split(&mut pool.reserve_b, amount_b), ctx);

        // Burn position NFT
        lp_position_nft::burn(&mut pool.position_manager, position, ctx);

        (coin_a, coin_b)
    }

    // ============ Swap Functions ============

    /// Swap token A for token B
    public fun swap_a_for_b<CoinA, CoinB>(
        pool: &mut LiquidityPool<CoinA, CoinB>,
        coin_in: Coin<CoinA>,
        min_amount_out: u64,
        ctx: &mut TxContext,
    ): Coin<CoinB> {
        assert!(!pool.is_paused, errors::pool_paused());
        
        let amount_in = coin::value(&coin_in);
        assert!(amount_in > 0, errors::zero_amount());

        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);

        // Calculate output amount
        let amount_out = math::calculate_output_amount(
            amount_in,
            reserve_a,
            reserve_b,
            pool.fee_tier,
        );
        
        assert!(amount_out >= min_amount_out, errors::slippage_exceeded());
        assert!(amount_out < reserve_b, errors::insufficient_liquidity());

        // Calculate fee
        let fee_amount = math::calculate_fee_amount(amount_in, pool.fee_tier);
        let protocol_fee = fee_amount * constants::protocol_fee_percentage() / constants::basis_points();
        let lp_fee = fee_amount - protocol_fee;

        // Update fee growth for LPs
        if (pool.total_supply > 0) {
            let fee_growth_increment = (lp_fee as u128) * 1000000000000000000u128 / (pool.total_supply as u128);
            pool.fee_growth_global_a = pool.fee_growth_global_a + fee_growth_increment;
        };

        // Add input to reserves
        balance::join(&mut pool.reserve_a, coin::into_balance(coin_in));
        
        // Split protocol fee
        if (protocol_fee > 0) {
            let protocol_fee_balance = balance::split(&mut pool.reserve_a, protocol_fee);
            balance::join(&mut pool.protocol_fees_a, protocol_fee_balance);
        };

        // Extract output
        let coin_out = coin::from_balance(balance::split(&mut pool.reserve_b, amount_out), ctx);

        // Update K
        pool.k_last = (balance::value(&pool.reserve_a) as u128) * 
                      (balance::value(&pool.reserve_b) as u128);

        // Emit event
        events::emit_swap_executed(
            object::uid_to_inner(&pool.id),
            tx_context::sender(ctx),
            amount_in,
            amount_out,
            fee_amount,
            true, // is_a_to_b
            balance::value(&pool.reserve_a),
            balance::value(&pool.reserve_b),
        );

        coin_out
    }

    /// Swap token B for token A
    public fun swap_b_for_a<CoinA, CoinB>(
        pool: &mut LiquidityPool<CoinA, CoinB>,
        coin_in: Coin<CoinB>,
        min_amount_out: u64,
        ctx: &mut TxContext,
    ): Coin<CoinA> {
        assert!(!pool.is_paused, errors::pool_paused());
        
        let amount_in = coin::value(&coin_in);
        assert!(amount_in > 0, errors::zero_amount());

        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);

        // Calculate output amount
        let amount_out = math::calculate_output_amount(
            amount_in,
            reserve_b,
            reserve_a,
            pool.fee_tier,
        );
        
        assert!(amount_out >= min_amount_out, errors::slippage_exceeded());
        assert!(amount_out < reserve_a, errors::insufficient_liquidity());

        // Calculate fee
        let fee_amount = math::calculate_fee_amount(amount_in, pool.fee_tier);
        let protocol_fee = fee_amount * constants::protocol_fee_percentage() / constants::basis_points();
        let lp_fee = fee_amount - protocol_fee;

        // Update fee growth for LPs
        if (pool.total_supply > 0) {
            let fee_growth_increment = (lp_fee as u128) * 1000000000000000000u128 / (pool.total_supply as u128);
            pool.fee_growth_global_b = pool.fee_growth_global_b + fee_growth_increment;
        };

        // Add input to reserves
        balance::join(&mut pool.reserve_b, coin::into_balance(coin_in));
        
        // Split protocol fee
        if (protocol_fee > 0) {
            let protocol_fee_balance = balance::split(&mut pool.reserve_b, protocol_fee);
            balance::join(&mut pool.protocol_fees_b, protocol_fee_balance);
        };

        // Extract output
        let coin_out = coin::from_balance(balance::split(&mut pool.reserve_a, amount_out), ctx);

        // Update K
        pool.k_last = (balance::value(&pool.reserve_a) as u128) * 
                      (balance::value(&pool.reserve_b) as u128);

        // Emit event
        events::emit_swap_executed(
            object::uid_to_inner(&pool.id),
            tx_context::sender(ctx),
            amount_in,
            amount_out,
            fee_amount,
            false, // is_a_to_b
            balance::value(&pool.reserve_a),
            balance::value(&pool.reserve_b),
        );

        coin_out
    }

    // ============ View Functions ============

    /// Get pool reserves
    public fun get_reserves<CoinA, CoinB>(pool: &LiquidityPool<CoinA, CoinB>): (u64, u64) {
        (balance::value(&pool.reserve_a), balance::value(&pool.reserve_b))
    }

    /// Get pool fee tier
    public fun get_fee_tier<CoinA, CoinB>(pool: &LiquidityPool<CoinA, CoinB>): u64 {
        pool.fee_tier
    }

    /// Get total LP supply
    public fun get_total_supply<CoinA, CoinB>(pool: &LiquidityPool<CoinA, CoinB>): u64 {
        pool.total_supply
    }

    /// Get pool K value
    public fun get_k<CoinA, CoinB>(pool: &LiquidityPool<CoinA, CoinB>): u128 {
        pool.k_last
    }

    /// Get fee growth globals
    public fun get_fee_growth<CoinA, CoinB>(pool: &LiquidityPool<CoinA, CoinB>): (u128, u128) {
        (pool.fee_growth_global_a, pool.fee_growth_global_b)
    }

    /// Get protocol fees accumulated
    public fun get_protocol_fees<CoinA, CoinB>(pool: &LiquidityPool<CoinA, CoinB>): (u64, u64) {
        (balance::value(&pool.protocol_fees_a), balance::value(&pool.protocol_fees_b))
    }

    /// Check if pool is paused
    public fun is_paused<CoinA, CoinB>(pool: &LiquidityPool<CoinA, CoinB>): bool {
        pool.is_paused
    }

    /// Get pool ID
    public fun pool_id<CoinA, CoinB>(pool: &LiquidityPool<CoinA, CoinB>): ID {
        object::uid_to_inner(&pool.id)
    }

    /// Get factory total pools
    public fun get_total_pools(factory: &PoolFactory): u64 {
        factory.total_pools
    }

    /// Check if pool exists
    public fun pool_exists<CoinA, CoinB>(factory: &PoolFactory, fee_tier: u64): bool {
        let type_a = type_name::get<CoinA>();
        let type_b = type_name::get<CoinB>();
        
        let (ordered_a, ordered_b) = order_types(type_a, type_b);
        
        let pool_key = PoolKey {
            token_a_type: ordered_a,
            token_b_type: ordered_b,
            fee_tier,
        };
        
        table::contains(&factory.pool_registry, pool_key)
    }

    /// Calculate expected output for a swap (A to B)
    public fun get_amount_out_a_to_b<CoinA, CoinB>(
        pool: &LiquidityPool<CoinA, CoinB>,
        amount_in: u64,
    ): u64 {
        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);
        
        math::calculate_output_amount(amount_in, reserve_a, reserve_b, pool.fee_tier)
    }

    /// Calculate expected output for a swap (B to A)
    public fun get_amount_out_b_to_a<CoinA, CoinB>(
        pool: &LiquidityPool<CoinA, CoinB>,
        amount_in: u64,
    ): u64 {
        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);
        
        math::calculate_output_amount(amount_in, reserve_b, reserve_a, pool.fee_tier)
    }

    /// Calculate price impact for a swap
    public fun get_price_impact<CoinA, CoinB>(
        pool: &LiquidityPool<CoinA, CoinB>,
        amount_in: u64,
        is_a_to_b: bool,
    ): u64 {
        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);
        
        if (is_a_to_b) {
            math::calculate_price_impact(amount_in, reserve_a, reserve_b, pool.fee_tier)
        } else {
            math::calculate_price_impact(amount_in, reserve_b, reserve_a, pool.fee_tier)
        }
    }

    // ============ Admin Functions ============

    /// Pause/unpause pool
    public fun set_pool_paused<CoinA, CoinB>(
        _: &PoolFactoryAdminCap,
        pool: &mut LiquidityPool<CoinA, CoinB>,
        paused: bool,
    ) {
        pool.is_paused = paused;
        events::emit_pool_status_changed(object::uid_to_inner(&pool.id), paused);
    }

    /// Pause/unpause pool creation
    public fun set_creation_paused(
        _: &PoolFactoryAdminCap,
        factory: &mut PoolFactory,
        paused: bool,
    ) {
        factory.creation_paused = paused;
    }

    /// Update protocol fee recipient
    public fun set_protocol_fee_recipient(
        _: &PoolFactoryAdminCap,
        factory: &mut PoolFactory,
        recipient: address,
    ) {
        factory.protocol_fee_recipient = recipient;
    }

    /// Collect protocol fees
    public fun collect_protocol_fees<CoinA, CoinB>(
        _: &PoolFactoryAdminCap,
        pool: &mut LiquidityPool<CoinA, CoinB>,
        factory: &PoolFactory,
        ctx: &mut TxContext,
    ): (Coin<CoinA>, Coin<CoinB>) {
        let amount_a = balance::value(&pool.protocol_fees_a);
        let amount_b = balance::value(&pool.protocol_fees_b);
        
        let coin_a = coin::from_balance(
            balance::withdraw_all(&mut pool.protocol_fees_a),
            ctx,
        );
        let coin_b = coin::from_balance(
            balance::withdraw_all(&mut pool.protocol_fees_b),
            ctx,
        );

        events::emit_protocol_fees_collected(
            object::uid_to_inner(&pool.id),
            amount_a,
            amount_b,
            factory.protocol_fee_recipient,
        );

        (coin_a, coin_b)
    }

    // ============ Helper Functions ============

    /// Compare two byte vectors lexicographically
    /// Returns true if a < b
    fun compare_bytes(a: &vector<u8>, b: &vector<u8>): bool {
        let len_a = vector::length(a);
        let len_b = vector::length(b);
        let min_len = if (len_a < len_b) { len_a } else { len_b };
        
        let mut i = 0;
        while (i < min_len) {
            let byte_a = *vector::borrow(a, i);
            let byte_b = *vector::borrow(b, i);
            if (byte_a < byte_b) {
                return true
            };
            if (byte_a > byte_b) {
                return false
            };
            i = i + 1;
        };
        
        // If all compared bytes are equal, shorter string is "less"
        len_a < len_b
    }

    /// Order types lexicographically for consistent pool keys
    fun order_types(type_a: TypeName, type_b: TypeName): (TypeName, TypeName) {
        let name_a = type_name::into_string(type_a);
        let name_b = type_name::into_string(type_b);
        
        let bytes_a = std::ascii::into_bytes(name_a);
        let bytes_b = std::ascii::into_bytes(name_b);
        
        if (compare_bytes(&bytes_a, &bytes_b)) {
            (type_a, type_b)
        } else {
            (type_b, type_a)
        }
    }

    /// Order types and coins together
    fun order_types_and_coins<CoinA, CoinB>(
        type_a: TypeName,
        type_b: TypeName,
        coin_a: Coin<CoinA>,
        coin_b: Coin<CoinB>,
    ): (TypeName, TypeName, Coin<CoinA>, Coin<CoinB>) {
        let name_a = type_name::into_string(type_a);
        let name_b = type_name::into_string(type_b);
        
        let bytes_a = std::ascii::into_bytes(name_a);
        let bytes_b = std::ascii::into_bytes(name_b);
        
        // Types are already generic CoinA/CoinB, so we maintain order in the pool
        // The ordering is done on the type names for registry lookup
        if (compare_bytes(&bytes_a, &bytes_b)) {
            (type_a, type_b, coin_a, coin_b)
        } else {
            (type_b, type_a, coin_a, coin_b)
        }
    }

    // ============ Test Functions ============

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }
}

