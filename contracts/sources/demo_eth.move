/// Demo ETH token for testing the AMM
#[allow(unused_use, duplicate_alias)]
module sui_amm::demo_eth {
    use sui::coin::{Self, TreasuryCap};
    use sui::url;
    use std::option;

    /// One-Time Witness for DEMO_ETH
    public struct DEMO_ETH has drop {}

    fun init(witness: DEMO_ETH, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(
            witness,
            18, // decimals
            b"ETH",
            b"Demo Ethereum",
            b"Demo ETH token for testing Sui AMM",
            option::some(url::new_unsafe_from_bytes(b"https://sui-amm.io/tokens/eth.png")),
            ctx,
        );
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, tx_context::sender(ctx));
    }

    /// Mint DEMO_ETH tokens
    public entry fun mint(
        treasury: &mut TreasuryCap<DEMO_ETH>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let coin = coin::mint(treasury, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }
}

