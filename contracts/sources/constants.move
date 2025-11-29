/// Constants and shared types for the Sui AMM
module sui_amm::constants {
    // ============ Fee Tiers (in basis points, 1 bp = 0.01%) ============
    
    /// 0.05% fee tier - for stable pairs
    public fun fee_tier_low(): u64 { 5 }
    
    /// 0.3% fee tier - standard tier
    public fun fee_tier_medium(): u64 { 30 }
    
    /// 1% fee tier - for exotic pairs
    public fun fee_tier_high(): u64 { 100 }
    
    /// Basis points denominator (10000 = 100%)
    public fun basis_points(): u64 { 10000 }
    
    // ============ Protocol Fee ============
    
    /// Protocol fee percentage of trading fees (in basis points)
    /// 10% of trading fees go to protocol
    public fun protocol_fee_percentage(): u64 { 1000 }
    
    // ============ Liquidity Constants ============
    
    /// Minimum liquidity to prevent division by zero attacks
    public fun minimum_liquidity(): u64 { 1000 }
    
    /// Ratio tolerance for adding liquidity (0.5% = 50 basis points)
    public fun ratio_tolerance(): u64 { 50 }
    
    // ============ Stable Swap Constants ============
    
    /// Default amplification coefficient for stable swap
    public fun default_amplification(): u64 { 100 }
    
    /// Maximum amplification coefficient
    public fun max_amplification(): u64 { 1000000 }
    
    /// Minimum amplification coefficient
    public fun min_amplification(): u64 { 1 }
    
    // ============ Precision Constants ============
    
    /// Precision for fee calculations
    public fun fee_precision(): u128 { 1000000 }
    
    /// Precision for LP calculations
    public fun lp_precision(): u128 { 1000000000000000000 } // 10^18
    
    // ============ Validation ============
    
    /// Validates that a fee tier is valid
    public fun is_valid_fee_tier(fee_tier: u64): bool {
        fee_tier == fee_tier_low() || 
        fee_tier == fee_tier_medium() || 
        fee_tier == fee_tier_high()
    }
}


