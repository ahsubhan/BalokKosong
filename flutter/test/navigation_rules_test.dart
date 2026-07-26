import 'package:balok_kosong/native_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('developer navigation requires the owner Google account', () {
    expect(
      developerLevelNavigationEnabled(
        email: 'ah.subhan@gmail.com',
        providerIds: const ['google.com'],
      ),
      isTrue,
    );
    expect(
      developerLevelNavigationEnabled(
        email: 'ah.subhan@gmail.com',
        providerIds: const ['password'],
      ),
      isFalse,
    );
    expect(
      developerLevelNavigationEnabled(
        email: 'pemain@example.com',
        providerIds: const ['google.com'],
      ),
      isFalse,
    );
  });

  test('regular player can only go right into an unlocked level', () {
    expect(
      canNavigateToNextLevel(
        developer: false,
        levelIndex: 0,
        highestUnlockedLevel: 1,
      ),
      isFalse,
    );
    expect(
      canNavigateToNextLevel(
        developer: false,
        levelIndex: 0,
        highestUnlockedLevel: 2,
      ),
      isTrue,
    );
    expect(
      canNavigateToNextLevel(
        developer: false,
        levelIndex: 9,
        highestUnlockedLevel: 10,
      ),
      isFalse,
    );
  });

  test('developer can move right from every level including level 10', () {
    for (var levelIndex = 0; levelIndex < 10; levelIndex++) {
      expect(
        canNavigateToNextLevel(
          developer: true,
          levelIndex: levelIndex,
          highestUnlockedLevel: 1,
        ),
        isTrue,
      );
    }
  });
}
