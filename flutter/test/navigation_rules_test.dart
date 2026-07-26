import 'package:balok_kosong/game_engine.dart';
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

  test('regular player stays locked until the current level is complete', () {
    for (var levelIndex = 0; levelIndex < totalLevels; levelIndex++) {
      expect(
        canNavigateToNextLevel(
          developer: false,
          currentLevelCompleted: false,
          levelIndex: levelIndex,
        ),
        isFalse,
      );
    }
  });

  test('completed level unlocks only the immediate next level', () {
    for (var levelIndex = 0; levelIndex < totalLevels - 1; levelIndex++) {
      expect(
        canNavigateToNextLevel(
          developer: false,
          currentLevelCompleted: true,
          levelIndex: levelIndex,
        ),
        isTrue,
      );
    }
    expect(
      canNavigateToNextLevel(
        developer: false,
        currentLevelCompleted: true,
        levelIndex: totalLevels - 1,
      ),
      isFalse,
    );
  });

  test('developer can advance without completion but cannot wrap level 10', () {
    for (var levelIndex = 0; levelIndex < totalLevels - 1; levelIndex++) {
      expect(
        canNavigateToNextLevel(
          developer: true,
          currentLevelCompleted: false,
          levelIndex: levelIndex,
        ),
        isTrue,
      );
    }
    expect(
      canNavigateToNextLevel(
        developer: true,
        currentLevelCompleted: false,
        levelIndex: totalLevels - 1,
      ),
      isFalse,
    );
  });
}
