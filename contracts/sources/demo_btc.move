/// Demo BTC token for testing the AMM
#[allow(unused_use, duplicate_alias)]
module sui_amm::demo_btc {
    use sui::coin::{Self, TreasuryCap};
    use sui::url;
    use std::option;

    /// One-Time Witness for DEMO_BTC
    public struct DEMO_BTC has drop {}

    fun init(witness: DEMO_BTC, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(
            witness,
            8, // decimals
            b"BTC",
            b"Demo Bitcoin",
            b"Demo BTC token for testing Sui AMM",
            option::some(url::new_unsafe_from_bytes(b"https://sui-amm.io/tokens/btc.png")),
            ctx,
        );
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, tx_context::sender(ctx));
    }

    /// Mint DEMO_BTC tokens
    public entry fun mint(
        treasury: &mut TreasuryCap<DEMO_BTC>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let coin = coin::mint(treasury, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }
}

