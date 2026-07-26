import 'package:flutter_test/flutter_test.dart';
import 'package:balok_kosong/player_progress.dart';

void main() {
  group('meaningful progress', () {
    test('level 1 without score remains a fresh player', () {
      expect(
        hasMeaningfulProgress(hasStarted: true, playerLevel: 1, playerScore: 0),
        isFalse,
      );
    });

    test('completed level or saved score enables progress choices', () {
      expect(
        hasMeaningfulProgress(hasStarted: true, playerLevel: 2, playerScore: 0),
        isTrue,
      );
      expect(
        hasMeaningfulProgress(
          hasStarted: true,
          playerLevel: 1,
          playerScore: 100,
        ),
        isTrue,
      );
    });
  });

  group('saved progress choices', () {
    test('developer always gets a fresh test session', () {
      expect(
        shouldOfferSavedProgress(
          authenticatedAccount: true,
          developer: true,
          hasStarted: true,
          playerLevel: 10,
          playerScore: 99999,
        ),
        isFalse,
      );
    });

    test('regular returning player can continue meaningful progress', () {
      expect(
        shouldOfferSavedProgress(
          authenticatedAccount: true,
          developer: false,
          hasStarted: true,
          playerLevel: 4,
          playerScore: 2500,
        ),
        isTrue,
      );
    });

    test(
      'guest always gets a fresh session even with stale local progress',
      () {
        expect(
          shouldOfferSavedProgress(
            authenticatedAccount: false,
            developer: false,
            hasStarted: true,
            playerLevel: 10,
            playerScore: 99999,
          ),
          isFalse,
        );
      },
    );
  });

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
