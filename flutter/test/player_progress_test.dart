import 'package:flutter_test/flutter_test.dart';
import 'package:balok_kosong/player_progress.dart';

void main() {
  test('fresh player always starts from level 1 despite legacy level 10', () {
    expect(
      resolveInitialLevel(
        startFromLevelOne: false,
        hasStarted: false,
        playerLevel: null,
        legacyLevel: 10,
      ),
      1,
    );
  });

  test('explicit level 1 choice overrides saved progress', () {
    expect(
      resolveInitialLevel(
        startFromLevelOne: true,
        hasStarted: true,
        playerLevel: 10,
        legacyLevel: 10,
      ),
      1,
    );
  });

  test('returning player can continue their own saved level', () {
    expect(
      resolveInitialLevel(
        startFromLevelOne: false,
        hasStarted: true,
        playerLevel: 6,
        legacyLevel: 10,
      ),
      6,
    );
  });
}
