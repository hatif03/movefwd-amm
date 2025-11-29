/// Math utilities for the Sui AMM
module sui_amm::math {
    use sui_amm::errors;
    
    // ============ Basic Math Operations ============
    
    /// Safe multiplication that checks for overflow
    public fun safe_mul(a: u64, b: u64): u64 {
        let result = (a as u128) * (b as u128);
        assert!(result <= 18446744073709551615u128, errors::overflow());
        (result as u64)
    }
    
    /// Safe multiplication for u128
    public fun safe_mul_u128(a: u128, b: u128): u128 {
        // For very large numbers, check overflow
        if (a == 0 || b == 0) {
            return 0
        };
        let result = a * b;
        assert!(result / a == b, errors::overflow());
        result
    }
    
    /// Safe division that checks for division by zero
    public fun safe_div(a: u64, b: u64): u64 {
        assert!(b > 0, errors::division_by_zero());
        a / b
    }
    
    /// Safe division for u128
    public fun safe_div_u128(a: u128, b: u128): u128 {
        assert!(b > 0, errors::division_by_zero());
        a / b
    }
    
    /// Safe subtraction that checks for underflow
    public fun safe_sub(a: u64, b: u64): u64 {
        assert!(a >= b, errors::underflow());
        a - b
    }
    
    /// Safe addition that checks for overflow
    public fun safe_add(a: u64, b: u64): u64 {
        let result = (a as u128) + (b as u128);
        assert!(result <= 18446744073709551615u128, errors::overflow());
        (result as u64)
    }
    
    // ============ Square Root ============
    
    /// Calculate integer square root using Newton's method
    /// Returns floor(sqrt(n))
    public fun sqrt(n: u128): u128 {
        if (n == 0) {
            return 0
        };
        
        let mut x = n;
        let mut y = (x + 1) / 2;
        
        while (y < x) {
            x = y;
            y = (x + n / x) / 2;
        };
        
        x
    }
    
    /// Calculate square root for u64
    public fun sqrt_u64(n: u64): u64 {
        (sqrt((n as u128)) as u64)
    }
    
    // ============ AMM Math Functions ============
    
    /// Calculate output amount for a swap using constant product formula
    /// output = (input_with_fee * reserve_out) / (reserve_in + input_with_fee)
    /// where input_with_fee = input * (10000 - fee_bps) / 10000
    public fun calculate_output_amount(
        amount_in: u64,
        reserve_in: u64,
        reserve_out: u64,
        fee_bps: u64,
    ): u64 {
        assert!(amount_in > 0, errors::zero_amount());
        assert!(reserve_in > 0 && reserve_out > 0, errors::insufficient_liquidity());
        
        // Calculate input after fee: amount_in * (10000 - fee_bps)
        let amount_in_with_fee = (amount_in as u128) * ((10000 - fee_bps) as u128);
        
        // Calculate numerator: amount_in_with_fee * reserve_out
        let numerator = amount_in_with_fee * (reserve_out as u128);
        
        // Calculate denominator: reserve_in * 10000 + amount_in_with_fee
        let denominator = (reserve_in as u128) * 10000 + amount_in_with_fee;
        
        // Calculate output
        let output = numerator / denominator;
        
        (output as u64)
    }
    
    /// Calculate input amount required for a desired output
    /// input = (reserve_in * amount_out * 10000) / ((reserve_out - amount_out) * (10000 - fee_bps)) + 1
    public fun calculate_input_amount(
        amount_out: u64,
        reserve_in: u64,
        reserve_out: u64,
        fee_bps: u64,
    ): u64 {
        assert!(amount_out > 0, errors::zero_amount());
        assert!(reserve_in > 0 && reserve_out > 0, errors::insufficient_liquidity());
        assert!(amount_out < reserve_out, errors::insufficient_liquidity());
        
        let numerator = (reserve_in as u128) * (amount_out as u128) * 10000;
        let denominator = ((reserve_out - amount_out) as u128) * ((10000 - fee_bps) as u128);
        
        // Add 1 to round up
        let input = (numerator / denominator) + 1;
        
        (input as u64)
    }
    
    /// Calculate the fee amount from an input
    public fun calculate_fee_amount(amount_in: u64, fee_bps: u64): u64 {
        ((amount_in as u128) * (fee_bps as u128) / 10000 as u64)
    }
    
    /// Calculate LP tokens to mint for adding liquidity
    /// For first deposit: sqrt(amount_a * amount_b) - MINIMUM_LIQUIDITY
    /// For subsequent: min(amount_a * total_supply / reserve_a, amount_b * total_supply / reserve_b)
    public fun calculate_lp_tokens_to_mint(
        amount_a: u64,
        amount_b: u64,
        reserve_a: u64,
        reserve_b: u64,
        total_supply: u64,
    ): u64 {
        if (total_supply == 0) {
            // First liquidity provider
            let product = (amount_a as u128) * (amount_b as u128);
            let lp_tokens = sqrt(product);
            
            // Subtract minimum liquidity to prevent attacks
            assert!(lp_tokens > 1000, errors::below_minimum_liquidity());
            ((lp_tokens - 1000) as u64)
        } else {
            // Subsequent liquidity providers
            let lp_a = ((amount_a as u128) * (total_supply as u128) / (reserve_a as u128) as u64);
            let lp_b = ((amount_b as u128) * (total_supply as u128) / (reserve_b as u128) as u64);
            
            // Return minimum to ensure fair minting
            if (lp_a < lp_b) { lp_a } else { lp_b }
        }
    }
    
    /// Calculate token amounts to return when removing liquidity
    /// amount_a = lp_tokens * reserve_a / total_supply
    /// amount_b = lp_tokens * reserve_b / total_supply
    public fun calculate_liquidity_removal(
        lp_tokens: u64,
        reserve_a: u64,
        reserve_b: u64,
        total_supply: u64,
    ): (u64, u64) {
        assert!(total_supply > 0, errors::division_by_zero());
        assert!(lp_tokens <= total_supply, errors::insufficient_lp_tokens());
        
        let amount_a = ((lp_tokens as u128) * (reserve_a as u128) / (total_supply as u128) as u64);
        let amount_b = ((lp_tokens as u128) * (reserve_b as u128) / (total_supply as u128) as u64);
        
        (amount_a, amount_b)
    }
    
    /// Calculate price impact of a swap
    /// Returns price impact in basis points
    public fun calculate_price_impact(
        amount_in: u64,
        reserve_in: u64,
        reserve_out: u64,
        fee_bps: u64,
    ): u64 {
        // Spot price before swap (scaled by 10000 for precision)
        let spot_price = (reserve_out as u128) * 10000 / (reserve_in as u128);
        
        // Calculate actual output
        let amount_out = calculate_output_amount(amount_in, reserve_in, reserve_out, fee_bps);
        
        // Effective price (scaled by 10000)
        let effective_price = (amount_out as u128) * 10000 / (amount_in as u128);
        
        // Price impact = (spot_price - effective_price) / spot_price * 10000
        if (spot_price > effective_price) {
            (((spot_price - effective_price) * 10000 / spot_price) as u64)
        } else {
            0
        }
    }
    
    /// Calculate impermanent loss given price change
    /// price_ratio is the ratio of new price to original price (scaled by 10000)
    /// Returns IL in basis points
    public fun calculate_impermanent_loss(price_ratio: u64): u64 {
        // IL = 2 * sqrt(price_ratio) / (1 + price_ratio) - 1
        // Scaled calculation for precision
        
        let ratio_128 = (price_ratio as u128);
        let sqrt_ratio = sqrt(ratio_128 * 10000); // sqrt scaled by 100
        
        // 2 * sqrt(r) / (1 + r) scaled by 10000
        let numerator = 2 * sqrt_ratio * 10000;
        let denominator = 10000 + ratio_128;
        
        let hodl_value_ratio = numerator / denominator;
        
        if (hodl_value_ratio < 10000) {
            (10000 - (hodl_value_ratio as u64))
        } else {
            0
        }
    }
    
    /// Check if amounts are within tolerance ratio
    /// Returns true if |actual_ratio - expected_ratio| / expected_ratio <= tolerance_bps
    public fun is_within_ratio_tolerance(
        amount_a: u64,
        amount_b: u64,
        reserve_a: u64,
        reserve_b: u64,
        tolerance_bps: u64,
    ): bool {
        if (reserve_a == 0 || reserve_b == 0) {
            return true // First deposit, any ratio is fine
        };
        
        // Calculate actual and expected ratios (scaled by 10^12 for precision)
        let scale = 1000000000000u128;
        let actual_ratio = (amount_a as u128) * scale / (amount_b as u128);
        let expected_ratio = (reserve_a as u128) * scale / (reserve_b as u128);
        
        // Calculate difference
        let diff = if (actual_ratio > expected_ratio) {
            actual_ratio - expected_ratio
        } else {
            expected_ratio - actual_ratio
        };
        
        // Check if within tolerance
        let tolerance = expected_ratio * (tolerance_bps as u128) / 10000;
        diff <= tolerance
    }
    
    /// Get minimum of two values
    public fun min(a: u64, b: u64): u64 {
        if (a < b) { a } else { b }
    }
    
    /// Get maximum of two values
    public fun max(a: u64, b: u64): u64 {
        if (a > b) { a } else { b }
    }
    
    /// Get minimum of two u128 values
    public fun min_u128(a: u128, b: u128): u128 {
        if (a < b) { a } else { b }
    }
    
    /// Get maximum of two u128 values
    public fun max_u128(a: u128, b: u128): u128 {
        if (a > b) { a } else { b }
    }
}

