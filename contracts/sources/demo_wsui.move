/// Demo wrapped SUI token for testing the AMM
#[allow(unused_use, duplicate_alias)]
module sui_amm::demo_wsui {
    use sui::coin::{Self, TreasuryCap};
    use sui::url;
    use std::option;

    /// One-Time Witness for DEMO_WSUI
    public struct DEMO_WSUI has drop {}

    fun init(witness: DEMO_WSUI, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(
            witness,
            9, // decimals
            b"WSUI",
            b"Demo Wrapped SUI",
            b"Demo wrapped SUI token for testing Sui AMM",
            option::some(url::new_unsafe_from_bytes(b"https://sui-amm.io/tokens/sui.png")),
            ctx,
        );
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, tx_context::sender(ctx));
    }

    /// Mint DEMO_WSUI tokens
    public entry fun mint(
        treasury: &mut TreasuryCap<DEMO_WSUI>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let coin = coin::mint(treasury, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }
}

