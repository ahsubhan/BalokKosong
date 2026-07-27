import 'package:balok_kosong/developer_access.dart';
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

  test('developer full access requires the owner Google provider', () {
    expect(
      developerFullAccessEnabled(
        email: 'AH.SUBHAN@gmail.com',
        providerIds: const ['google.com'],
      ),
      isTrue,
    );
    expect(
      developerFullAccessEnabled(
        email: 'ah.subhan@gmail.com',
        providerIds: const ['password'],
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
          highestUnlockedLevel: 1,
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
          highestUnlockedLevel: 1,
        ),
        isTrue,
      );
    }
    expect(
      canNavigateToNextLevel(
        developer: false,
        currentLevelCompleted: true,
        levelIndex: totalLevels - 1,
        highestUnlockedLevel: totalLevels,
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
          highestUnlockedLevel: 1,
        ),
        isTrue,
      );
    }
    expect(
      canNavigateToNextLevel(
        developer: true,
        currentLevelCompleted: false,
        levelIndex: totalLevels - 1,
        highestUnlockedLevel: 1,
      ),
      isFalse,
    );
  });

  test('player can return forward only up to the highest unlocked level', () {
    const highestUnlockedLevel = 5;

    for (
      var levelIndex = 0;
      levelIndex < highestUnlockedLevel - 1;
      levelIndex++
    ) {
      expect(
        canNavigateToNextLevel(
          developer: false,
          currentLevelCompleted: false,
          levelIndex: levelIndex,
          highestUnlockedLevel: highestUnlockedLevel,
        ),
        isTrue,
        reason:
            'Level ${levelIndex + 1} should be able to return toward Level 5',
      );
    }

    expect(
      canNavigateToNextLevel(
        developer: false,
        currentLevelCompleted: false,
        levelIndex: highestUnlockedLevel - 1,
        highestUnlockedLevel: highestUnlockedLevel,
      ),
      isFalse,
      reason: 'Level 5 must be completed before Level 6 is opened',
    );
  });
}
