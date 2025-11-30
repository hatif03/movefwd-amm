$PACKAGE = "0x374b4c8fec99c1f2dd38983fd1624c21d1984ec9258648aab9a5adaaafd70afa"
$FACTORY = "0xeb0bc8869f53adcf10a10b92070d6910289ee54261dcfed387f659c8ffd53ed6"
$USDC_COIN = "0xda4a3a67864f0341350ecb709ccb4780853bbf5c117522c343f2dacae14120ce"
$USDT_COIN = "0x375b68ea44456159c32874a77982174a6b7b4b90c8bb8cb23bee2064ff0b1832"
$CLOCK = "0x6"
$RECIPIENT = "0xfe3df512d14db62f702d0c193564df373e3ba2674ca2d43382ba29597bb0c1fd"

$TYPE_ARGS = "${PACKAGE}::demo_usdc::DEMO_USDC, ${PACKAGE}::demo_usdt::DEMO_USDT"
$MOVE_CALL = "${PACKAGE}::pool_factory::create_pool<${TYPE_ARGS}>"

sui client ptb --gas-budget 50000000 `
  --move-call $MOVE_CALL @$FACTORY @$USDC_COIN @$USDT_COIN 30u64 @$CLOCK `
  --assign nft `
  --transfer-objects "[nft]" @$RECIPIENT

