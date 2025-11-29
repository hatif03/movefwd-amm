/// Unit tests for Slippage Protection module
#[test_only]
module sui_amm::slippage_tests {
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::clock::{Self, Clock};
    
    use sui_amm::slippage_protection::{Self};

    // ============ Test Setup ============

    const ALICE: address = @0xA;

    fun setup_test(): Scenario {
        ts::begin(ALICE)
    }

    fun create_test_clock(scenario: &mut Scenario): Clock {
        ts::next_tx(scenario, ALICE);
        clock::create_for_testing(ts::ctx(scenario))
    }

    // ============ Min Output Calculation Tests ============

    #[test]
    fun test_calculate_min_output() {
        // 0.5% slippage on 1000
        let min_output = slippage_protection::calculate_min_output(1000, 50);
        // Expected: 1000 * (10000 - 50) / 10000 = 995
        assert!(min_output == 995, 0);
        
        // 1% slippage on 1000
        let min_output_1pct = slippage_protection::calculate_min_output(1000, 100);
        assert!(min_output_1pct == 990, 1);
        
        // 5% slippage on 1000
        let min_output_5pct = slippage_protection::calculate_min_output(1000, 500);
        assert!(min_output_5pct == 950, 2);
        
        // 0% slippage (no tolerance)
        let min_output_zero = slippage_protection::calculate_min_output(1000, 0);
        assert!(min_output_zero == 1000, 3);
    }

    #[test]
    fun test_calculate_min_output_large_amounts() {
        // Large amount with 0.3% slippage
        let min_output = slippage_protection::calculate_min_output(1000000000, 30);
        // Expected: 1000000000 * 9970 / 10000 = 997000000
        assert!(min_output == 997000000, 0);
    }

    // ============ Max Input Calculation Tests ============

    #[test]
    fun test_calculate_max_input() {
        // 0.5% slippage on 1000
        let max_input = slippage_protection::calculate_max_input(1000, 50);
        // Expected: 1000 * (10000 + 50) / 10000 = 1005
        assert!(max_input == 1005, 0);
        
        // 1% slippage on 1000
        let max_input_1pct = slippage_protection::calculate_max_input(1000, 100);
        assert!(max_input_1pct == 1010, 1);
        
        // 5% slippage on 1000
        let max_input_5pct = slippage_protection::calculate_max_input(1000, 500);
        assert!(max_input_5pct == 1050, 2);
    }

    // ============ Deadline Tests ============

    #[test]
    fun test_is_deadline_passed() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Set clock to 1000
        clock::set_for_testing(&mut clock, 1000);
        
        // Deadline in future
        assert!(!slippage_protection::is_deadline_passed(2000, &clock), 0);
        
        // Deadline in past
        assert!(slippage_protection::is_deadline_passed(500, &clock), 1);
        
        // Deadline exactly now
        assert!(!slippage_protection::is_deadline_passed(1000, &clock), 2);
        
        // No deadline (0)
        assert!(!slippage_protection::is_deadline_passed(0, &clock), 3);
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_calculate_deadline() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        clock::set_for_testing(&mut clock, 1000);
        
        // Add 30 seconds
        let deadline = slippage_protection::calculate_deadline(30000, &clock);
        assert!(deadline == 31000, 0);
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_assert_deadline_not_passed() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        clock::set_for_testing(&mut clock, 1000);
        
        // Should not abort - deadline in future
        slippage_protection::assert_deadline_not_passed(2000, &clock);
        
        // Should not abort - no deadline
        slippage_protection::assert_deadline_not_passed(0, &clock);
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ============ User Settings Tests ============

    #[test]
    fun test_create_user_settings() {
        let mut scenario = setup_test();
        ts::next_tx(&mut scenario, ALICE);
        
        let settings = slippage_protection::create_user_settings(
            50,     // 0.5% slippage tolerance
            30000,  // 30 second deadline
            500,    // 5% max price impact
            ts::ctx(&mut scenario),
        );
        
        let (tolerance, deadline, use_protection, max_impact) = 
            slippage_protection::get_user_settings(&settings);
        
        assert!(tolerance == 50, 0);
        assert!(deadline == 30000, 1);
        assert!(use_protection == true, 2);
        assert!(max_impact == 500, 3);
        
        slippage_protection::destroy_user_settings(settings);
        ts::end(scenario);
    }

    #[test]
    fun test_update_slippage_tolerance() {
        let mut scenario = setup_test();
        ts::next_tx(&mut scenario, ALICE);
        
        let mut settings = slippage_protection::create_user_settings(
            50,
            30000,
            500,
            ts::ctx(&mut scenario),
        );
        
        // Update tolerance
        slippage_protection::update_slippage_tolerance(&mut settings, 100);
        
        let (tolerance, _, _, _) = slippage_protection::get_user_settings(&settings);
        assert!(tolerance == 100, 0);
        
        slippage_protection::destroy_user_settings(settings);
        ts::end(scenario);
    }

    #[test]
    fun test_update_deadline() {
        let mut scenario = setup_test();
        ts::next_tx(&mut scenario, ALICE);
        
        let mut settings = slippage_protection::create_user_settings(
            50,
            30000,
            500,
            ts::ctx(&mut scenario),
        );
        
        // Update deadline
        slippage_protection::update_deadline(&mut settings, 60000);
        
        let (_, deadline, _, _) = slippage_protection::get_user_settings(&settings);
        assert!(deadline == 60000, 0);
        
        slippage_protection::destroy_user_settings(settings);
        ts::end(scenario);
    }

    #[test]
    fun test_update_price_impact_protection() {
        let mut scenario = setup_test();
        ts::next_tx(&mut scenario, ALICE);
        
        let mut settings = slippage_protection::create_user_settings(
            50,
            30000,
            500,
            ts::ctx(&mut scenario),
        );
        
        // Disable price impact protection
        slippage_protection::update_price_impact_protection(&mut settings, false, 1000);
        
        let (_, _, use_protection, max_impact) = slippage_protection::get_user_settings(&settings);
        assert!(use_protection == false, 0);
        assert!(max_impact == 1000, 1);
        
        slippage_protection::destroy_user_settings(settings);
        ts::end(scenario);
    }

    // ============ Slippage Assertion Tests ============

    #[test]
    fun test_assert_slippage_ok() {
        // Actual output equals expected
        slippage_protection::assert_slippage_ok(1000, 1000, 50);
        
        // Actual output slightly below expected but within tolerance
        slippage_protection::assert_slippage_ok(1000, 996, 50);
        
        // Actual output above expected (bonus)
        slippage_protection::assert_slippage_ok(1000, 1100, 50);
    }

    #[test]
    #[expected_failure(abort_code = sui_amm::errors::slippage_exceeded())]
    fun test_assert_slippage_fail() {
        // Actual output too low
        slippage_protection::assert_slippage_ok(1000, 900, 50);
    }

    // ============ Price Impact Assertion Tests ============

    #[test]
    fun test_assert_price_impact_ok() {
        // Impact within limit
        slippage_protection::assert_price_impact_ok(100, 500);
        
        // Impact exactly at limit
        slippage_protection::assert_price_impact_ok(500, 500);
        
        // Zero impact
        slippage_protection::assert_price_impact_ok(0, 500);
    }

    #[test]
    #[expected_failure(abort_code = sui_amm::errors::price_impact_too_high())]
    fun test_assert_price_impact_fail() {
        // Impact exceeds limit
        slippage_protection::assert_price_impact_ok(600, 500);
    }

    // ============ Edge Case Tests ============

    #[test]
    fun test_zero_slippage() {
        // Zero slippage tolerance means no tolerance
        let min_output = slippage_protection::calculate_min_output(1000, 0);
        assert!(min_output == 1000, 0);
        
        // Should pass with exact amount
        slippage_protection::assert_slippage_ok(1000, 1000, 0);
    }

    #[test]
    fun test_max_slippage() {
        // 50% slippage tolerance
        let min_output = slippage_protection::calculate_min_output(1000, 5000);
        assert!(min_output == 500, 0);
    }

    #[test]
    fun test_small_amounts() {
        // Small amount with slippage
        let min_output = slippage_protection::calculate_min_output(100, 50);
        // Expected: 100 * 9950 / 10000 = 99 (rounds down)
        assert!(min_output == 99, 0);
        
        // Very small amount
        let min_output_tiny = slippage_protection::calculate_min_output(10, 50);
        assert!(min_output_tiny == 9, 1);
    }
}

