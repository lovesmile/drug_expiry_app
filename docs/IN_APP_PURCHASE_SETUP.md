# Pro 购买配置

代码中的商品 ID 是：`premium_unlock`。

## Android / Google Play

1. 在 Google Play Console 创建与应用包名 `com.lovesmile.expiry` 对应的应用。
2. 在“获利设置 → 应用内商品”创建商品。
3. 商品 ID 必须使用 `premium_unlock`。
4. 商品类型必须是一次性购买的非消耗型商品，并设置售价。
5. 将应用发布到内部测试轨道，使用已加入测试名单的 Google 账号安装测试包。
6. 真机必须通过 Google Play 安装测试包；直接安装普通 APK 通常无法完成真实购买。

## iOS / App Store

1. 在 App Store Connect 创建与 Runner Bundle ID 对应的应用。
2. 创建非消耗型 In-App Purchase，Product ID 使用 `premium_unlock`。
3. 配置价格、税务和银行信息，并使用 Sandbox 测试账号验证购买和恢复购买。
4. 提交审核前确认 iOS Bundle ID 与 App Store Connect 应用完全一致。

## 代码行为

- 购买服务使用单例，会员页和应用启动阶段共享同一个购买流。
- 购买成功或恢复成功后，通过 `UserProvider.setPremium(true)` 持久化 Pro 状态。
- 商店不可用、商品不存在、购买失败都会在页面显示明确提示。
- 恢复购买会持续等待商店回调，不会在调用 `restorePurchases()` 后立即结束状态。
