import 'package:balok_kosong/game_engine.dart';
import 'package:balok_kosong/native_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('next level remains locked until the current level is complete', () {
    for (var levelIndex = 0; levelIndex < totalLevels; levelIndex++) {
      expect(
        canNavigateToNextLevel(
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
          currentLevelCompleted: true,
          levelIndex: levelIndex,
        ),
        isTrue,
      );
    }
    expect(
      canNavigateToNextLevel(
        currentLevelCompleted: true,
        levelIndex: totalLevels - 1,
      ),
      isFalse,
    );
  });
}
