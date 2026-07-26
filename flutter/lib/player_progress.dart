import 'game_engine.dart';

String playerProgressKey(String key, String userId) => '${key}_$userId';

int resolveInitialLevel({
  required bool startFromLevelOne,
  required bool hasStarted,
  required int? playerLevel,
  required int? legacyLevel,
}) {
  if (startFromLevelOne || !hasStarted) return 1;
  return (playerLevel ?? legacyLevel ?? 1).clamp(1, totalLevels);
}
