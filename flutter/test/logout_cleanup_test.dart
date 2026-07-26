import 'package:balok_kosong/firebase_service.dart';
import 'package:balok_kosong/player_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('logout clears account data but keeps device preferences', () async {
    const userId = 'account-123';
    SharedPreferences.setMockInitialValues({
      'balok_level': 7,
      'balok_score': 4200,
      'balok_tokens': 36,
      'balok_energy': 4,
      'balok_unlimited': true,
      'balok_theme_pack': true,
      'balok_custom_theme_unlocked': true,
      'balok_no_ads': true,
      'balok_grid_unlocked_levels': <String>['4', '5'],
      'balok_free_hints_used': 6,
      'balok_purchase_history': <String>['30 Token'],
      playerProgressKey('balok_level', userId): 7,
      playerProgressKey('balok_score', userId): 4200,
      playerProgressKey('balok_has_started', userId): true,
      'balok_music_enabled': false,
      'balok_grid_visible': true,
      'balok_notify_promos': true,
      'balok_theme_name': 'Midnight',
      'balok_processed_purchases': <String>['receipt-1'],
      'balok_kosong_tutorial_seen_$userId': true,
    });
    final preferences = await SharedPreferences.getInstance();

    await clearSignedOutAccountData(preferences, userId: userId);

    for (final key in [
      'balok_level',
      'balok_score',
      'balok_tokens',
      'balok_energy',
      'balok_unlimited',
      'balok_theme_pack',
      'balok_custom_theme_unlocked',
      'balok_no_ads',
      'balok_grid_unlocked_levels',
      'balok_free_hints_used',
      'balok_purchase_history',
      playerProgressKey('balok_level', userId),
      playerProgressKey('balok_score', userId),
      playerProgressKey('balok_has_started', userId),
    ]) {
      expect(preferences.containsKey(key), isFalse, reason: key);
    }

    expect(preferences.getBool('balok_music_enabled'), isFalse);
    expect(preferences.getBool('balok_grid_visible'), isTrue);
    expect(preferences.getBool('balok_notify_promos'), isTrue);
    expect(preferences.getString('balok_theme_name'), 'Midnight');
    expect(preferences.getStringList('balok_processed_purchases'), const [
      'receipt-1',
    ]);
    expect(preferences.getBool('balok_kosong_tutorial_seen_$userId'), isTrue);
  });
}
