/// Demo USDC token for testing the AMM
#[allow(unused_use, duplicate_alias)]
module sui_amm::demo_usdc {
    use sui::coin::{Self, TreasuryCap};
    use sui::url;
    use std::option;

    /// One-Time Witness for DEMO_USDC
    public struct DEMO_USDC has drop {}

    fun init(witness: DEMO_USDC, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(
            witness,
            6, // decimals
            b"USDC",
            b"Demo USD Coin",
            b"Demo USDC token for testing Sui AMM",
            option::some(url::new_unsafe_from_bytes(b"https://sui-amm.io/tokens/usdc.png")),
            ctx,
        );
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, tx_context::sender(ctx));
    }

    /// Mint DEMO_USDC tokens
    public entry fun mint(
        treasury: &mut TreasuryCap<DEMO_USDC>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let coin = coin::mint(treasury, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }
}

