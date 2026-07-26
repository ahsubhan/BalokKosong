import 'package:balok_kosong/firebase_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('coupon result describes every granted reward', () {
    const result = CouponRedemptionResult(
      code: 'BALOKHEMAT',
      tokens: 15,
      energy: 5,
      themePack: true,
      customThemeUnlocked: true,
      noAds: true,
      tokenReward: 10,
      energyReward: 2,
      themePackReward: true,
      customThemeReward: true,
      noAdsReward: true,
    );

    expect(result.message, contains('+10 token'));
    expect(result.message, contains('+2 energy'));
    expect(result.message, contains('tema Neon & Ocean'));
    expect(result.message, contains('tema Custom'));
    expect(result.message, contains('bebas iklan'));
  });
}
