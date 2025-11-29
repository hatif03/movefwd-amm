/// Unit tests for Math module
#[test_only]
module sui_amm::math_tests {
    use sui_amm::math;

    // ============ Basic Math Tests ============

    #[test]
    fun test_safe_add() {
        assert!(math::safe_add(100, 200) == 300, 0);
        assert!(math::safe_add(0, 0) == 0, 1);
        assert!(math::safe_add(1, 0) == 1, 2);
    }

    #[test]
    #[expected_failure(abort_code = 700, location = sui_amm::math)]
    fun test_safe_add_overflow() {
        let max_u64 = 18446744073709551615u64;
        math::safe_add(max_u64, 1);
    }

    #[test]
    fun test_safe_sub() {
        assert!(math::safe_sub(300, 200) == 100, 0);
        assert!(math::safe_sub(100, 100) == 0, 1);
        assert!(math::safe_sub(100, 0) == 100, 2);
    }

    #[test]
    #[expected_failure(abort_code = 701, location = sui_amm::math)]
    fun test_safe_sub_underflow() {
        math::safe_sub(100, 200);
    }

    #[test]
    fun test_safe_mul() {
        assert!(math::safe_mul(100, 200) == 20000, 0);
        assert!(math::safe_mul(0, 1000) == 0, 1);
        assert!(math::safe_mul(1, 1) == 1, 2);
    }

    #[test]
    fun test_safe_div() {
        assert!(math::safe_div(200, 100) == 2, 0);
        assert!(math::safe_div(100, 100) == 1, 1);
        assert!(math::safe_div(0, 100) == 0, 2);
    }

    #[test]
    #[expected_failure(abort_code = 702, location = sui_amm::math)]
    fun test_safe_div_by_zero() {
        math::safe_div(100, 0);
    }

    // ============ Square Root Tests ============

    #[test]
    fun test_sqrt() {
        assert!(math::sqrt(0) == 0, 0);
        assert!(math::sqrt(1) == 1, 1);
        assert!(math::sqrt(4) == 2, 2);
        assert!(math::sqrt(9) == 3, 3);
        assert!(math::sqrt(16) == 4, 4);
        assert!(math::sqrt(100) == 10, 5);
        assert!(math::sqrt(1000000) == 1000, 6);
        
        // Non-perfect squares (floor)
        assert!(math::sqrt(2) == 1, 7);
        assert!(math::sqrt(3) == 1, 8);
        assert!(math::sqrt(5) == 2, 9);
        assert!(math::sqrt(8) == 2, 10);
    }

    #[test]
    fun test_sqrt_u64() {
        assert!(math::sqrt_u64(0) == 0, 0);
        assert!(math::sqrt_u64(100) == 10, 1);
        assert!(math::sqrt_u64(10000) == 100, 2);
    }

    // ============ AMM Math Tests ============

    #[test]
    fun test_calculate_output_amount() {
        // Standard swap: 1000 in, reserves 10000/10000, 0.3% fee
        let output = math::calculate_output_amount(1000, 10000, 10000, 30);
        // Expected: (1000 * 9970 * 10000) / (10000 * 10000 + 1000 * 9970)
        // = 99700000000 / 109970000 ≈ 906
        assert!(output > 0, 0);
        assert!(output < 1000, 1); // Should be less than input due to fee
        
        // Large swap
        let large_output = math::calculate_output_amount(5000, 10000, 10000, 30);
        assert!(large_output > output, 2);
        
        // Very small swap
        let small_output = math::calculate_output_amount(1, 10000, 10000, 30);
        assert!(small_output == 0 || small_output == 1, 3);
    }

    #[test]
    fun test_calculate_output_amount_no_fee() {
        // No fee swap
        let output = math::calculate_output_amount(1000, 10000, 10000, 0);
        // Expected: 1000 * 10000 / (10000 + 1000) ≈ 909
        assert!(output > 900, 0);
        assert!(output < 920, 1);
    }

    #[test]
    #[expected_failure(abort_code = 0, location = sui_amm::math)]
    fun test_calculate_output_zero_input() {
        math::calculate_output_amount(0, 10000, 10000, 30);
    }

    #[test]
    #[expected_failure(abort_code = 102, location = sui_amm::math)]
    fun test_calculate_output_zero_reserve() {
        math::calculate_output_amount(1000, 0, 10000, 30);
    }

    #[test]
    fun test_calculate_input_amount() {
        // Calculate input needed for specific output
        let input = math::calculate_input_amount(900, 10000, 10000, 30);
        assert!(input > 900, 0); // Input should be more than output
        
        // Verify it would produce approximately the desired output
        let output = math::calculate_output_amount(input, 10000, 10000, 30);
        assert!(output >= 900, 1);
    }

    #[test]
    fun test_calculate_fee_amount() {
        // 0.3% fee on 1000
        let fee = math::calculate_fee_amount(1000, 30);
        assert!(fee == 3, 0);
        
        // 1% fee on 1000
        let fee_1pct = math::calculate_fee_amount(1000, 100);
        assert!(fee_1pct == 10, 1);
        
        // 0.05% fee on 1000
        let fee_low = math::calculate_fee_amount(1000, 5);
        assert!(fee_low == 0, 2); // Rounds down
        
        // 0.05% fee on 10000
        let fee_low_larger = math::calculate_fee_amount(10000, 5);
        assert!(fee_low_larger == 5, 3);
    }

    // ============ LP Token Calculation Tests ============

    #[test]
    fun test_calculate_lp_tokens_first_deposit() {
        // First deposit: sqrt(1000 * 1000) - 1000 = 0
        // Need larger amounts for meaningful LP tokens
        let lp_tokens = math::calculate_lp_tokens_to_mint(10000, 10000, 0, 0, 0);
        assert!(lp_tokens == 9000, 0); // sqrt(100000000) - 1000 = 10000 - 1000 = 9000
    }

    #[test]
    fun test_calculate_lp_tokens_subsequent_deposit() {
        // Subsequent deposit
        let lp_tokens = math::calculate_lp_tokens_to_mint(1000, 1000, 10000, 10000, 9000);
        // Expected: min(1000 * 9000 / 10000, 1000 * 9000 / 10000) = 900
        assert!(lp_tokens == 900, 0);
    }

    #[test]
    fun test_calculate_lp_tokens_unbalanced() {
        // Unbalanced deposit should use minimum
        let lp_tokens = math::calculate_lp_tokens_to_mint(2000, 1000, 10000, 10000, 9000);
        // min(2000 * 9000 / 10000, 1000 * 9000 / 10000) = min(1800, 900) = 900
        assert!(lp_tokens == 900, 0);
    }

    // ============ Liquidity Removal Tests ============

    #[test]
    fun test_calculate_liquidity_removal() {
        let (amount_a, amount_b) = math::calculate_liquidity_removal(
            1000,  // LP tokens to remove
            10000, // reserve_a
            20000, // reserve_b
            5000,  // total_supply
        );
        
        // amount_a = 1000 * 10000 / 5000 = 2000
        // amount_b = 1000 * 20000 / 5000 = 4000
        assert!(amount_a == 2000, 0);
        assert!(amount_b == 4000, 1);
    }

    #[test]
    fun test_calculate_liquidity_removal_all() {
        let (amount_a, amount_b) = math::calculate_liquidity_removal(
            5000,  // All LP tokens
            10000, // reserve_a
            20000, // reserve_b
            5000,  // total_supply
        );
        
        assert!(amount_a == 10000, 0);
        assert!(amount_b == 20000, 1);
    }

    // ============ Price Impact Tests ============

    #[test]
    fun test_calculate_price_impact() {
        // Small swap should have low price impact
        let impact_small = math::calculate_price_impact(100, 10000, 10000, 30);
        assert!(impact_small < 500, 0); // Less than 5%
        
        // Large swap should have higher price impact
        let impact_large = math::calculate_price_impact(5000, 10000, 10000, 30);
        assert!(impact_large > impact_small, 1);
    }

    // ============ Impermanent Loss Tests ============

    #[test]
    fun test_calculate_impermanent_loss() {
        // No price change = no IL
        let il_no_change = math::calculate_impermanent_loss(10000); // 1:1 ratio
        assert!(il_no_change == 0, 0);
        
        // 2x price increase
        let il_2x = math::calculate_impermanent_loss(20000); // 2:1 ratio
        assert!(il_2x > 0, 1);
        
        // 4x price increase
        let il_4x = math::calculate_impermanent_loss(40000); // 4:1 ratio
        assert!(il_4x > il_2x, 2);
    }

    // ============ Ratio Tolerance Tests ============

    #[test]
    fun test_is_within_ratio_tolerance() {
        // Same ratio should be within tolerance
        assert!(math::is_within_ratio_tolerance(1000, 1000, 10000, 10000, 50), 0);
        
        // Slightly off ratio should be within 0.5% tolerance
        assert!(math::is_within_ratio_tolerance(1000, 1003, 10000, 10000, 50), 1);
        
        // Way off ratio should fail (10% difference)
        assert!(!math::is_within_ratio_tolerance(1000, 1100, 10000, 10000, 50), 2);
    }

    #[test]
    fun test_is_within_ratio_tolerance_first_deposit() {
        // First deposit (zero reserves) should always pass
        assert!(math::is_within_ratio_tolerance(1000, 2000, 0, 0, 50), 0);
    }

    // ============ Min/Max Tests ============

    #[test]
    fun test_min_max() {
        assert!(math::min(100, 200) == 100, 0);
        assert!(math::min(200, 100) == 100, 1);
        assert!(math::min(100, 100) == 100, 2);
        
        assert!(math::max(100, 200) == 200, 3);
        assert!(math::max(200, 100) == 200, 4);
        assert!(math::max(100, 100) == 100, 5);
    }

    #[test]
    fun test_min_max_u128() {
        assert!(math::min_u128(100, 200) == 100, 0);
        assert!(math::max_u128(100, 200) == 200, 1);
    }
}

