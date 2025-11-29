/// Stable Swap Pool Contract
/// Optimized AMM for stable asset pairs with lower slippage
/// Uses StableSwap invariant: An^n * sum(x_i) + D = ADn^n + D^(n+1) / (n^n * prod(x_i))
module sui_amm::stable_swap_pool {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::clock::Clock;
    
    use sui_amm::events;
    use sui_amm::errors;
    use sui_amm::constants;
    use sui_amm::math;
    use sui_amm::lp_position_nft::{Self, LPPositionNFT, LPPositionManager};

    // ============ Constants ============

    /// Number of iterations for Newton's method convergence
    const MAX_ITERATIONS: u64 = 255;
    
    /// Precision for stable swap calculations
    const PRECISION: u128 = 1000000000000000000; // 10^18

    // ============ Structs ============

    /// Admin capability for stable swap pools
    public struct StableSwapAdminCap has key, store {
        id: UID,
    }

    /// Stable Swap Pool optimized for stable pairs
    public struct StableSwapPool<phantom CoinA, phantom CoinB> has key, store {
        id: UID,
        /// Reserve of token A
        reserve_a: Balance<CoinA>,
        /// Reserve of token B
        reserve_b: Balance<CoinB>,
        /// Amplification coefficient (A)
        amplification: u64,
        /// Fee tier in basis points (typically lower than standard pools)
        fee_tier: u64,
        /// Total LP token supply
        total_supply: u64,
        /// Protocol fees accumulated (token A)
        protocol_fees_a: Balance<CoinA>,
        /// Protocol fees accumulated (token B)
        protocol_fees_b: Balance<CoinB>,
        /// Global fee growth per LP token for token A
        fee_growth_global_a: u128,
        /// Global fee growth per LP token for token B
        fee_growth_global_b: u128,
        /// LP Position Manager
        position_manager: LPPositionManager,
        /// Whether the pool is paused
        is_paused: bool,
        /// Cached D value (invariant)
        d_last: u128,
        /// Future amplification (for ramping)
        future_amplification: u64,
        /// Timestamp when ramp started
        ramp_start_time: u64,
        /// Timestamp when ramp ends
        ramp_end_time: u64,
    }

    // ============ Init ============

    fun init(ctx: &mut TxContext) {
        let admin_cap = StableSwapAdminCap {
            id: object::new(ctx),
        };
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    // ============ Pool Creation ============

    /// Create a new stable swap pool
    public fun create_stable_pool<CoinA, CoinB>(
        coin_a: Coin<CoinA>,
        coin_b: Coin<CoinB>,
        amplification: u64,
        fee_tier: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): LPPositionNFT {
        // Validate inputs
        assert!(amplification >= constants::min_amplification(), errors::invalid_amplification());
        assert!(amplification <= constants::max_amplification(), errors::invalid_amplification());
        assert!(fee_tier <= constants::fee_tier_medium(), errors::invalid_fee_tier()); // Stable pools should have lower fees
        
        let amount_a = coin::value(&coin_a);
        let amount_b = coin::value(&coin_b);
        assert!(amount_a > 0 && amount_b > 0, errors::zero_amount());

        // Create pool
        let pool_uid = object::new(ctx);
        let pool_id = object::uid_to_inner(&pool_uid);
        
        // Create position manager
        let position_manager = lp_position_nft::create_manager(pool_id, ctx);
        
        // Calculate initial D (invariant)
        let d = calculate_d(amount_a, amount_b, amplification);
        
        // Initial LP tokens = D (for stable pools)
        let initial_lp_tokens = ((d / PRECISION) as u64);
        assert!(initial_lp_tokens > constants::minimum_liquidity(), errors::below_minimum_liquidity());
        let lp_tokens_for_provider = initial_lp_tokens - constants::minimum_liquidity();
        
        let mut pool = StableSwapPool<CoinA, CoinB> {
            id: pool_uid,
            reserve_a: coin::into_balance(coin_a),
            reserve_b: coin::into_balance(coin_b),
            amplification,
            fee_tier,
            total_supply: initial_lp_tokens,
            protocol_fees_a: balance::zero(),
            protocol_fees_b: balance::zero(),
            fee_growth_global_a: 0,
            fee_growth_global_b: 0,
            position_manager,
            is_paused: false,
            d_last: d,
            future_amplification: amplification,
            ramp_start_time: 0,
            ramp_end_time: 0,
        };

        // Mint LP Position NFT for creator
        let position = lp_position_nft::mint(
            &mut pool.position_manager,
            pool_id,
            lp_tokens_for_provider,
            amount_a,
            amount_b,
            0,
            0,
            clock,
            ctx,
        );

        transfer::share_object(pool);

        position
    }

    // ============ Liquidity Functions ============

    /// Add liquidity to stable pool
    public fun add_liquidity<CoinA, CoinB>(
        pool: &mut StableSwapPool<CoinA, CoinB>,
        coin_a: Coin<CoinA>,
        coin_b: Coin<CoinB>,
        min_lp_tokens: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): LPPositionNFT {
        assert!(!pool.is_paused, errors::pool_paused());
        
        let amount_a = coin::value(&coin_a);
        let amount_b = coin::value(&coin_b);
        
        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);
        
        // Calculate D before
        let d_before = calculate_d(reserve_a, reserve_b, get_current_amplification(pool));
        
        // Add liquidity
        balance::join(&mut pool.reserve_a, coin::into_balance(coin_a));
        balance::join(&mut pool.reserve_b, coin::into_balance(coin_b));
        
        // Calculate D after
        let new_reserve_a = balance::value(&pool.reserve_a);
        let new_reserve_b = balance::value(&pool.reserve_b);
        let d_after = calculate_d(new_reserve_a, new_reserve_b, get_current_amplification(pool));
        
        // Calculate LP tokens to mint
        let lp_tokens = if (pool.total_supply == 0) {
            ((d_after / PRECISION) as u64)
        } else {
            let d_diff = d_after - d_before;
            (((d_diff * (pool.total_supply as u128)) / d_before) as u64)
        };
        
        assert!(lp_tokens >= min_lp_tokens, errors::slippage_exceeded());
        
        pool.total_supply = pool.total_supply + lp_tokens;
        pool.d_last = d_after;
        
        // Mint position NFT
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

    /// Remove liquidity from stable pool
    public fun remove_liquidity<CoinA, CoinB>(
        pool: &mut StableSwapPool<CoinA, CoinB>,
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

        // Calculate proportional amounts
        let amount_a = ((lp_tokens_to_remove as u128) * (reserve_a as u128) / (pool.total_supply as u128) as u64);
        let amount_b = ((lp_tokens_to_remove as u128) * (reserve_b as u128) / (pool.total_supply as u128) as u64);

        assert!(amount_a >= min_amount_a, errors::slippage_exceeded());
        assert!(amount_b >= min_amount_b, errors::slippage_exceeded());

        // Update pool state
        pool.total_supply = pool.total_supply - lp_tokens_to_remove;
        
        // Update D
        let new_reserve_a = reserve_a - amount_a;
        let new_reserve_b = reserve_b - amount_b;
        pool.d_last = calculate_d(new_reserve_a, new_reserve_b, get_current_amplification(pool));

        // Update position
        lp_position_nft::remove_lp_tokens(position, lp_tokens_to_remove, clock);

        // Withdraw tokens
        let coin_a = coin::from_balance(balance::split(&mut pool.reserve_a, amount_a), ctx);
        let coin_b = coin::from_balance(balance::split(&mut pool.reserve_b, amount_b), ctx);

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

    // ============ Swap Functions ============

    /// Swap token A for token B using stable swap curve
    public fun swap_a_for_b<CoinA, CoinB>(
        pool: &mut StableSwapPool<CoinA, CoinB>,
        coin_in: Coin<CoinA>,
        min_amount_out: u64,
        ctx: &mut TxContext,
    ): Coin<CoinB> {
        assert!(!pool.is_paused, errors::pool_paused());
        
        let amount_in = coin::value(&coin_in);
        assert!(amount_in > 0, errors::zero_amount());

        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);
        let amp = get_current_amplification(pool);

        // Calculate output using stable swap formula
        let amount_out = calculate_swap_output(
            amount_in,
            reserve_a,
            reserve_b,
            amp,
            pool.fee_tier,
            true, // a_to_b
        );
        
        assert!(amount_out >= min_amount_out, errors::slippage_exceeded());
        assert!(amount_out < reserve_b, errors::insufficient_liquidity());

        // Calculate and distribute fees
        let fee_amount = math::calculate_fee_amount(amount_in, pool.fee_tier);
        let protocol_fee = fee_amount * constants::protocol_fee_percentage() / constants::basis_points();
        let lp_fee = fee_amount - protocol_fee;

        // Update fee growth
        if (pool.total_supply > 0) {
            let fee_growth_increment = (lp_fee as u128) * PRECISION / (pool.total_supply as u128);
            pool.fee_growth_global_a = pool.fee_growth_global_a + fee_growth_increment;
        };

        // Add input to reserves
        balance::join(&mut pool.reserve_a, coin::into_balance(coin_in));
        
        // Protocol fee
        if (protocol_fee > 0) {
            let protocol_fee_balance = balance::split(&mut pool.reserve_a, protocol_fee);
            balance::join(&mut pool.protocol_fees_a, protocol_fee_balance);
        };

        // Extract output
        let coin_out = coin::from_balance(balance::split(&mut pool.reserve_b, amount_out), ctx);

        // Update D
        pool.d_last = calculate_d(
            balance::value(&pool.reserve_a),
            balance::value(&pool.reserve_b),
            amp,
        );

        events::emit_swap_executed(
            object::uid_to_inner(&pool.id),
            tx_context::sender(ctx),
            amount_in,
            amount_out,
            fee_amount,
            true,
            balance::value(&pool.reserve_a),
            balance::value(&pool.reserve_b),
        );

        coin_out
    }

    /// Swap token B for token A using stable swap curve
    public fun swap_b_for_a<CoinA, CoinB>(
        pool: &mut StableSwapPool<CoinA, CoinB>,
        coin_in: Coin<CoinB>,
        min_amount_out: u64,
        ctx: &mut TxContext,
    ): Coin<CoinA> {
        assert!(!pool.is_paused, errors::pool_paused());
        
        let amount_in = coin::value(&coin_in);
        assert!(amount_in > 0, errors::zero_amount());

        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);
        let amp = get_current_amplification(pool);

        // Calculate output using stable swap formula
        let amount_out = calculate_swap_output(
            amount_in,
            reserve_b,
            reserve_a,
            amp,
            pool.fee_tier,
            false, // b_to_a
        );
        
        assert!(amount_out >= min_amount_out, errors::slippage_exceeded());
        assert!(amount_out < reserve_a, errors::insufficient_liquidity());

        // Calculate and distribute fees
        let fee_amount = math::calculate_fee_amount(amount_in, pool.fee_tier);
        let protocol_fee = fee_amount * constants::protocol_fee_percentage() / constants::basis_points();
        let lp_fee = fee_amount - protocol_fee;

        // Update fee growth
        if (pool.total_supply > 0) {
            let fee_growth_increment = (lp_fee as u128) * PRECISION / (pool.total_supply as u128);
            pool.fee_growth_global_b = pool.fee_growth_global_b + fee_growth_increment;
        };

        // Add input to reserves
        balance::join(&mut pool.reserve_b, coin::into_balance(coin_in));
        
        // Protocol fee
        if (protocol_fee > 0) {
            let protocol_fee_balance = balance::split(&mut pool.reserve_b, protocol_fee);
            balance::join(&mut pool.protocol_fees_b, protocol_fee_balance);
        };

        // Extract output
        let coin_out = coin::from_balance(balance::split(&mut pool.reserve_a, amount_out), ctx);

        // Update D
        pool.d_last = calculate_d(
            balance::value(&pool.reserve_a),
            balance::value(&pool.reserve_b),
            amp,
        );

        events::emit_swap_executed(
            object::uid_to_inner(&pool.id),
            tx_context::sender(ctx),
            amount_in,
            amount_out,
            fee_amount,
            false,
            balance::value(&pool.reserve_a),
            balance::value(&pool.reserve_b),
        );

        coin_out
    }

    // ============ Stable Swap Math ============

    /// Calculate D (invariant) for stable swap
    /// Uses Newton's method to solve: A * n^n * sum(x_i) + D = A * D * n^n + D^(n+1) / (n^n * prod(x_i))
    /// For n=2: A * 4 * (x + y) + D = A * D * 4 + D^3 / (4 * x * y)
    fun calculate_d(reserve_a: u64, reserve_b: u64, amplification: u64): u128 {
        let x = (reserve_a as u128) * PRECISION;
        let y = (reserve_b as u128) * PRECISION;
        let s = x + y;
        
        if (s == 0) {
            return 0
        };
        
        let a = (amplification as u128);
        let ann = a * 4; // A * n^n where n=2
        
        let mut d = s;
        let mut d_prev: u128;
        
        let mut i = 0;
        while (i < MAX_ITERATIONS) {
            // D^3 / (4 * x * y)
            let d_p = d * d * d / (4 * x * y / PRECISION);
            
            d_prev = d;
            
            // D = (A * n^n * S + n * D_P) * D / ((A * n^n - 1) * D + (n + 1) * D_P)
            // For n=2: D = (4A * S + 2 * D_P) * D / ((4A - 1) * D + 3 * D_P)
            let numerator = (ann * s / PRECISION + 2 * d_p) * d;
            let denominator = (ann - 1) * d + 3 * d_p;
            
            if (denominator == 0) {
                break
            };
            
            d = numerator / denominator;
            
            // Check convergence
            let diff = if (d > d_prev) { d - d_prev } else { d_prev - d };
            if (diff <= 1) {
                break
            };
            
            i = i + 1;
        };
        
        d
    }

    /// Calculate y given x and D for stable swap
    /// Solves for y in: A * 4 * (x + y) + D = A * D * 4 + D^3 / (4 * x * y)
    fun calculate_y(x: u128, d: u128, amplification: u64): u128 {
        let a = (amplification as u128);
        let ann = a * 4;
        
        // c = D^3 / (4 * x * A * n^n)
        let c = d * d * d / (4 * x * ann);
        
        // b = x + D / (A * n^n) - D
        let b = x + d / ann;
        
        let mut y = d;
        let mut y_prev: u128;
        
        let mut i = 0;
        while (i < MAX_ITERATIONS) {
            y_prev = y;
            
            // y = (y^2 + c) / (2 * y + b - D)
            let numerator = y * y + c;
            let denominator = 2 * y + b;
            
            if (denominator <= d) {
                break
            };
            
            y = numerator / (denominator - d);
            
            // Check convergence
            let diff = if (y > y_prev) { y - y_prev } else { y_prev - y };
            if (diff <= 1) {
                break
            };
            
            i = i + 1;
        };
        
        y
    }

    /// Calculate swap output amount using stable swap formula
    fun calculate_swap_output(
        amount_in: u64,
        reserve_in: u64,
        reserve_out: u64,
        amplification: u64,
        fee_tier: u64,
        _is_a_to_b: bool,
    ): u64 {
        // Apply fee to input
        let amount_in_after_fee = amount_in - math::calculate_fee_amount(amount_in, fee_tier);
        
        // Scale to precision
        let x = (reserve_in as u128) * PRECISION;
        let y = (reserve_out as u128) * PRECISION;
        
        // Calculate D
        let d = calculate_d(reserve_in, reserve_out, amplification);
        
        // New x after swap
        let new_x = x + (amount_in_after_fee as u128) * PRECISION;
        
        // Calculate new y
        let new_y = calculate_y(new_x / PRECISION, d, amplification);
        
        // Output amount
        let dy = y - new_y * PRECISION;
        
        ((dy / PRECISION) as u64)
    }

    // ============ Amplification Ramping ============

    /// Get current amplification coefficient (considering ramping)
    public fun get_current_amplification<CoinA, CoinB>(pool: &StableSwapPool<CoinA, CoinB>): u64 {
        // For simplicity, return current amplification
        // In production, implement time-based ramping
        pool.amplification
    }

    /// Start ramping amplification coefficient
    public fun ramp_amplification<CoinA, CoinB>(
        _: &StableSwapAdminCap,
        pool: &mut StableSwapPool<CoinA, CoinB>,
        new_amplification: u64,
        ramp_duration: u64,
        clock: &Clock,
    ) {
        assert!(new_amplification >= constants::min_amplification(), errors::invalid_amplification());
        assert!(new_amplification <= constants::max_amplification(), errors::invalid_amplification());
        
        let current_time = sui::clock::timestamp_ms(clock);
        
        pool.future_amplification = new_amplification;
        pool.ramp_start_time = current_time;
        pool.ramp_end_time = current_time + ramp_duration;
    }

    /// Stop ramping and set current amplification
    public fun stop_ramp<CoinA, CoinB>(
        _: &StableSwapAdminCap,
        pool: &mut StableSwapPool<CoinA, CoinB>,
    ) {
        pool.amplification = get_current_amplification(pool);
        pool.future_amplification = pool.amplification;
        pool.ramp_end_time = 0;
    }

    // ============ View Functions ============

    /// Get pool reserves
    public fun get_reserves<CoinA, CoinB>(pool: &StableSwapPool<CoinA, CoinB>): (u64, u64) {
        (balance::value(&pool.reserve_a), balance::value(&pool.reserve_b))
    }

    /// Get amplification coefficient
    public fun get_amplification<CoinA, CoinB>(pool: &StableSwapPool<CoinA, CoinB>): u64 {
        pool.amplification
    }

    /// Get fee tier
    public fun get_fee_tier<CoinA, CoinB>(pool: &StableSwapPool<CoinA, CoinB>): u64 {
        pool.fee_tier
    }

    /// Get total supply
    public fun get_total_supply<CoinA, CoinB>(pool: &StableSwapPool<CoinA, CoinB>): u64 {
        pool.total_supply
    }

    /// Get D (invariant)
    public fun get_d<CoinA, CoinB>(pool: &StableSwapPool<CoinA, CoinB>): u128 {
        pool.d_last
    }

    /// Get expected output for swap (A to B)
    public fun get_amount_out_a_to_b<CoinA, CoinB>(
        pool: &StableSwapPool<CoinA, CoinB>,
        amount_in: u64,
    ): u64 {
        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);
        
        calculate_swap_output(
            amount_in,
            reserve_a,
            reserve_b,
            get_current_amplification(pool),
            pool.fee_tier,
            true,
        )
    }

    /// Get expected output for swap (B to A)
    public fun get_amount_out_b_to_a<CoinA, CoinB>(
        pool: &StableSwapPool<CoinA, CoinB>,
        amount_in: u64,
    ): u64 {
        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);
        
        calculate_swap_output(
            amount_in,
            reserve_b,
            reserve_a,
            get_current_amplification(pool),
            pool.fee_tier,
            false,
        )
    }

    /// Calculate virtual price (D / total_supply)
    public fun get_virtual_price<CoinA, CoinB>(pool: &StableSwapPool<CoinA, CoinB>): u128 {
        if (pool.total_supply == 0) {
            return PRECISION
        };
        pool.d_last * PRECISION / (pool.total_supply as u128)
    }

    // ============ Admin Functions ============

    /// Pause/unpause pool
    public fun set_paused<CoinA, CoinB>(
        _: &StableSwapAdminCap,
        pool: &mut StableSwapPool<CoinA, CoinB>,
        paused: bool,
    ) {
        pool.is_paused = paused;
        events::emit_pool_status_changed(object::uid_to_inner(&pool.id), paused);
    }

    /// Collect protocol fees
    public fun collect_protocol_fees<CoinA, CoinB>(
        _: &StableSwapAdminCap,
        pool: &mut StableSwapPool<CoinA, CoinB>,
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
            tx_context::sender(ctx),
        );

        (coin_a, coin_b)
    }

    // ============ Test Functions ============

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }
}

