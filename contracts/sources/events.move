/// Events for the Sui AMM
module sui_amm::events {
    use sui::event;
    use sui::object::ID;
    
    // ============ Pool Events ============
    
    /// Emitted when a new pool is created
    public struct PoolCreated has copy, drop {
        pool_id: ID,
        token_a_type: vector<u8>,
        token_b_type: vector<u8>,
        fee_tier: u64,
        initial_reserve_a: u64,
        initial_reserve_b: u64,
        creator: address,
    }
    
    /// Emitted when pool is paused/unpaused
    public struct PoolStatusChanged has copy, drop {
        pool_id: ID,
        is_paused: bool,
    }
    
    // ============ Liquidity Events ============
    
    /// Emitted when liquidity is added
    public struct LiquidityAdded has copy, drop {
        pool_id: ID,
        position_id: ID,
        provider: address,
        amount_a: u64,
        amount_b: u64,
        lp_tokens_minted: u64,
        total_supply_after: u64,
    }
    
    /// Emitted when liquidity is removed
    public struct LiquidityRemoved has copy, drop {
        pool_id: ID,
        position_id: ID,
        provider: address,
        amount_a: u64,
        amount_b: u64,
        lp_tokens_burned: u64,
        total_supply_after: u64,
    }
    
    // ============ Swap Events ============
    
    /// Emitted when a swap is executed
    public struct SwapExecuted has copy, drop {
        pool_id: ID,
        sender: address,
        amount_in: u64,
        amount_out: u64,
        fee_amount: u64,
        is_a_to_b: bool,
        reserve_a_after: u64,
        reserve_b_after: u64,
    }
    
    // ============ Fee Events ============
    
    /// Emitted when fees are claimed
    public struct FeesClaimed has copy, drop {
        pool_id: ID,
        position_id: ID,
        claimer: address,
        fee_amount_a: u64,
        fee_amount_b: u64,
    }
    
    /// Emitted when protocol fees are collected
    public struct ProtocolFeesCollected has copy, drop {
        pool_id: ID,
        amount_a: u64,
        amount_b: u64,
        collector: address,
    }
    
    /// Emitted when fees are auto-compounded
    public struct FeesCompounded has copy, drop {
        pool_id: ID,
        position_id: ID,
        fee_amount_a: u64,
        fee_amount_b: u64,
        additional_lp_tokens: u64,
    }
    
    // ============ NFT Position Events ============
    
    /// Emitted when a new LP position NFT is minted
    public struct PositionMinted has copy, drop {
        position_id: ID,
        pool_id: ID,
        owner: address,
        lp_tokens: u64,
    }
    
    /// Emitted when an LP position NFT is burned
    public struct PositionBurned has copy, drop {
        position_id: ID,
        pool_id: ID,
        owner: address,
    }
    
    /// Emitted when position metadata is updated
    public struct PositionUpdated has copy, drop {
        position_id: ID,
        lp_tokens: u64,
        accumulated_fees_a: u64,
        accumulated_fees_b: u64,
    }
    
    /// Emitted when position is transferred
    public struct PositionTransferred has copy, drop {
        position_id: ID,
        from: address,
        to: address,
    }
    
    // ============ Event Emission Functions ============
    
    public fun emit_pool_created(
        pool_id: ID,
        token_a_type: vector<u8>,
        token_b_type: vector<u8>,
        fee_tier: u64,
        initial_reserve_a: u64,
        initial_reserve_b: u64,
        creator: address,
    ) {
        event::emit(PoolCreated {
            pool_id,
            token_a_type,
            token_b_type,
            fee_tier,
            initial_reserve_a,
            initial_reserve_b,
            creator,
        });
    }
    
    public fun emit_pool_status_changed(pool_id: ID, is_paused: bool) {
        event::emit(PoolStatusChanged { pool_id, is_paused });
    }
    
    public fun emit_liquidity_added(
        pool_id: ID,
        position_id: ID,
        provider: address,
        amount_a: u64,
        amount_b: u64,
        lp_tokens_minted: u64,
        total_supply_after: u64,
    ) {
        event::emit(LiquidityAdded {
            pool_id,
            position_id,
            provider,
            amount_a,
            amount_b,
            lp_tokens_minted,
            total_supply_after,
        });
    }
    
    public fun emit_liquidity_removed(
        pool_id: ID,
        position_id: ID,
        provider: address,
        amount_a: u64,
        amount_b: u64,
        lp_tokens_burned: u64,
        total_supply_after: u64,
    ) {
        event::emit(LiquidityRemoved {
            pool_id,
            position_id,
            provider,
            amount_a,
            amount_b,
            lp_tokens_burned,
            total_supply_after,
        });
    }
    
    public fun emit_swap_executed(
        pool_id: ID,
        sender: address,
        amount_in: u64,
        amount_out: u64,
        fee_amount: u64,
        is_a_to_b: bool,
        reserve_a_after: u64,
        reserve_b_after: u64,
    ) {
        event::emit(SwapExecuted {
            pool_id,
            sender,
            amount_in,
            amount_out,
            fee_amount,
            is_a_to_b,
            reserve_a_after,
            reserve_b_after,
        });
    }
    
    public fun emit_fees_claimed(
        pool_id: ID,
        position_id: ID,
        claimer: address,
        fee_amount_a: u64,
        fee_amount_b: u64,
    ) {
        event::emit(FeesClaimed {
            pool_id,
            position_id,
            claimer,
            fee_amount_a,
            fee_amount_b,
        });
    }
    
    public fun emit_protocol_fees_collected(
        pool_id: ID,
        amount_a: u64,
        amount_b: u64,
        collector: address,
    ) {
        event::emit(ProtocolFeesCollected {
            pool_id,
            amount_a,
            amount_b,
            collector,
        });
    }
    
    public fun emit_fees_compounded(
        pool_id: ID,
        position_id: ID,
        fee_amount_a: u64,
        fee_amount_b: u64,
        additional_lp_tokens: u64,
    ) {
        event::emit(FeesCompounded {
            pool_id,
            position_id,
            fee_amount_a,
            fee_amount_b,
            additional_lp_tokens,
        });
    }
    
    public fun emit_position_minted(
        position_id: ID,
        pool_id: ID,
        owner: address,
        lp_tokens: u64,
    ) {
        event::emit(PositionMinted {
            position_id,
            pool_id,
            owner,
            lp_tokens,
        });
    }
    
    public fun emit_position_burned(
        position_id: ID,
        pool_id: ID,
        owner: address,
    ) {
        event::emit(PositionBurned {
            position_id,
            pool_id,
            owner,
        });
    }
    
    public fun emit_position_updated(
        position_id: ID,
        lp_tokens: u64,
        accumulated_fees_a: u64,
        accumulated_fees_b: u64,
    ) {
        event::emit(PositionUpdated {
            position_id,
            lp_tokens,
            accumulated_fees_a,
            accumulated_fees_b,
        });
    }
    
    public fun emit_position_transferred(
        position_id: ID,
        from: address,
        to: address,
    ) {
        event::emit(PositionTransferred {
            position_id,
            from,
            to,
        });
    }
}

