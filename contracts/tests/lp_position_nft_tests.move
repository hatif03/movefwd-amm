/// Unit tests for LP Position NFT module
#[test_only]
module sui_amm::lp_position_nft_tests {
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::object::{Self, ID};
    use sui::clock::{Self, Clock};
    
    use sui_amm::lp_position_nft::{Self, LPPositionNFT, LPPositionManager};

    // ============ Test Setup ============

    const ALICE: address = @0xA;
    const BOB: address = @0xB;

    fun setup_test(): Scenario {
        ts::begin(ALICE)
    }

    fun create_test_clock(scenario: &mut Scenario): Clock {
        ts::next_tx(scenario, ALICE);
        clock::create_for_testing(ts::ctx(scenario))
    }

    // ============ Manager Tests ============

    #[test]
    fun test_create_manager() {
        let mut scenario = setup_test();
        ts::next_tx(&mut scenario, ALICE);
        
        let pool_id = object::id_from_address(@0x1);
        let manager = lp_position_nft::create_manager(pool_id, ts::ctx(&mut scenario));
        
        assert!(lp_position_nft::manager_pool_id(&manager) == pool_id, 0);
        assert!(lp_position_nft::manager_total_positions(&manager) == 0, 1);
        
        // Clean up
        let LPPositionManager { id, pool_id: _, total_positions: _ } = manager;
        object::delete(id);
        
        ts::end(scenario);
    }

    // ============ Mint Tests ============

    #[test]
    fun test_mint_position() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        ts::next_tx(&mut scenario, ALICE);
        
        let pool_id = object::id_from_address(@0x1);
        let mut manager = lp_position_nft::create_manager(pool_id, ts::ctx(&mut scenario));
        
        let position = lp_position_nft::mint(
            &mut manager,
            pool_id,
            10000, // lp_tokens
            5000,  // initial_amount_a
            5000,  // initial_amount_b
            0,     // fee_growth_a
            0,     // fee_growth_b
            &clock,
            ts::ctx(&mut scenario),
        );
        
        assert!(lp_position_nft::lp_tokens(&position) == 10000, 0);
        assert!(lp_position_nft::pool_id(&position) == pool_id, 1);
        assert!(lp_position_nft::manager_total_positions(&manager) == 1, 2);
        
        let (fees_a, fees_b) = lp_position_nft::accumulated_fees(&position);
        assert!(fees_a == 0, 3);
        assert!(fees_b == 0, 4);
        
        let (initial_a, initial_b) = lp_position_nft::initial_amounts(&position);
        assert!(initial_a == 5000, 5);
        assert!(initial_b == 5000, 6);
        
        // Clean up
        lp_position_nft::destroy_for_testing(position);
        let LPPositionManager { id, pool_id: _, total_positions: _ } = manager;
        object::delete(id);
        clock::destroy_for_testing(clock);
        
        ts::end(scenario);
    }

    // ============ LP Token Management Tests ============

    #[test]
    fun test_add_lp_tokens() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        ts::next_tx(&mut scenario, ALICE);
        
        let pool_id = object::id_from_address(@0x1);
        let mut manager = lp_position_nft::create_manager(pool_id, ts::ctx(&mut scenario));
        
        let mut position = lp_position_nft::mint(
            &mut manager,
            pool_id,
            10000,
            5000,
            5000,
            0,
            0,
            &clock,
            ts::ctx(&mut scenario),
        );
        
        // Add more LP tokens
        lp_position_nft::add_lp_tokens(&mut position, 5000, 2500, 2500, &clock);
        
        assert!(lp_position_nft::lp_tokens(&position) == 15000, 0);
        
        let (initial_a, initial_b) = lp_position_nft::initial_amounts(&position);
        assert!(initial_a == 7500, 1);
        assert!(initial_b == 7500, 2);
        
        // Clean up
        lp_position_nft::destroy_for_testing(position);
        let LPPositionManager { id, pool_id: _, total_positions: _ } = manager;
        object::delete(id);
        clock::destroy_for_testing(clock);
        
        ts::end(scenario);
    }

    #[test]
    fun test_remove_lp_tokens() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        ts::next_tx(&mut scenario, ALICE);
        
        let pool_id = object::id_from_address(@0x1);
        let mut manager = lp_position_nft::create_manager(pool_id, ts::ctx(&mut scenario));
        
        let mut position = lp_position_nft::mint(
            &mut manager,
            pool_id,
            10000,
            5000,
            5000,
            0,
            0,
            &clock,
            ts::ctx(&mut scenario),
        );
        
        // Remove some LP tokens
        lp_position_nft::remove_lp_tokens(&mut position, 3000, &clock);
        
        assert!(lp_position_nft::lp_tokens(&position) == 7000, 0);
        
        // Clean up
        lp_position_nft::destroy_for_testing(position);
        let LPPositionManager { id, pool_id: _, total_positions: _ } = manager;
        object::delete(id);
        clock::destroy_for_testing(clock);
        
        ts::end(scenario);
    }

    #[test]
    fun test_update_lp_tokens() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        ts::next_tx(&mut scenario, ALICE);
        
        let pool_id = object::id_from_address(@0x1);
        let mut manager = lp_position_nft::create_manager(pool_id, ts::ctx(&mut scenario));
        
        let mut position = lp_position_nft::mint(
            &mut manager,
            pool_id,
            10000,
            5000,
            5000,
            0,
            0,
            &clock,
            ts::ctx(&mut scenario),
        );
        
        // Update LP tokens directly
        lp_position_nft::update_lp_tokens(&mut position, 8000, &clock);
        
        assert!(lp_position_nft::lp_tokens(&position) == 8000, 0);
        
        // Clean up
        lp_position_nft::destroy_for_testing(position);
        let LPPositionManager { id, pool_id: _, total_positions: _ } = manager;
        object::delete(id);
        clock::destroy_for_testing(clock);
        
        ts::end(scenario);
    }

    // ============ Fee Tests ============

    #[test]
    fun test_update_fees() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        ts::next_tx(&mut scenario, ALICE);
        
        let pool_id = object::id_from_address(@0x1);
        let mut manager = lp_position_nft::create_manager(pool_id, ts::ctx(&mut scenario));
        
        let mut position = lp_position_nft::mint(
            &mut manager,
            pool_id,
            1000000000000000000, // 10^18 LP tokens for precision
            5000,
            5000,
            0,
            0,
            &clock,
            ts::ctx(&mut scenario),
        );
        
        // Simulate fee growth
        let new_fee_growth_a = 1000000000000000000u128; // 10^18 (1 token per LP token)
        let new_fee_growth_b = 500000000000000000u128;  // 0.5 * 10^18
        
        lp_position_nft::update_fees(&mut position, new_fee_growth_a, new_fee_growth_b, &clock);
        
        let (fees_a, fees_b) = lp_position_nft::accumulated_fees(&position);
        assert!(fees_a > 0, 0);
        
        // Clean up
        lp_position_nft::destroy_for_testing(position);
        let LPPositionManager { id, pool_id: _, total_positions: _ } = manager;
        object::delete(id);
        clock::destroy_for_testing(clock);
        
        ts::end(scenario);
    }

    #[test]
    fun test_claim_fees() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        ts::next_tx(&mut scenario, ALICE);
        
        let pool_id = object::id_from_address(@0x1);
        let mut manager = lp_position_nft::create_manager(pool_id, ts::ctx(&mut scenario));
        
        let mut position = lp_position_nft::mint(
            &mut manager,
            pool_id,
            10000,
            5000,
            5000,
            0,
            0,
            &clock,
            ts::ctx(&mut scenario),
        );
        
        // Set some fees
        lp_position_nft::set_accumulated_fees(&mut position, 100, 200, &clock);
        
        let (fees_a, fees_b) = lp_position_nft::accumulated_fees(&position);
        assert!(fees_a == 100, 0);
        assert!(fees_b == 200, 1);
        
        // Claim fees
        let (claimed_a, claimed_b) = lp_position_nft::claim_fees(&mut position, &clock);
        
        assert!(claimed_a == 100, 2);
        assert!(claimed_b == 200, 3);
        
        // Fees should be reset
        let (fees_a_after, fees_b_after) = lp_position_nft::accumulated_fees(&position);
        assert!(fees_a_after == 0, 4);
        assert!(fees_b_after == 0, 5);
        
        // Clean up
        lp_position_nft::destroy_for_testing(position);
        let LPPositionManager { id, pool_id: _, total_positions: _ } = manager;
        object::delete(id);
        clock::destroy_for_testing(clock);
        
        ts::end(scenario);
    }

    // ============ Position Value Tests ============

    #[test]
    fun test_calculate_position_value() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        ts::next_tx(&mut scenario, ALICE);
        
        let pool_id = object::id_from_address(@0x1);
        let mut manager = lp_position_nft::create_manager(pool_id, ts::ctx(&mut scenario));
        
        let position = lp_position_nft::mint(
            &mut manager,
            pool_id,
            1000, // 10% of total supply
            5000,
            5000,
            0,
            0,
            &clock,
            ts::ctx(&mut scenario),
        );
        
        // Calculate position value
        let (value_a, value_b) = lp_position_nft::calculate_position_value(
            &position,
            100000, // reserve_a
            200000, // reserve_b
            10000,  // total_supply
        );
        
        // Should get 10% of reserves
        assert!(value_a == 10000, 0);
        assert!(value_b == 20000, 1);
        
        // Clean up
        lp_position_nft::destroy_for_testing(position);
        let LPPositionManager { id, pool_id: _, total_positions: _ } = manager;
        object::delete(id);
        clock::destroy_for_testing(clock);
        
        ts::end(scenario);
    }

    #[test]
    fun test_calculate_pool_share() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        ts::next_tx(&mut scenario, ALICE);
        
        let pool_id = object::id_from_address(@0x1);
        let mut manager = lp_position_nft::create_manager(pool_id, ts::ctx(&mut scenario));
        
        let position = lp_position_nft::mint(
            &mut manager,
            pool_id,
            2500, // 25% of total supply
            5000,
            5000,
            0,
            0,
            &clock,
            ts::ctx(&mut scenario),
        );
        
        // Calculate pool share (in basis points)
        let share = lp_position_nft::calculate_pool_share(&position, 10000);
        
        // Should be 2500 basis points (25%)
        assert!(share == 2500, 0);
        
        // Clean up
        lp_position_nft::destroy_for_testing(position);
        let LPPositionManager { id, pool_id: _, total_positions: _ } = manager;
        object::delete(id);
        clock::destroy_for_testing(clock);
        
        ts::end(scenario);
    }

    // ============ Burn Tests ============

    #[test]
    fun test_burn_position() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        ts::next_tx(&mut scenario, ALICE);
        
        let pool_id = object::id_from_address(@0x1);
        let mut manager = lp_position_nft::create_manager(pool_id, ts::ctx(&mut scenario));
        
        let position = lp_position_nft::mint(
            &mut manager,
            pool_id,
            10000,
            5000,
            5000,
            0,
            0,
            &clock,
            ts::ctx(&mut scenario),
        );
        
        // Burn the position
        lp_position_nft::burn(&mut manager, position, ts::ctx(&scenario));
        
        // Manager should still track that a position was created
        assert!(lp_position_nft::manager_total_positions(&manager) == 1, 0);
        
        // Clean up
        let LPPositionManager { id, pool_id: _, total_positions: _ } = manager;
        object::delete(id);
        clock::destroy_for_testing(clock);
        
        ts::end(scenario);
    }

    // ============ Timestamp Tests ============

    #[test]
    fun test_timestamps() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Set clock to specific time
        clock::set_for_testing(&mut clock, 1000000);
        
        ts::next_tx(&mut scenario, ALICE);
        
        let pool_id = object::id_from_address(@0x1);
        let mut manager = lp_position_nft::create_manager(pool_id, ts::ctx(&mut scenario));
        
        let position = lp_position_nft::mint(
            &mut manager,
            pool_id,
            10000,
            5000,
            5000,
            0,
            0,
            &clock,
            ts::ctx(&mut scenario),
        );
        
        assert!(lp_position_nft::created_at(&position) == 1000000, 0);
        assert!(lp_position_nft::last_updated(&position) == 1000000, 1);
        
        // Clean up
        lp_position_nft::destroy_for_testing(position);
        let LPPositionManager { id, pool_id: _, total_positions: _ } = manager;
        object::delete(id);
        clock::destroy_for_testing(clock);
        
        ts::end(scenario);
    }

    // ============ Multiple Position Tests ============

    #[test]
    fun test_multiple_positions() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        ts::next_tx(&mut scenario, ALICE);
        
        let pool_id = object::id_from_address(@0x1);
        let mut manager = lp_position_nft::create_manager(pool_id, ts::ctx(&mut scenario));
        
        // Mint first position
        let position1 = lp_position_nft::mint(
            &mut manager,
            pool_id,
            10000,
            5000,
            5000,
            0,
            0,
            &clock,
            ts::ctx(&mut scenario),
        );
        
        // Mint second position
        let position2 = lp_position_nft::mint(
            &mut manager,
            pool_id,
            20000,
            10000,
            10000,
            0,
            0,
            &clock,
            ts::ctx(&mut scenario),
        );
        
        assert!(lp_position_nft::manager_total_positions(&manager) == 2, 0);
        assert!(lp_position_nft::lp_tokens(&position1) == 10000, 1);
        assert!(lp_position_nft::lp_tokens(&position2) == 20000, 2);
        
        // Clean up
        lp_position_nft::destroy_for_testing(position1);
        lp_position_nft::destroy_for_testing(position2);
        let LPPositionManager { id, pool_id: _, total_positions: _ } = manager;
        object::delete(id);
        clock::destroy_for_testing(clock);
        
        ts::end(scenario);
    }
}

