/// Error codes for the Sui AMM
module sui_amm::errors {
    // ============ General Errors (0-99) ============
    
    /// Zero amount provided
    public fun zero_amount(): u64 { 0 }
    
    /// Invalid fee tier
    public fun invalid_fee_tier(): u64 { 1 }
    
    /// Unauthorized operation
    public fun unauthorized(): u64 { 2 }
    
    /// Invalid address
    public fun invalid_address(): u64 { 3 }
    
    // ============ Pool Errors (100-199) ============
    
    /// Pool already exists for this token pair and fee tier
    public fun pool_already_exists(): u64 { 100 }
    
    /// Pool does not exist
    public fun pool_not_found(): u64 { 101 }
    
    /// Insufficient liquidity in pool
    public fun insufficient_liquidity(): u64 { 102 }
    
    /// Invalid token pair (same token)
    public fun invalid_token_pair(): u64 { 103 }
    
    /// Pool is paused
    public fun pool_paused(): u64 { 104 }
    
    /// K invariant violated
    public fun k_invariant_violated(): u64 { 105 }
    
    // ============ Liquidity Errors (200-299) ============
    
    /// Liquidity ratio out of tolerance
    public fun ratio_out_of_tolerance(): u64 { 200 }
    
    /// Insufficient LP tokens
    public fun insufficient_lp_tokens(): u64 { 201 }
    
    /// Below minimum liquidity
    public fun below_minimum_liquidity(): u64 { 202 }
    
    /// Invalid liquidity amounts
    public fun invalid_liquidity_amounts(): u64 { 203 }
    
    // ============ Swap Errors (300-399) ============
    
    /// Slippage tolerance exceeded
    public fun slippage_exceeded(): u64 { 300 }
    
    /// Transaction deadline exceeded
    public fun deadline_exceeded(): u64 { 301 }
    
    /// Insufficient output amount
    public fun insufficient_output(): u64 { 302 }
    
    /// Price impact too high
    public fun price_impact_too_high(): u64 { 303 }
    
    /// Invalid swap path
    public fun invalid_swap_path(): u64 { 304 }
    
    // ============ NFT Position Errors (400-499) ============
    
    /// Position not found
    public fun position_not_found(): u64 { 400 }
    
    /// Position already exists
    public fun position_already_exists(): u64 { 401 }
    
    /// Invalid position owner
    public fun invalid_position_owner(): u64 { 402 }
    
    /// Position has no liquidity
    public fun position_empty(): u64 { 403 }
    
    // ============ Fee Errors (500-599) ============
    
    /// No fees to claim
    public fun no_fees_to_claim(): u64 { 500 }
    
    /// Fee calculation overflow
    public fun fee_overflow(): u64 { 501 }
    
    /// Invalid fee recipient
    public fun invalid_fee_recipient(): u64 { 502 }
    
    // ============ Stable Swap Errors (600-699) ============
    
    /// Invalid amplification coefficient
    public fun invalid_amplification(): u64 { 600 }
    
    /// Stable swap convergence failed
    public fun convergence_failed(): u64 { 601 }
    
    /// Tokens not suitable for stable swap
    public fun not_stable_pair(): u64 { 602 }
    
    // ============ Math Errors (700-799) ============
    
    /// Arithmetic overflow
    public fun overflow(): u64 { 700 }
    
    /// Arithmetic underflow
    public fun underflow(): u64 { 701 }
    
    /// Division by zero
    public fun division_by_zero(): u64 { 702 }
    
    /// Square root calculation error
    public fun sqrt_error(): u64 { 703 }
}




