import 'game_engine.dart';

String playerProgressKey(String key, String userId) => '${key}_$userId';

bool hasMeaningfulProgress({
  required bool hasStarted,
  required int? playerLevel,
  required int? playerScore,
}) {
  if (!hasStarted) return false;
  return (playerLevel ?? 1) > 1 || (playerScore ?? 0) > 0;
}

bool shouldOfferSavedProgress({
  required bool authenticatedAccount,
  required bool developer,
  required bool hasStarted,
  required int? playerLevel,
  required int? playerScore,
}) =>
    authenticatedAccount &&
    !developer &&
    hasMeaningfulProgress(
      hasStarted: hasStarted,
      playerLevel: playerLevel,
      playerScore: playerScore,
    );

int resolveInitialLevel({
  required bool startFromLevelOne,
  required bool hasStarted,
  required int? playerLevel,
  required int? legacyLevel,
}) {
  if (startFromLevelOne || !hasStarted) return 1;
  return (playerLevel ?? legacyLevel ?? 1).clamp(1, totalLevels);
}
