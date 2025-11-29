/// Fee Distributor Contract
/// Manages fee collection and distribution to liquidity providers
module sui_amm::fee_distributor {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::clock::Clock;
    use sui::table::{Self, Table};
    
    use sui_amm::events;
    use sui_amm::errors;
    use sui_amm::constants;
    use sui_amm::math;
    use sui_amm::lp_position_nft::{Self, LPPositionNFT};
    use sui_amm::pool_factory::{Self, LiquidityPool};

    // ============ Constants ============

    /// Precision for fee calculations (10^18)
    const FEE_PRECISION: u128 = 1000000000000000000;

    // ============ Structs ============

    /// Admin capability for fee distributor
    public struct FeeDistributorAdminCap has key, store {
        id: UID,
    }

    /// Fee Distributor - manages fee distribution across pools
    public struct FeeDistributor has key {
        id: UID,
        /// Protocol fee recipient
        protocol_fee_recipient: address,
        /// Auto-compound enabled by default
        auto_compound_default: bool,
        /// Minimum fees before claim is allowed
        min_claim_amount: u64,
    }

    /// Fee accumulator for a specific pool
    public struct PoolFeeAccumulator<phantom CoinA, phantom CoinB> has key, store {
        id: UID,
        /// Pool ID this accumulator is for
        pool_id: ID,
        /// Accumulated fees for token A
        accumulated_fees_a: Balance<CoinA>,
        /// Accumulated fees for token B
        accumulated_fees_b: Balance<CoinB>,
        /// Fee growth per LP token for token A (scaled by 10^18)
        fee_growth_global_a: u128,
        /// Fee growth per LP token for token B (scaled by 10^18)
        fee_growth_global_b: u128,
        /// Total fees distributed for token A
        total_fees_distributed_a: u64,
        /// Total fees distributed for token B
        total_fees_distributed_b: u64,
        /// Last update timestamp
        last_update: u64,
    }

    /// User's fee claim record
    public struct FeeClaimRecord has store, drop {
        /// Position ID
        position_id: ID,
        /// Last claimed fee growth A
        last_fee_growth_a: u128,
        /// Last claimed fee growth B
        last_fee_growth_b: u128,
        /// Total claimed A
        total_claimed_a: u64,
        /// Total claimed B
        total_claimed_b: u64,
    }

    // ============ Init ============

    fun init(ctx: &mut TxContext) {
        let admin_cap = FeeDistributorAdminCap {
            id: object::new(ctx),
        };

        let distributor = FeeDistributor {
            id: object::new(ctx),
            protocol_fee_recipient: tx_context::sender(ctx),
            auto_compound_default: false,
            min_claim_amount: 1, // Minimum 1 token to claim
        };

        transfer::transfer(admin_cap, tx_context::sender(ctx));
        transfer::share_object(distributor);
    }

    // ============ Fee Accumulator Functions ============

    /// Create a fee accumulator for a pool
    public fun create_accumulator<CoinA, CoinB>(
        pool_id: ID,
        ctx: &mut TxContext,
    ): PoolFeeAccumulator<CoinA, CoinB> {
        PoolFeeAccumulator {
            id: object::new(ctx),
            pool_id,
            accumulated_fees_a: balance::zero(),
            accumulated_fees_b: balance::zero(),
            fee_growth_global_a: 0,
            fee_growth_global_b: 0,
            total_fees_distributed_a: 0,
            total_fees_distributed_b: 0,
            last_update: 0,
        }
    }

    /// Add fees to the accumulator (called by pool on swaps)
    public fun add_fees<CoinA, CoinB>(
        accumulator: &mut PoolFeeAccumulator<CoinA, CoinB>,
        fee_a: Balance<CoinA>,
        fee_b: Balance<CoinB>,
        total_supply: u64,
        clock: &Clock,
    ) {
        let fee_a_amount = balance::value(&fee_a);
        let fee_b_amount = balance::value(&fee_b);
        
        // Update fee growth globals
        if (total_supply > 0) {
            if (fee_a_amount > 0) {
                let growth_a = (fee_a_amount as u128) * FEE_PRECISION / (total_supply as u128);
                accumulator.fee_growth_global_a = accumulator.fee_growth_global_a + growth_a;
            };
            
            if (fee_b_amount > 0) {
                let growth_b = (fee_b_amount as u128) * FEE_PRECISION / (total_supply as u128);
                accumulator.fee_growth_global_b = accumulator.fee_growth_global_b + growth_b;
            };
        };
        
        // Add to accumulated fees
        balance::join(&mut accumulator.accumulated_fees_a, fee_a);
        balance::join(&mut accumulator.accumulated_fees_b, fee_b);
        
        accumulator.last_update = sui::clock::timestamp_ms(clock);
    }

    // ============ Fee Claiming Functions ============

    /// Claim accumulated fees for a position
    public fun claim_fees<CoinA, CoinB>(
        pool: &LiquidityPool<CoinA, CoinB>,
        position: &mut LPPositionNFT,
        clock: &Clock,
        ctx: &mut TxContext,
    ): (Coin<CoinA>, Coin<CoinB>) {
        assert!(
            lp_position_nft::pool_id(position) == pool_factory::pool_id(pool),
            errors::invalid_position_owner()
        );

        // Get current fee growth from pool
        let (fee_growth_a, fee_growth_b) = pool_factory::get_fee_growth(pool);
        
        // Update position fees
        lp_position_nft::update_fees(position, fee_growth_a, fee_growth_b, clock);
        
        // Claim accumulated fees from position
        let (fees_a, fees_b) = lp_position_nft::claim_fees(position, clock);
        
        // Get tokens from pool reserves (this would need pool modification in practice)
        // For now, return empty coins if no fees
        let coin_a = coin::zero<CoinA>(ctx);
        let coin_b = coin::zero<CoinB>(ctx);
        
        // Emit event
        events::emit_fees_claimed(
            pool_factory::pool_id(pool),
            lp_position_nft::id(position),
            tx_context::sender(ctx),
            fees_a,
            fees_b,
        );

        (coin_a, coin_b)
    }

    /// Claim fees directly from pool (integrated version)
    public fun claim_fees_from_pool<CoinA, CoinB>(
        position: &mut LPPositionNFT,
        pool: &mut LiquidityPool<CoinA, CoinB>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): (Coin<CoinA>, Coin<CoinB>) {
        assert!(
            lp_position_nft::pool_id(position) == pool_factory::pool_id(pool),
            errors::invalid_position_owner()
        );

        // Get current fee growth from pool
        let (fee_growth_a, fee_growth_b) = pool_factory::get_fee_growth(pool);
        
        // Update position fees based on fee growth
        lp_position_nft::update_fees(position, fee_growth_a, fee_growth_b, clock);
        
        // Claim accumulated fees from position
        let (fees_a, fees_b) = lp_position_nft::claim_fees(position, clock);
        
        // Note: In a full implementation, fees would be extracted from pool reserves
        // For now, create zero coins as placeholder
        let coin_a = coin::zero<CoinA>(ctx);
        let coin_b = coin::zero<CoinB>(ctx);
        
        // Emit event
        events::emit_fees_claimed(
            pool_factory::pool_id(pool),
            lp_position_nft::id(position),
            tx_context::sender(ctx),
            fees_a,
            fees_b,
        );

        (coin_a, coin_b)
    }

    /// Calculate claimable fees for a position
    public fun calculate_claimable_fees<CoinA, CoinB>(
        pool: &LiquidityPool<CoinA, CoinB>,
        position: &LPPositionNFT,
    ): (u64, u64) {
        let (global_fee_growth_a, global_fee_growth_b) = pool_factory::get_fee_growth(pool);
        let (position_fee_growth_a, position_fee_growth_b) = lp_position_nft::fee_growth_last(position);
        let (current_fees_a, current_fees_b) = lp_position_nft::accumulated_fees(position);
        
        // Calculate new fees since last update
        let fee_growth_delta_a = global_fee_growth_a - position_fee_growth_a;
        let fee_growth_delta_b = global_fee_growth_b - position_fee_growth_b;
        
        let lp_tokens = lp_position_nft::lp_tokens(position);
        
        let new_fees_a = ((lp_tokens as u128) * fee_growth_delta_a / FEE_PRECISION as u64);
        let new_fees_b = ((lp_tokens as u128) * fee_growth_delta_b / FEE_PRECISION as u64);
        
        (
            math::safe_add(current_fees_a, new_fees_a),
            math::safe_add(current_fees_b, new_fees_b)
        )
    }

    // ============ Auto-Compound Functions ============

    /// Auto-compound fees back into the position
    public fun auto_compound<CoinA, CoinB>(
        pool: &mut LiquidityPool<CoinA, CoinB>,
        position: &mut LPPositionNFT,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        assert!(
            lp_position_nft::pool_id(position) == pool_factory::pool_id(pool),
            errors::invalid_position_owner()
        );

        // Get current fee growth from pool
        let (fee_growth_a, fee_growth_b) = pool_factory::get_fee_growth(pool);
        
        // Update position fees
        lp_position_nft::update_fees(position, fee_growth_a, fee_growth_b, clock);
        
        // Get claimable fees
        let (fees_a, fees_b) = lp_position_nft::claim_fees(position, clock);
        
        if (fees_a == 0 && fees_b == 0) {
            return
        };
        
        // Calculate additional LP tokens from fees
        let (reserve_a, reserve_b) = pool_factory::get_reserves(pool);
        let total_supply = pool_factory::get_total_supply(pool);
        
        let additional_lp_tokens = if (total_supply > 0 && reserve_a > 0 && reserve_b > 0) {
            math::calculate_lp_tokens_to_mint(
                fees_a,
                fees_b,
                reserve_a,
                reserve_b,
                total_supply,
            )
        } else {
            0
        };
        
        if (additional_lp_tokens > 0) {
            // Add LP tokens to position
            lp_position_nft::add_lp_tokens(position, additional_lp_tokens, fees_a, fees_b, clock);
            
            // Emit event
            events::emit_fees_compounded(
                pool_factory::pool_id(pool),
                lp_position_nft::id(position),
                fees_a,
                fees_b,
                additional_lp_tokens,
            );
        };
    }

    // ============ View Functions ============

    /// Get fee growth globals from accumulator
    public fun get_fee_growth<CoinA, CoinB>(
        accumulator: &PoolFeeAccumulator<CoinA, CoinB>,
    ): (u128, u128) {
        (accumulator.fee_growth_global_a, accumulator.fee_growth_global_b)
    }

    /// Get accumulated fees in accumulator
    public fun get_accumulated_fees<CoinA, CoinB>(
        accumulator: &PoolFeeAccumulator<CoinA, CoinB>,
    ): (u64, u64) {
        (
            balance::value(&accumulator.accumulated_fees_a),
            balance::value(&accumulator.accumulated_fees_b),
        )
    }

    /// Get total fees distributed
    public fun get_total_distributed<CoinA, CoinB>(
        accumulator: &PoolFeeAccumulator<CoinA, CoinB>,
    ): (u64, u64) {
        (accumulator.total_fees_distributed_a, accumulator.total_fees_distributed_b)
    }

    /// Get protocol fee recipient
    public fun get_protocol_fee_recipient(distributor: &FeeDistributor): address {
        distributor.protocol_fee_recipient
    }

    /// Get minimum claim amount
    public fun get_min_claim_amount(distributor: &FeeDistributor): u64 {
        distributor.min_claim_amount
    }

    /// Calculate fee share for a position
    public fun calculate_fee_share<CoinA, CoinB>(
        pool: &LiquidityPool<CoinA, CoinB>,
        position: &LPPositionNFT,
    ): u64 {
        let total_supply = pool_factory::get_total_supply(pool);
        let lp_tokens = lp_position_nft::lp_tokens(position);
        
        if (total_supply == 0) {
            return 0
        };
        
        // Return share in basis points
        (((lp_tokens as u128) * 10000 / (total_supply as u128)) as u64)
    }

    // ============ Admin Functions ============

    /// Set protocol fee recipient
    public fun set_protocol_fee_recipient(
        _: &FeeDistributorAdminCap,
        distributor: &mut FeeDistributor,
        recipient: address,
    ) {
        distributor.protocol_fee_recipient = recipient;
    }

    /// Set minimum claim amount
    public fun set_min_claim_amount(
        _: &FeeDistributorAdminCap,
        distributor: &mut FeeDistributor,
        amount: u64,
    ) {
        distributor.min_claim_amount = amount;
    }

    /// Set auto-compound default
    public fun set_auto_compound_default(
        _: &FeeDistributorAdminCap,
        distributor: &mut FeeDistributor,
        enabled: bool,
    ) {
        distributor.auto_compound_default = enabled;
    }

    /// Withdraw accumulated fees from accumulator (for distribution)
    public fun withdraw_accumulated_fees<CoinA, CoinB>(
        _: &FeeDistributorAdminCap,
        accumulator: &mut PoolFeeAccumulator<CoinA, CoinB>,
        ctx: &mut TxContext,
    ): (Coin<CoinA>, Coin<CoinB>) {
        let amount_a = balance::value(&accumulator.accumulated_fees_a);
        let amount_b = balance::value(&accumulator.accumulated_fees_b);
        
        accumulator.total_fees_distributed_a = accumulator.total_fees_distributed_a + amount_a;
        accumulator.total_fees_distributed_b = accumulator.total_fees_distributed_b + amount_b;
        
        let coin_a = coin::from_balance(
            balance::withdraw_all(&mut accumulator.accumulated_fees_a),
            ctx,
        );
        let coin_b = coin::from_balance(
            balance::withdraw_all(&mut accumulator.accumulated_fees_b),
            ctx,
        );
        
        (coin_a, coin_b)
    }

    // ============ Test Functions ============

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }
}

