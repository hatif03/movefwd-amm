/// Unit tests for Pool Factory module
#[test_only]
module sui_amm::pool_factory_tests {
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::test_utils;
    
    use sui_amm::pool_factory::{Self, PoolFactory, PoolFactoryAdminCap, LiquidityPool};
    use sui_amm::lp_position_nft::{Self, LPPositionNFT};
    use sui_amm::constants;

    // ============ Test Coins ============

    public struct COIN_A has drop {}
    public struct COIN_B has drop {}
    public struct COIN_C has drop {}

    // ============ Test Setup ============

    const ALICE: address = @0xA;
    const BOB: address = @0xB;

    fun setup_test(): Scenario {
        let mut scenario = ts::begin(ALICE);
        
        // Initialize pool factory
        ts::next_tx(&mut scenario, ALICE);
        pool_factory::init_for_testing(ts::ctx(&mut scenario));
        
        scenario
    }

    fun create_test_clock(scenario: &mut Scenario): Clock {
        ts::next_tx(scenario, ALICE);
        clock::create_for_testing(ts::ctx(scenario))
    }

    fun mint_coin<T: drop>(amount: u64, witness: T, scenario: &mut Scenario): Coin<T> {
        coin::mint_for_testing<T>(amount, ts::ctx(scenario))
    }

    // ============ Pool Creation Tests ============

    #[test]
    fun test_create_pool() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            let coin_a = mint_coin(10000, COIN_A {}, &mut scenario);
            let coin_b = mint_coin(10000, COIN_B {}, &mut scenario);
            
            let position = pool_factory::create_pool<COIN_A, COIN_B>(
                &mut factory,
                coin_a,
                coin_b,
                constants::fee_tier_medium(), // 0.3%
                &clock,
                ts::ctx(&mut scenario),
            );
            
            // Verify position was created
            assert!(lp_position_nft::lp_tokens(&position) > 0, 0);
            
            // Verify factory state
            assert!(pool_factory::get_total_pools(&factory) == 1, 1);
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_pool_reserves() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            let coin_a = mint_coin(10000, COIN_A {}, &mut scenario);
            let coin_b = mint_coin(20000, COIN_B {}, &mut scenario);
            
            let position = pool_factory::create_pool<COIN_A, COIN_B>(
                &mut factory,
                coin_a,
                coin_b,
                constants::fee_tier_medium(),
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        // Check pool reserves
        ts::next_tx(&mut scenario, ALICE);
        {
            let pool = ts::take_shared<LiquidityPool<COIN_A, COIN_B>>(&scenario);
            
            let (reserve_a, reserve_b) = pool_factory::get_reserves(&pool);
            assert!(reserve_a == 10000, 0);
            assert!(reserve_b == 20000, 1);
            
            ts::return_shared(pool);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ============ Swap Tests ============

    #[test]
    fun test_swap_a_for_b() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Create pool
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            let coin_a = mint_coin(100000, COIN_A {}, &mut scenario);
            let coin_b = mint_coin(100000, COIN_B {}, &mut scenario);
            
            let position = pool_factory::create_pool<COIN_A, COIN_B>(
                &mut factory,
                coin_a,
                coin_b,
                constants::fee_tier_medium(),
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        // Perform swap
        ts::next_tx(&mut scenario, BOB);
        {
            let mut pool = ts::take_shared<LiquidityPool<COIN_A, COIN_B>>(&scenario);
            
            let swap_amount = 1000;
            let coin_in = mint_coin(swap_amount, COIN_A {}, &mut scenario);
            
            // Calculate expected output
            let expected_out = pool_factory::get_amount_out_a_to_b(&pool, swap_amount);
            
            let coin_out = pool_factory::swap_a_for_b(
                &mut pool,
                coin_in,
                expected_out - 10, // Allow small slippage
                ts::ctx(&mut scenario),
            );
            
            let received = coin::value(&coin_out);
            assert!(received >= expected_out - 10, 0);
            assert!(received > 0, 1);
            
            // Verify reserves changed
            let (reserve_a, reserve_b) = pool_factory::get_reserves(&pool);
            assert!(reserve_a > 100000, 2); // Increased
            assert!(reserve_b < 100000, 3); // Decreased
            
            ts::return_shared(pool);
            test_utils::destroy(coin_out);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_swap_b_for_a() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Create pool
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            let coin_a = mint_coin(100000, COIN_A {}, &mut scenario);
            let coin_b = mint_coin(100000, COIN_B {}, &mut scenario);
            
            let position = pool_factory::create_pool<COIN_A, COIN_B>(
                &mut factory,
                coin_a,
                coin_b,
                constants::fee_tier_medium(),
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        // Perform swap
        ts::next_tx(&mut scenario, BOB);
        {
            let mut pool = ts::take_shared<LiquidityPool<COIN_A, COIN_B>>(&scenario);
            
            let swap_amount = 1000;
            let coin_in = mint_coin(swap_amount, COIN_B {}, &mut scenario);
            
            let expected_out = pool_factory::get_amount_out_b_to_a(&pool, swap_amount);
            
            let coin_out = pool_factory::swap_b_for_a(
                &mut pool,
                coin_in,
                expected_out - 10,
                ts::ctx(&mut scenario),
            );
            
            let received = coin::value(&coin_out);
            assert!(received >= expected_out - 10, 0);
            
            ts::return_shared(pool);
            test_utils::destroy(coin_out);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ============ Liquidity Tests ============

    #[test]
    fun test_add_liquidity() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Create pool
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            let coin_a = mint_coin(100000, COIN_A {}, &mut scenario);
            let coin_b = mint_coin(100000, COIN_B {}, &mut scenario);
            
            let position = pool_factory::create_pool<COIN_A, COIN_B>(
                &mut factory,
                coin_a,
                coin_b,
                constants::fee_tier_medium(),
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        // Add more liquidity
        ts::next_tx(&mut scenario, BOB);
        {
            let mut pool = ts::take_shared<LiquidityPool<COIN_A, COIN_B>>(&scenario);
            
            let coin_a = mint_coin(10000, COIN_A {}, &mut scenario);
            let coin_b = mint_coin(10000, COIN_B {}, &mut scenario);
            
            let total_supply_before = pool_factory::get_total_supply(&pool);
            
            let position = pool_factory::add_liquidity(
                &mut pool,
                coin_a,
                coin_b,
                1, // min LP tokens
                &clock,
                ts::ctx(&mut scenario),
            );
            
            let total_supply_after = pool_factory::get_total_supply(&pool);
            
            assert!(total_supply_after > total_supply_before, 0);
            assert!(lp_position_nft::lp_tokens(&position) > 0, 1);
            
            ts::return_shared(pool);
            transfer::public_transfer(position, BOB);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_remove_liquidity() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Create pool
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            let coin_a = mint_coin(100000, COIN_A {}, &mut scenario);
            let coin_b = mint_coin(100000, COIN_B {}, &mut scenario);
            
            let position = pool_factory::create_pool<COIN_A, COIN_B>(
                &mut factory,
                coin_a,
                coin_b,
                constants::fee_tier_medium(),
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        // Remove some liquidity
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut pool = ts::take_shared<LiquidityPool<COIN_A, COIN_B>>(&scenario);
            let mut position = ts::take_from_sender<LPPositionNFT>(&scenario);
            
            let lp_tokens_before = lp_position_nft::lp_tokens(&position);
            let tokens_to_remove = lp_tokens_before / 2;
            
            let (coin_a, coin_b) = pool_factory::remove_liquidity(
                &mut pool,
                &mut position,
                tokens_to_remove,
                1, // min amount a
                1, // min amount b
                &clock,
                ts::ctx(&mut scenario),
            );
            
            assert!(coin::value(&coin_a) > 0, 0);
            assert!(coin::value(&coin_b) > 0, 1);
            assert!(lp_position_nft::lp_tokens(&position) == lp_tokens_before - tokens_to_remove, 2);
            
            ts::return_shared(pool);
            ts::return_to_sender(&scenario, position);
            test_utils::destroy(coin_a);
            test_utils::destroy(coin_b);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ============ Fee Tier Tests ============

    #[test]
    fun test_different_fee_tiers() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Create pool with low fee
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            let coin_a = mint_coin(10000, COIN_A {}, &mut scenario);
            let coin_b = mint_coin(10000, COIN_B {}, &mut scenario);
            
            let position = pool_factory::create_pool<COIN_A, COIN_B>(
                &mut factory,
                coin_a,
                coin_b,
                constants::fee_tier_low(), // 0.05%
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        // Check fee tier
        ts::next_tx(&mut scenario, ALICE);
        {
            let pool = ts::take_shared<LiquidityPool<COIN_A, COIN_B>>(&scenario);
            assert!(pool_factory::get_fee_tier(&pool) == constants::fee_tier_low(), 0);
            ts::return_shared(pool);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ============ Price Impact Tests ============

    #[test]
    fun test_price_impact() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Create pool
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            let coin_a = mint_coin(100000, COIN_A {}, &mut scenario);
            let coin_b = mint_coin(100000, COIN_B {}, &mut scenario);
            
            let position = pool_factory::create_pool<COIN_A, COIN_B>(
                &mut factory,
                coin_a,
                coin_b,
                constants::fee_tier_medium(),
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        // Check price impact
        ts::next_tx(&mut scenario, ALICE);
        {
            let pool = ts::take_shared<LiquidityPool<COIN_A, COIN_B>>(&scenario);
            
            // Small swap should have low impact
            let impact_small = pool_factory::get_price_impact(&pool, 100, true);
            
            // Large swap should have higher impact
            let impact_large = pool_factory::get_price_impact(&pool, 10000, true);
            
            assert!(impact_large > impact_small, 0);
            
            ts::return_shared(pool);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ============ Admin Tests ============

    #[test]
    fun test_pause_pool() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Create pool
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            let coin_a = mint_coin(10000, COIN_A {}, &mut scenario);
            let coin_b = mint_coin(10000, COIN_B {}, &mut scenario);
            
            let position = pool_factory::create_pool<COIN_A, COIN_B>(
                &mut factory,
                coin_a,
                coin_b,
                constants::fee_tier_medium(),
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        // Pause pool
        ts::next_tx(&mut scenario, ALICE);
        {
            let admin_cap = ts::take_from_sender<PoolFactoryAdminCap>(&scenario);
            let mut pool = ts::take_shared<LiquidityPool<COIN_A, COIN_B>>(&scenario);
            
            assert!(!pool_factory::is_paused(&pool), 0);
            
            pool_factory::set_pool_paused(&admin_cap, &mut pool, true);
            
            assert!(pool_factory::is_paused(&pool), 1);
            
            ts::return_to_sender(&scenario, admin_cap);
            ts::return_shared(pool);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ============ K Invariant Tests ============

    #[test]
    fun test_k_invariant() {
        let mut scenario = setup_test();
        let mut clock = create_test_clock(&mut scenario);
        
        // Create pool
        ts::next_tx(&mut scenario, ALICE);
        {
            let mut factory = ts::take_shared<PoolFactory>(&scenario);
            
            let coin_a = mint_coin(100000, COIN_A {}, &mut scenario);
            let coin_b = mint_coin(100000, COIN_B {}, &mut scenario);
            
            let position = pool_factory::create_pool<COIN_A, COIN_B>(
                &mut factory,
                coin_a,
                coin_b,
                constants::fee_tier_medium(),
                &clock,
                ts::ctx(&mut scenario),
            );
            
            ts::return_shared(factory);
            transfer::public_transfer(position, ALICE);
        };
        
        // Verify K after creation
        ts::next_tx(&mut scenario, ALICE);
        {
            let pool = ts::take_shared<LiquidityPool<COIN_A, COIN_B>>(&scenario);
            
            let k = pool_factory::get_k(&pool);
            let (reserve_a, reserve_b) = pool_factory::get_reserves(&pool);
            
            // K should equal reserve_a * reserve_b
            assert!(k == (reserve_a as u128) * (reserve_b as u128), 0);
            
            ts::return_shared(pool);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }
}

