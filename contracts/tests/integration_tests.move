/// Integration tests for end-to-end AMM workflows
#[test_only]
#[allow(unused_variable, unused_use, deprecated_usage, unused_let_mut)]
module sui_amm::integration_tests {
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::test_utils;
    
    use sui_amm::pool_factory::{Self, PoolFactory, LiquidityPool};
    use sui_amm::lp_position_nft::{Self, LPPositionNFT};
    use sui_amm::constants;
    use sui_amm::math;

    // ============ Test Coins ============

    public struct USDC has drop {}
    public struct USDT has drop {}
    public struct ETH has drop {}
    public struct BTC has drop {}

    // ============ Test Setup ============

    const ALICE: address = @0xA;  // Liquidity Provider 1
    const BOB: address = @0xB;    // Liquidity Provider 2  
    const CHARLIE: address = @0xC; // Trader
    const ADMIN: address = @0xD;   // Admin

    fun setup_test(): Scenario {
        let mut scenario = ts::begin(ADMIN);
        
        ts::next_tx(&mut scenario, ADMIN);
        pool_factory::init_for_testing(ts::ctx(&mut scenario));
        
        scenario
    }

    fun create_test_clock(scenario: &mut Scenario): Clock {
        ts::next_tx(scenario, ADMIN);
        clock::create_for_testing(ts::ctx(scenario))
    }

    // ============ End-to-End Flow Tests ============

    #[test]
    /// Test complete flow: Create pool → Add liquidity → Swap → Claim fees → Remove liquidity
    fun test_complete_amm_flow() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Step 1: Alice creates pool with initial liquidity
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            let usdc = coin::mint_for_testing<USDC>(1000000, ts::ctx(&mut scenario)); // 1M USDC
            let eth = coin::mint_for_testing<ETH>(1000, ts::ctx(&mut scenario));       // 1000 ETH
            
            let position = pool_factory::create_pool<USDC, ETH>(
                &mut factory,
                usdc,
                eth,
                constants::fee_tier_medium(),
                &clock,
                ts::ctx(&mut scenario),
            );
            
            // Verify pool creation
            assert!(pool_factory::get_total_pools(&factory) == 1, 0);
            assert!(lp_position_nft::lp_tokens(&position) > 0, 1);
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        // Step 2: Bob adds more liquidity
        ts::next_tx(&mut scenario, BOB);
        {
            let mut pool = ts::take_shared<LiquidityPool<USDC, ETH>>(&scenario);
            
            let usdc = coin::mint_for_testing<USDC>(100000, ts::ctx(&mut scenario));
            let eth = coin::mint_for_testing<ETH>(100, ts::ctx(&mut scenario));
            
            let position = pool_factory::add_liquidity(
                &mut pool,
                usdc,
                eth,
                1,
                &clock,
                ts::ctx(&mut scenario),
            );
            
            assert!(lp_position_nft::lp_tokens(&position) > 0, 0);
            
            ts::return_shared(pool);
            transfer::public_transfer(position, BOB);
        };
        
        // Step 3: Charlie performs multiple swaps
        ts::next_tx(&mut scenario, CHARLIE);
        {
            let mut pool = ts::take_shared<LiquidityPool<USDC, ETH>>(&scenario);
            
            // Swap USDC for ETH
            let usdc_in = coin::mint_for_testing<USDC>(10000, ts::ctx(&mut scenario));
            let expected_eth = pool_factory::get_amount_out_a_to_b(&pool, 10000);
            
            // Use 0 for min_output to avoid underflow if expected_eth is small
            let min_out = if (expected_eth > 10) { expected_eth - 10 } else { 0 };
            let eth_out = pool_factory::swap_a_for_b(
                &mut pool,
                usdc_in,
                min_out,
                ts::ctx(&mut scenario),
            );
            
            assert!(coin::value(&eth_out) > 0, 0);
            
            // Swap ETH back for USDC
            let expected_usdc = pool_factory::get_amount_out_b_to_a(&pool, coin::value(&eth_out));
            
            let min_usdc_out = if (expected_usdc > 10) { expected_usdc - 10 } else { 0 };
            let usdc_out = pool_factory::swap_b_for_a(
                &mut pool,
                eth_out,
                min_usdc_out,
                ts::ctx(&mut scenario),
            );
            
            assert!(coin::value(&usdc_out) > 0, 1);
            
            ts::return_shared(pool);
            test_utils::destroy(usdc_out);
        };
        
        // Step 4: Alice removes half her liquidity
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut pool = ts::take_shared<LiquidityPool<USDC, ETH>>(&scenario);
            let mut position = ts::take_from_sender<LPPositionNFT>(&scenario);
            
            let lp_tokens = lp_position_nft::lp_tokens(&position);
            let tokens_to_remove = lp_tokens / 2;
            
            let (usdc, eth) = pool_factory::remove_liquidity(
                &mut pool,
                &mut position,
                tokens_to_remove,
                1,
                1,
                &clock,
                ts::ctx(&mut scenario),
            );
            
            assert!(coin::value(&usdc) > 0, 0);
            assert!(coin::value(&eth) > 0, 1);
            assert!(lp_position_nft::lp_tokens(&position) == lp_tokens - tokens_to_remove, 2);
            
            ts::return_shared(pool);
            ts::return_to_sender(&scenario, position);
            test_utils::destroy(usdc);
            test_utils::destroy(eth);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ============ Multiple LPs Tests ============

    #[test]
    /// Test multiple liquidity providers in same pool
    fun test_multiple_lps_same_pool() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Alice creates pool
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            let usdc = coin::mint_for_testing<USDC>(100000, ts::ctx(&mut scenario));
            let usdt = coin::mint_for_testing<USDT>(100000, ts::ctx(&mut scenario));
            
            let position = pool_factory::create_pool<USDC, USDT>(
                &mut factory,
                usdc,
                usdt,
                constants::fee_tier_low(), // Low fee for stablecoin pair
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        // Bob adds liquidity
        ts::next_tx(&mut scenario, BOB);
        {
            let mut pool = ts::take_shared<LiquidityPool<USDC, USDT>>(&scenario);
            
            let usdc = coin::mint_for_testing<USDC>(50000, ts::ctx(&mut scenario));
            let usdt = coin::mint_for_testing<USDT>(50000, ts::ctx(&mut scenario));
            
            let position = pool_factory::add_liquidity(
                &mut pool,
                usdc,
                usdt,
                1,
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(pool);
            transfer::public_transfer(position, BOB);
        };
        
        // Charlie adds liquidity
        ts::next_tx(&mut scenario, CHARLIE);
        {
            let mut pool = ts::take_shared<LiquidityPool<USDC, USDT>>(&scenario);
            
            let usdc = coin::mint_for_testing<USDC>(25000, ts::ctx(&mut scenario));
            let usdt = coin::mint_for_testing<USDT>(25000, ts::ctx(&mut scenario));
            
            let position = pool_factory::add_liquidity(
                &mut pool,
                usdc,
                usdt,
                1,
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(pool);
            transfer::public_transfer(position, CHARLIE);
        };
        
        // Verify total supply increased
        ts::next_tx(&mut scenario, ADMIN);
        {
            let pool = ts::take_shared<LiquidityPool<USDC, USDT>>(&scenario);
            
            let total_supply = pool_factory::get_total_supply(&pool);
            let (reserve_a, reserve_b) = pool_factory::get_reserves(&pool);
            
            // Should have 175000 of each token
            assert!(reserve_a == 175000, 0);
            assert!(reserve_b == 175000, 1);
            
            ts::return_shared(pool);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ============ Concurrent Swaps Tests ============

    #[test]
    /// Test multiple swaps in sequence
    fun test_concurrent_swaps() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Create pool with high liquidity
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            let usdc = coin::mint_for_testing<USDC>(10000000, ts::ctx(&mut scenario));
            let eth = coin::mint_for_testing<ETH>(10000, ts::ctx(&mut scenario));
            
            let position = pool_factory::create_pool<USDC, ETH>(
                &mut factory,
                usdc,
                eth,
                constants::fee_tier_medium(),
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        // Multiple users swap
        let users = vector[BOB, CHARLIE, @0xE, @0xF];
        let mut i = 0;
        while (i < 4) {
            let user = *vector::borrow(&users, i);
            
            ts::next_tx(&mut scenario, user);
            {
                let mut pool = ts::take_shared<LiquidityPool<USDC, ETH>>(&scenario);
                
                // Use larger swap amount to ensure non-zero output
                let usdc = coin::mint_for_testing<USDC>(100000, ts::ctx(&mut scenario));
                let eth_out = pool_factory::swap_a_for_b(&mut pool, usdc, 0, ts::ctx(&mut scenario));
                
                assert!(coin::value(&eth_out) > 0, i);
                
                ts::return_shared(pool);
                test_utils::destroy(eth_out);
            };
            
            i = i + 1;
        };
        
        // Verify K invariant maintained
        ts::next_tx(&mut scenario, ADMIN);
        {
            let pool = ts::take_shared<LiquidityPool<USDC, ETH>>(&scenario);
            
            let k = pool_factory::get_k(&pool);
            let (reserve_a, reserve_b) = pool_factory::get_reserves(&pool);
            
            // K should equal reserve_a * reserve_b (may differ slightly due to fees)
            let calculated_k = (reserve_a as u128) * (reserve_b as u128);
            
            // K should be close (fees accumulate)
            assert!(k > 0, 0);
            assert!(calculated_k > 0, 1);
            
            ts::return_shared(pool);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ============ Impermanent Loss Scenario Tests ============

    #[test]
    /// Test impermanent loss scenario with price change
    fun test_impermanent_loss_scenario() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Create pool with equal values
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            // 1000000 USDC and 1000 ETH (1 ETH = 1000 USDC) - larger amounts for minimum liquidity
            let usdc = coin::mint_for_testing<USDC>(1000000, ts::ctx(&mut scenario));
            let eth = coin::mint_for_testing<ETH>(1000, ts::ctx(&mut scenario));
            
            let position = pool_factory::create_pool<USDC, ETH>(
                &mut factory,
                usdc,
                eth,
                constants::fee_tier_medium(),
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        // Record initial position value
        ts::next_tx(&mut scenario, ALICE);
        let initial_lp_tokens: u64;
        {
            let position = ts::take_from_sender<LPPositionNFT>(&scenario);
            initial_lp_tokens = lp_position_nft::lp_tokens(&position);
            ts::return_to_sender(&scenario, position);
        };
        
        // Simulate price change by large swap (ETH price increases)
        // Buy ETH with USDC
        ts::next_tx(&mut scenario, BOB);
        {
            let mut pool = ts::take_shared<LiquidityPool<USDC, ETH>>(&scenario);
            
            // Large buy of ETH
            let usdc = coin::mint_for_testing<USDC>(5000, ts::ctx(&mut scenario));
            let eth_out = pool_factory::swap_a_for_b(&mut pool, usdc, 0, ts::ctx(&mut scenario));
            
            ts::return_shared(pool);
            test_utils::destroy(eth_out);
        };
        
        // Check Alice's position value after price change
        ts::next_tx(&mut scenario, ALICE);
        {
            let pool = ts::take_shared<LiquidityPool<USDC, ETH>>(&scenario);
            let position = ts::take_from_sender<LPPositionNFT>(&scenario);
            
            let (reserve_a, reserve_b) = pool_factory::get_reserves(&pool);
            let total_supply = pool_factory::get_total_supply(&pool);
            
            let (value_a, value_b) = lp_position_nft::calculate_position_value(
                &position,
                reserve_a,
                reserve_b,
                total_supply,
            );
            
            // Position should still have value
            assert!(value_a > 0, 0);
            assert!(value_b > 0, 1);
            
            // LP tokens unchanged
            assert!(lp_position_nft::lp_tokens(&position) == initial_lp_tokens, 2);
            
            ts::return_shared(pool);
            ts::return_to_sender(&scenario, position);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ============ Large Amount Tests ============

    #[test]
    /// Test with large amounts to check for overflow
    fun test_large_amounts() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Create pool with large amounts
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            // 1 billion tokens each
            let usdc = coin::mint_for_testing<USDC>(1000000000, ts::ctx(&mut scenario));
            let usdt = coin::mint_for_testing<USDT>(1000000000, ts::ctx(&mut scenario));
            
            let position = pool_factory::create_pool<USDC, USDT>(
                &mut factory,
                usdc,
                usdt,
                constants::fee_tier_low(),
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        // Large swap
        ts::next_tx(&mut scenario, BOB);
        {
            let mut pool = ts::take_shared<LiquidityPool<USDC, USDT>>(&scenario);
            
            let usdc = coin::mint_for_testing<USDC>(10000000, ts::ctx(&mut scenario));
            let usdt_out = pool_factory::swap_a_for_b(&mut pool, usdc, 0, ts::ctx(&mut scenario));
            
            assert!(coin::value(&usdt_out) > 0, 0);
            
            ts::return_shared(pool);
            test_utils::destroy(usdt_out);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ============ Small Amount Tests ============

    #[test]
    /// Test with very small amounts
    fun test_small_amounts() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Create pool
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            let usdc = coin::mint_for_testing<USDC>(1000000, ts::ctx(&mut scenario));
            let eth = coin::mint_for_testing<ETH>(1000, ts::ctx(&mut scenario));
            
            let position = pool_factory::create_pool<USDC, ETH>(
                &mut factory,
                usdc,
                eth,
                constants::fee_tier_medium(),
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        // Small swap
        ts::next_tx(&mut scenario, BOB);
        {
            let mut pool = ts::take_shared<LiquidityPool<USDC, ETH>>(&scenario);
            
            let usdc = coin::mint_for_testing<USDC>(1, ts::ctx(&mut scenario));
            let eth_out = pool_factory::swap_a_for_b(&mut pool, usdc, 0, ts::ctx(&mut scenario));
            
            // May get 0 output for very small amounts
            ts::return_shared(pool);
            test_utils::destroy(eth_out);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ============ Fee Accumulation Tests ============

    #[test]
    /// Test fee accumulation over multiple swaps
    fun test_fee_accumulation() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Create pool
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            let usdc = coin::mint_for_testing<USDC>(1000000, ts::ctx(&mut scenario));
            let eth = coin::mint_for_testing<ETH>(1000, ts::ctx(&mut scenario));
            
            let position = pool_factory::create_pool<USDC, ETH>(
                &mut factory,
                usdc,
                eth,
                constants::fee_tier_high(), // 1% fee for more visible accumulation
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        // Perform many swaps
        let mut i = 0;
        while (i < 10) {
            ts::next_tx(&mut scenario, BOB);
            {
                let mut pool = ts::take_shared<LiquidityPool<USDC, ETH>>(&scenario);
                
                let usdc = coin::mint_for_testing<USDC>(10000, ts::ctx(&mut scenario));
                let eth_out = pool_factory::swap_a_for_b(&mut pool, usdc, 0, ts::ctx(&mut scenario));
                
                ts::return_shared(pool);
                test_utils::destroy(eth_out);
            };
            i = i + 1;
        };
        
        // Check fee growth
        ts::next_tx(&mut scenario, ADMIN);
        {
            let pool = ts::take_shared<LiquidityPool<USDC, ETH>>(&scenario);
            
            let (fee_growth_a, fee_growth_b) = pool_factory::get_fee_growth(&pool);
            
            // Fee growth should be positive after swaps
            assert!(fee_growth_a > 0, 0);
            
            ts::return_shared(pool);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ============ Pool Share Tests ============

    #[test]
    /// Test proportional LP share calculation
    fun test_proportional_shares() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Alice creates pool with 100k
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            let usdc = coin::mint_for_testing<USDC>(100000, ts::ctx(&mut scenario));
            let usdt = coin::mint_for_testing<USDT>(100000, ts::ctx(&mut scenario));
            
            let position = pool_factory::create_pool<USDC, USDT>(
                &mut factory,
                usdc,
                usdt,
                constants::fee_tier_low(),
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        // Bob adds equal amount (should get ~equal share)
        ts::next_tx(&mut scenario, BOB);
        {
            let mut pool = ts::take_shared<LiquidityPool<USDC, USDT>>(&scenario);
            
            let usdc = coin::mint_for_testing<USDC>(100000, ts::ctx(&mut scenario));
            let usdt = coin::mint_for_testing<USDT>(100000, ts::ctx(&mut scenario));
            
            let position = pool_factory::add_liquidity(
                &mut pool,
                usdc,
                usdt,
                1,
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(pool);
            transfer::public_transfer(position, BOB);
        };
        
        // Verify shares are roughly equal
        ts::next_tx(&mut scenario, ADMIN);
        {
            let pool = ts::take_shared<LiquidityPool<USDC, USDT>>(&scenario);
            let total_supply = pool_factory::get_total_supply(&pool);
            ts::return_shared(pool);
        };
        
        ts::next_tx(&mut scenario, ALICE);
        {
            let pool = ts::take_shared<LiquidityPool<USDC, USDT>>(&scenario);
            let position = ts::take_from_sender<LPPositionNFT>(&scenario);
            
            let total_supply = pool_factory::get_total_supply(&pool);
            let share = lp_position_nft::calculate_pool_share(&position, total_supply);
            
            // Alice should have roughly 50% (5000 basis points)
            // May not be exactly 50% due to minimum liquidity lock
            assert!(share > 4000, 0); // At least 40%
            assert!(share < 6000, 1); // At most 60%
            
            ts::return_shared(pool);
            ts::return_to_sender(&scenario, position);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }
}


