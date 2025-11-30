/// Demo USDT token for testing the AMM
#[allow(unused_use, duplicate_alias)]
module sui_amm::demo_usdt {
    use sui::coin::{Self, TreasuryCap};
    use sui::url;
    use std::option;

    /// One-Time Witness for DEMO_USDT
    public struct DEMO_USDT has drop {}

    fun init(witness: DEMO_USDT, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(
            witness,
            6, // decimals
            b"USDT",
            b"Demo Tether USD",
            b"Demo USDT token for testing Sui AMM",
            option::some(url::new_unsafe_from_bytes(b"https://sui-amm.io/tokens/usdt.png")),
            ctx,
        );
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, tx_context::sender(ctx));
    }

    /// Mint DEMO_USDT tokens
    public entry fun mint(
        treasury: &mut TreasuryCap<DEMO_USDT>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let coin = coin::mint(treasury, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }
}

