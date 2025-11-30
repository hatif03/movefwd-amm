$PACKAGE = "0x374b4c8fec99c1f2dd38983fd1624c21d1984ec9258648aab9a5adaaafd70afa"
$FACTORY = "0xeb0bc8869f53adcf10a10b92070d6910289ee54261dcfed387f659c8ffd53ed6"
$BTC_COIN = "0x9c11ff745be36c470f9cba68ef015ab96d2053ea38d75c3193dc2f70f6feb089"
$WSUI_COIN = "0x209297514ef5ac77f0a0ff921b1240374ef225736f59f89c3431b403016e3222"
$CLOCK = "0x6"
$RECIPIENT = "0xfe3df512d14db62f702d0c193564df373e3ba2674ca2d43382ba29597bb0c1fd"

$TYPE_ARGS = "${PACKAGE}::demo_btc::DEMO_BTC, ${PACKAGE}::demo_wsui::DEMO_WSUI"
$MOVE_CALL = "${PACKAGE}::pool_factory::create_pool<${TYPE_ARGS}>"

sui client ptb --gas-budget 50000000 `
  --move-call $MOVE_CALL @$FACTORY @$BTC_COIN @$WSUI_COIN 30u64 @$CLOCK `
  --assign nft `
  --transfer-objects "[nft]" @$RECIPIENT

