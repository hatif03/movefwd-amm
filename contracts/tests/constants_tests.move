/// Unit tests for Constants module
#[test_only]
module sui_amm::constants_tests {
    use sui_amm::constants;

    #[test]
    fun test_fee_tiers() {
        // Verify fee tier values
        assert!(constants::fee_tier_low() == 5, 0);      // 0.05%
        assert!(constants::fee_tier_medium() == 30, 1);  // 0.3%
        assert!(constants::fee_tier_high() == 100, 2);   // 1%
    }

    #[test]
    fun test_is_valid_fee_tier() {
        // Valid tiers
        assert!(constants::is_valid_fee_tier(5), 0);
        assert!(constants::is_valid_fee_tier(30), 1);
        assert!(constants::is_valid_fee_tier(100), 2);
        
        // Invalid tiers
        assert!(!constants::is_valid_fee_tier(0), 3);
        assert!(!constants::is_valid_fee_tier(10), 4);
        assert!(!constants::is_valid_fee_tier(50), 5);
        assert!(!constants::is_valid_fee_tier(200), 6);
    }

    #[test]
    fun test_basis_points() {
        assert!(constants::basis_points() == 10000, 0);
    }

    #[test]
    fun test_protocol_fee_percentage() {
        // 10% of trading fees go to protocol
        assert!(constants::protocol_fee_percentage() == 1000, 0);
    }

    #[test]
    fun test_minimum_liquidity() {
        assert!(constants::minimum_liquidity() == 1000, 0);
    }

    #[test]
    fun test_ratio_tolerance() {
        // 0.5% tolerance
        assert!(constants::ratio_tolerance() == 50, 0);
    }

    #[test]
    fun test_amplification_constants() {
        assert!(constants::default_amplification() == 100, 0);
        assert!(constants::min_amplification() == 1, 1);
        assert!(constants::max_amplification() == 1000000, 2);
        
        // Min should be less than default
        assert!(constants::min_amplification() < constants::default_amplification(), 3);
        
        // Default should be less than max
        assert!(constants::default_amplification() < constants::max_amplification(), 4);
    }

    #[test]
    fun test_precision_constants() {
        assert!(constants::fee_precision() == 1000000, 0);
        assert!(constants::lp_precision() == 1000000000000000000, 1);
    }
}



