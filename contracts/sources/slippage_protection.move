/// Slippage Protection Contract
/// Manages slippage calculation, protection mechanisms, and price limits
#[allow(unused_use, duplicate_alias)]
module sui_amm::slippage_protection {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};
    
    use sui_amm::errors;
    use sui_amm::math;
    use sui_amm::pool_factory::{Self, LiquidityPool};

    // ============ Constants ============

    /// Default slippage tolerance (0.5% = 50 basis points)
    const DEFAULT_SLIPPAGE_TOLERANCE: u64 = 50;
    
    /// Maximum slippage tolerance (50% = 5000 basis points)
    const MAX_SLIPPAGE_TOLERANCE: u64 = 5000;
    
    /// Default transaction deadline (30 minutes in milliseconds)
    const DEFAULT_DEADLINE: u64 = 1800000;
    
    /// Maximum price impact allowed (10% = 1000 basis points)
    const MAX_PRICE_IMPACT: u64 = 1000;

    // ============ Structs ============

    /// Slippage protection settings (shared object)
    public struct SlippageProtectionSettings has key {
        id: UID,
        /// Default slippage tolerance in basis points
        default_slippage_tolerance: u64,
        /// Maximum allowed slippage tolerance
        max_slippage_tolerance: u64,
        /// Default transaction deadline in milliseconds
        default_deadline: u64,
        /// Maximum allowed price impact
        max_price_impact: u64,
        /// Whether price impact protection is enabled globally
        price_impact_protection_enabled: bool,
    }

    /// User-specific slippage settings
    public struct UserSlippageSettings has key, store {
        id: UID,
        /// User's address
        user: address,
        /// User's slippage tolerance in basis points
        slippage_tolerance: u64,
        /// User's preferred deadline in milliseconds
        deadline: u64,
        /// Whether to use price impact protection
        use_price_impact_protection: bool,
        /// Maximum price impact user will accept
        max_price_impact: u64,
    }

    /// Price limit order
    public struct PriceLimitOrder has key, store {
        id: UID,
        /// Pool ID
        pool_id: ID,
        /// Order creator
        creator: address,
        /// Input amount
        amount_in: u64,
        /// Minimum price (output/input ratio * 10000)
        min_price: u64,
        /// Whether it's A to B swap
        is_a_to_b: bool,
        /// Order deadline
        deadline: u64,
        /// Whether order is active
        is_active: bool,
    }

    /// Swap parameters validated with slippage protection
    public struct ValidatedSwapParams has drop {
        /// Minimum output amount after slippage
        min_amount_out: u64,
        /// Transaction deadline
        deadline: u64,
        /// Calculated price impact in basis points
        price_impact: u64,
        /// Whether the swap is valid
        is_valid: bool,
    }

    // ============ Init ============

    fun init(ctx: &mut TxContext) {
        let settings = SlippageProtectionSettings {
            id: object::new(ctx),
            default_slippage_tolerance: DEFAULT_SLIPPAGE_TOLERANCE,
            max_slippage_tolerance: MAX_SLIPPAGE_TOLERANCE,
            default_deadline: DEFAULT_DEADLINE,
            max_price_impact: MAX_PRICE_IMPACT,
            price_impact_protection_enabled: true,
        };

        transfer::share_object(settings);
    }

    // ============ User Settings Functions ============

    /// Create user-specific slippage settings
    public fun create_user_settings(
        slippage_tolerance: u64,
        deadline: u64,
        max_price_impact: u64,
        ctx: &mut TxContext,
    ): UserSlippageSettings {
        assert!(slippage_tolerance <= MAX_SLIPPAGE_TOLERANCE, errors::slippage_exceeded());
        
        UserSlippageSettings {
            id: object::new(ctx),
            user: tx_context::sender(ctx),
            slippage_tolerance,
            deadline,
            use_price_impact_protection: true,
            max_price_impact,
        }
    }

    /// Update user slippage tolerance
    public fun update_slippage_tolerance(
        settings: &mut UserSlippageSettings,
        new_tolerance: u64,
    ) {
        assert!(new_tolerance <= MAX_SLIPPAGE_TOLERANCE, errors::slippage_exceeded());
        settings.slippage_tolerance = new_tolerance;
    }

    /// Update user deadline preference
    public fun update_deadline(
        settings: &mut UserSlippageSettings,
        new_deadline: u64,
    ) {
        settings.deadline = new_deadline;
    }

    /// Update price impact protection
    public fun update_price_impact_protection(
        settings: &mut UserSlippageSettings,
        enabled: bool,
        max_impact: u64,
    ) {
        settings.use_price_impact_protection = enabled;
        settings.max_price_impact = max_impact;
    }

    // ============ Slippage Calculation Functions ============

    /// Calculate minimum output with slippage protection
    public fun calculate_min_output(
        expected_output: u64,
        slippage_tolerance_bps: u64,
    ): u64 {
        // min_output = expected_output * (10000 - slippage_tolerance) / 10000
        let min_output = (expected_output as u128) * ((10000 - slippage_tolerance_bps) as u128) / 10000;
        (min_output as u64)
    }

    /// Calculate maximum input with slippage protection
    public fun calculate_max_input(
        expected_input: u64,
        slippage_tolerance_bps: u64,
    ): u64 {
        // max_input = expected_input * (10000 + slippage_tolerance) / 10000
        let max_input = (expected_input as u128) * ((10000 + slippage_tolerance_bps) as u128) / 10000;
        (max_input as u64)
    }

    /// Calculate price impact for a swap
    public fun calculate_price_impact<CoinA, CoinB>(
        pool: &LiquidityPool<CoinA, CoinB>,
        amount_in: u64,
        is_a_to_b: bool,
    ): u64 {
        pool_factory::get_price_impact(pool, amount_in, is_a_to_b)
    }

    /// Validate swap parameters
    public fun validate_swap<CoinA, CoinB>(
        pool: &LiquidityPool<CoinA, CoinB>,
        amount_in: u64,
        min_amount_out: u64,
        deadline: u64,
        settings: &SlippageProtectionSettings,
        clock: &Clock,
        is_a_to_b: bool,
    ): ValidatedSwapParams {
        let current_time = clock::timestamp_ms(clock);
        
        // Check deadline
        let deadline_valid = deadline == 0 || current_time <= deadline;
        
        // Calculate expected output
        let expected_output = if (is_a_to_b) {
            pool_factory::get_amount_out_a_to_b(pool, amount_in)
        } else {
            pool_factory::get_amount_out_b_to_a(pool, amount_in)
        };
        
        // Check minimum output
        let output_valid = expected_output >= min_amount_out;
        
        // Calculate price impact
        let price_impact = pool_factory::get_price_impact(pool, amount_in, is_a_to_b);
        
        // Check price impact
        let price_impact_valid = !settings.price_impact_protection_enabled || 
                                  price_impact <= settings.max_price_impact;
        
        ValidatedSwapParams {
            min_amount_out,
            deadline,
            price_impact,
            is_valid: deadline_valid && output_valid && price_impact_valid,
        }
    }

    /// Validate swap with user settings
    public fun validate_swap_with_user_settings<CoinA, CoinB>(
        pool: &LiquidityPool<CoinA, CoinB>,
        amount_in: u64,
        user_settings: &UserSlippageSettings,
        clock: &Clock,
        is_a_to_b: bool,
    ): ValidatedSwapParams {
        let current_time = clock::timestamp_ms(clock);
        let deadline = current_time + user_settings.deadline;
        
        // Calculate expected output
        let expected_output = if (is_a_to_b) {
            pool_factory::get_amount_out_a_to_b(pool, amount_in)
        } else {
            pool_factory::get_amount_out_b_to_a(pool, amount_in)
        };
        
        // Calculate minimum output with user's slippage tolerance
        let min_amount_out = calculate_min_output(expected_output, user_settings.slippage_tolerance);
        
        // Calculate price impact
        let price_impact = pool_factory::get_price_impact(pool, amount_in, is_a_to_b);
        
        // Check price impact if protection is enabled
        let price_impact_valid = !user_settings.use_price_impact_protection || 
                                  price_impact <= user_settings.max_price_impact;
        
        ValidatedSwapParams {
            min_amount_out,
            deadline,
            price_impact,
            is_valid: price_impact_valid,
        }
    }

    // ============ Deadline Functions ============

    /// Check if deadline has passed
    public fun is_deadline_passed(deadline: u64, clock: &Clock): bool {
        if (deadline == 0) {
            return false // No deadline set
        };
        clock::timestamp_ms(clock) > deadline
    }

    /// Assert deadline not passed
    public fun assert_deadline_not_passed(deadline: u64, clock: &Clock) {
        assert!(!is_deadline_passed(deadline, clock), errors::deadline_exceeded());
    }

    /// Calculate deadline from current time
    public fun calculate_deadline(duration_ms: u64, clock: &Clock): u64 {
        clock::timestamp_ms(clock) + duration_ms
    }

    // ============ Price Limit Order Functions ============

    /// Create a price limit order
    public fun create_price_limit_order<CoinA, CoinB>(
        pool: &LiquidityPool<CoinA, CoinB>,
        amount_in: u64,
        min_price: u64,
        is_a_to_b: bool,
        deadline_duration: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): PriceLimitOrder {
        assert!(amount_in > 0, errors::zero_amount());
        
        let pool_id = pool_factory::pool_id(pool);
        let deadline = clock::timestamp_ms(clock) + deadline_duration;
        
        PriceLimitOrder {
            id: object::new(ctx),
            pool_id,
            creator: tx_context::sender(ctx),
            amount_in,
            min_price,
            is_a_to_b,
            deadline,
            is_active: true,
        }
    }

    /// Check if price limit order can be executed
    public fun can_execute_price_limit_order<CoinA, CoinB>(
        order: &PriceLimitOrder,
        pool: &LiquidityPool<CoinA, CoinB>,
        clock: &Clock,
    ): bool {
        if (!order.is_active) {
            return false
        };
        
        if (is_deadline_passed(order.deadline, clock)) {
            return false
        };
        
        // Calculate current price (output/input * 10000)
        let expected_output = if (order.is_a_to_b) {
            pool_factory::get_amount_out_a_to_b(pool, order.amount_in)
        } else {
            pool_factory::get_amount_out_b_to_a(pool, order.amount_in)
        };
        
        let current_price = (expected_output as u128) * 10000 / (order.amount_in as u128);
        
        (current_price as u64) >= order.min_price
    }

    /// Cancel a price limit order
    public fun cancel_price_limit_order(
        order: &mut PriceLimitOrder,
        ctx: &TxContext,
    ) {
        assert!(order.creator == tx_context::sender(ctx), errors::unauthorized());
        order.is_active = false;
    }

    /// Mark order as executed
    public fun mark_order_executed(order: &mut PriceLimitOrder) {
        order.is_active = false;
    }

    // ============ View Functions ============

    /// Get validated swap params fields
    public fun get_validated_params(params: &ValidatedSwapParams): (u64, u64, u64, bool) {
        (params.min_amount_out, params.deadline, params.price_impact, params.is_valid)
    }

    /// Get default settings
    public fun get_default_settings(settings: &SlippageProtectionSettings): (u64, u64, u64, u64) {
        (
            settings.default_slippage_tolerance,
            settings.max_slippage_tolerance,
            settings.default_deadline,
            settings.max_price_impact,
        )
    }

    /// Get user settings
    public fun get_user_settings(settings: &UserSlippageSettings): (u64, u64, bool, u64) {
        (
            settings.slippage_tolerance,
            settings.deadline,
            settings.use_price_impact_protection,
            settings.max_price_impact,
        )
    }

    /// Get price limit order details
    public fun get_order_details(order: &PriceLimitOrder): (ID, address, u64, u64, bool, u64, bool) {
        (
            order.pool_id,
            order.creator,
            order.amount_in,
            order.min_price,
            order.is_a_to_b,
            order.deadline,
            order.is_active,
        )
    }

    /// Check if price impact protection is enabled
    public fun is_price_impact_protection_enabled(settings: &SlippageProtectionSettings): bool {
        settings.price_impact_protection_enabled
    }

    /// Get current exchange rate (scaled by 10000)
    public fun get_exchange_rate<CoinA, CoinB>(
        pool: &LiquidityPool<CoinA, CoinB>,
        is_a_to_b: bool,
    ): u64 {
        let (reserve_a, reserve_b) = pool_factory::get_reserves(pool);
        
        if (is_a_to_b) {
            ((reserve_b as u128) * 10000 / (reserve_a as u128) as u64)
        } else {
            ((reserve_a as u128) * 10000 / (reserve_b as u128) as u64)
        }
    }

    /// Calculate effective exchange rate for a swap (including fees and slippage)
    public fun get_effective_rate<CoinA, CoinB>(
        pool: &LiquidityPool<CoinA, CoinB>,
        amount_in: u64,
        is_a_to_b: bool,
    ): u64 {
        let amount_out = if (is_a_to_b) {
            pool_factory::get_amount_out_a_to_b(pool, amount_in)
        } else {
            pool_factory::get_amount_out_b_to_a(pool, amount_in)
        };
        
        ((amount_out as u128) * 10000 / (amount_in as u128) as u64)
    }

    // ============ Admin Functions ============

    /// Update global slippage settings (requires admin cap from another module)
    public fun update_default_slippage_tolerance(
        settings: &mut SlippageProtectionSettings,
        new_tolerance: u64,
    ) {
        assert!(new_tolerance <= MAX_SLIPPAGE_TOLERANCE, errors::slippage_exceeded());
        settings.default_slippage_tolerance = new_tolerance;
    }

    /// Update maximum slippage tolerance
    public fun update_max_slippage_tolerance(
        settings: &mut SlippageProtectionSettings,
        new_max: u64,
    ) {
        settings.max_slippage_tolerance = new_max;
    }

    /// Update default deadline
    public fun update_default_deadline(
        settings: &mut SlippageProtectionSettings,
        new_deadline: u64,
    ) {
        settings.default_deadline = new_deadline;
    }

    /// Update max price impact
    public fun update_max_price_impact(
        settings: &mut SlippageProtectionSettings,
        new_max: u64,
    ) {
        settings.max_price_impact = new_max;
    }

    /// Toggle price impact protection
    public fun toggle_price_impact_protection(
        settings: &mut SlippageProtectionSettings,
        enabled: bool,
    ) {
        settings.price_impact_protection_enabled = enabled;
    }

    // ============ Helper Functions ============

    /// Assert slippage within tolerance
    public fun assert_slippage_ok(
        expected_output: u64,
        actual_output: u64,
        tolerance_bps: u64,
    ) {
        let min_output = calculate_min_output(expected_output, tolerance_bps);
        assert!(actual_output >= min_output, errors::slippage_exceeded());
    }

    /// Assert price impact within limit
    public fun assert_price_impact_ok(
        price_impact: u64,
        max_impact: u64,
    ) {
        assert!(price_impact <= max_impact, errors::price_impact_too_high());
    }

    // ============ Test Functions ============

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }
    
    #[test_only]
    public fun destroy_user_settings(settings: UserSlippageSettings) {
        let UserSlippageSettings {
            id,
            user: _,
            slippage_tolerance: _,
            deadline: _,
            use_price_impact_protection: _,
            max_price_impact: _,
        } = settings;
        object::delete(id);
    }
    
    #[test_only]
    public fun destroy_price_limit_order(order: PriceLimitOrder) {
        let PriceLimitOrder {
            id,
            pool_id: _,
            creator: _,
            amount_in: _,
            min_price: _,
            is_a_to_b: _,
            deadline: _,
            is_active: _,
        } = order;
        object::delete(id);
    }
}


