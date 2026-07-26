import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:app_settings/app_settings.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_service.dart';
import 'firebase_service.dart';
import 'game_engine.dart';
import 'help_feedback.dart';
import 'how_to_play.dart';
import 'mode_selection.dart';
import 'notification_service.dart';
import 'player_progress.dart';
import 'profile_screen.dart';
import 'store_screen.dart';

const _pieceColors = [
  Color(0xfff0524b),
  Color(0xff3f9bd2),
  Color(0xffefc13d),
  Color(0xff4dba92),
  Color(0xff9472c5),
  Color(0xfff47b3b),
  Color(0xffdf6892),
];

const _maximumAllowedMistakes = 10;

Future<void> openNativeGameSettings(
  BuildContext context,
  WidgetBuilder homeBuilder,
) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) =>
        NativeGameScreen(homeBuilder: homeBuilder, settingsOnly: true),
  ),
);

bool canNavigateToNextLevel({
  required bool currentLevelCompleted,
  required int levelIndex,
}) => levelIndex < totalLevels - 1 && currentLevelCompleted;

enum _HintDialogAction { back, continueHint, watchAd }

const _themes = {
  'Gelap': (Color(0xff170b2d), Color(0xff35215e)),
  'Midnight': (Color(0xff18082d), Color(0xff42206f)),
  'Forest': (Color(0xff132a24), Color(0xff294b40)),
  'Plum': (Color(0xff281c30), Color(0xff4b3653)),
  'Sand': (Color(0xff3b3025), Color(0xff695845)),
  'Neon': (Color(0xff070113), Color(0xff1b0750)),
  'Ocean': (Color(0xff021623), Color(0xff073d5d)),
  'Custom': (Color(0xff130522), Color(0xcc2b1645)),
};

class NativeGameScreen extends StatefulWidget {
  const NativeGameScreen({
    super.key,
    required this.homeBuilder,
    this.challengeMode = false,
    this.startFromLevelOne = false,
    this.settingsOnly = false,
  });

  final bool challengeMode;
  final bool startFromLevelOne;
  final bool settingsOnly;
  final WidgetBuilder homeBuilder;

  @override
  State<NativeGameScreen> createState() => _NativeGameScreenState();
}

class _NativeGameScreenState extends State<NativeGameScreen> {
  int levelIndex = 0;
  int score = 0;
  int moves = 0;
  int mistakes = 0;
  int hintsUsed = 0;
  int freeHintsUsed = 0;
  int elapsedSeconds = 0;
  int remainingSeconds = 0;
  bool paused = false;
  bool mistakeDialogOpen = false;
  late bool challengeMode;
  bool timeoutDialogOpen = false;
  bool gridVisible = true;
  bool musicEnabled = true;
  int tokens = 0;
  bool themePack = false;
  bool customThemeUnlocked = false;
  Set<int> gridUnlockedLevels = {};
  String? hintedPieceId;
  String? customBackgroundPath;
  String themeName = 'Midnight';
  late PuzzleEngine engine;
  Timer? timer;
  bool settingsRouteReplaced = false;

  @override
  void initState() {
    super.initState();
    challengeMode = widget.challengeMode;
    _loadLevel(0);
    if (widget.settingsOnly) {
      paused = true;
      unawaited(_openSettingsOnly());
      return;
    }
    unawaited(GameAudio.instance.playGameplay());
    _loadSettings();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !paused && engine.pieces.isNotEmpty) {
        var timedOut = false;
        setState(() {
          elapsedSeconds++;
          if (challengeMode) {
            remainingSeconds = math.max(0, remainingSeconds - 1);
            if (remainingSeconds == 0 && !timeoutDialogOpen) {
              timeoutDialogOpen = true;
              paused = true;
              timedOut = true;
            }
          }
        });
        if (timedOut) {
          unawaited(GameAudio.instance.pauseGameplay());
          _showTimeout();
        }
      }
    });
  }

  Future<void> _openSettingsOnly() async {
    await _loadSettings();
    if (!mounted) return;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await _showSettings();
    if (mounted && !settingsRouteReplaced) Navigator.pop(context);
  }

  Future<void> _loadSettings() async {
    final preferences = await SharedPreferences.getInstance();
    final userId = FirebaseService.instance.user?.uid ?? 'perangkat';
    final progressKey = playerProgressKey('balok_has_started', userId);
    final hasStarted = preferences.getBool(progressKey) ?? false;
    final playerLevel =
        (preferences.getInt(playerProgressKey('balok_level', userId)) ??
                (hasStarted ? preferences.getInt('balok_level') : null) ??
                1)
            .clamp(1, totalLevels);
    final initialLevel = resolveInitialLevel(
      startFromLevelOne: widget.startFromLevelOne,
      hasStarted: hasStarted,
      playerLevel: playerLevel,
      legacyLevel: preferences.getInt('balok_level'),
    );
    final savedScore =
        preferences.getInt(playerProgressKey('balok_score', userId)) ??
        (hasStarted ? preferences.getInt('balok_score') : null) ??
        0;
    if (!widget.settingsOnly) {
      await preferences.setBool(progressKey, true);
      await preferences.setInt(
        playerProgressKey('balok_level', userId),
        playerLevel,
      );
      await preferences.setInt(
        playerProgressKey('balok_score', userId),
        savedScore,
      );
    }
    if (!mounted) return;
    setState(() {
      levelIndex = initialLevel - 1;
      score = savedScore;
      gridVisible = preferences.getBool('balok_grid_visible') ?? true;
      musicEnabled = preferences.getBool('balok_music_enabled') ?? true;
      tokens = preferences.getInt('balok_tokens') ?? 0;
      freeHintsUsed = preferences.getInt('balok_free_hints_used') ?? 0;
      themePack = preferences.getBool('balok_theme_pack') ?? false;
      customThemeUnlocked =
          preferences.getBool('balok_custom_theme_unlocked') ?? false;
      customBackgroundPath = preferences.getString(
        'balok_custom_background_path',
      );
      gridUnlockedLevels =
          (preferences.getStringList('balok_grid_unlocked_levels') ?? const [])
              .map(int.tryParse)
              .whereType<int>()
              .toSet();
      themeName = preferences.getString('balok_theme_name') ?? 'Midnight';
      if (!_themes.containsKey(themeName)) themeName = 'Midnight';
      if (!themePack && (themeName == 'Neon' || themeName == 'Ocean')) {
        themeName = 'Midnight';
      }
      if (themeName == 'Custom' &&
          (customBackgroundPath == null ||
              !File(customBackgroundPath!).existsSync())) {
        themeName = 'Midnight';
      }
      _loadLevel(levelIndex);
    });
  }

  bool get _gridAvailable =>
      levelIndex < 3 || gridUnlockedLevels.contains(levelIndex + 1);

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _loadLevel(int next, {bool keepPaused = false}) {
    levelIndex = next.clamp(0, totalLevels - 1);
    engine = PuzzleEngine(
      generateLevel(levelIndex + 1, levelPieceCount(levelIndex)),
    );
    remainingSeconds = 45 + engine.pieces.length * 3;
    elapsedSeconds = 0;
    moves = 0;
    mistakes = 0;
    hintsUsed = 0;
    paused = keepPaused;
    mistakeDialogOpen = false;
    timeoutDialogOpen = false;
    hintedPieceId = null;
  }

  Future<void> _restart() async {
    final restartLevel = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff24103c),
        icon: const Icon(
          Icons.refresh_rounded,
          color: Color(0xffd8a5ff),
          size: 46,
        ),
        title: const Text(
          'Ulangi permainan?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(dialogContext, 0),
                icon: const Icon(Icons.first_page_rounded),
                label: const Text('Mulai lagi dari Level 1'),
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, levelIndex),
                icon: const Icon(Icons.replay_rounded),
                label: Text('Mulai dari awal Level ${levelIndex + 1}'),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
    if (restartLevel == null || !mounted) return;
    setState(() => _loadLevel(restartLevel));
    unawaited(GameAudio.instance.resumeGameplay());
  }

  void _onPieceExit(PuzzlePiece piece) {
    setState(() {
      engine.pieces.removeWhere((candidate) => candidate.id == piece.id);
      if (hintedPieceId == piece.id) hintedPieceId = null;
      moves++;
      score += math.max(25, 120 - elapsedSeconds ~/ 5);
    });
    if (engine.pieces.isEmpty) {
      Future<void>.delayed(const Duration(milliseconds: 260), _showComplete);
    }
  }

  void _onWrongMove() {
    if (mistakeDialogOpen) return;
    var levelFailed = false;
    setState(() {
      mistakes++;
      if (mistakes > _maximumAllowedMistakes) {
        mistakeDialogOpen = true;
        paused = true;
        levelFailed = true;
      }
    });
    if (levelFailed) {
      unawaited(GameAudio.instance.pauseGameplay());
      unawaited(_showMistakeFailure());
    }
  }

  Future<void> _showMistakeFailure() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff24103c),
        icon: const Icon(
          Icons.close_rounded,
          color: Color(0xffff7597),
          size: 52,
        ),
        title: const Text(
          'Level gagal',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Anda menabrak balok lebih dari $_maximumAllowedMistakes kali. '
          'Level ${levelIndex + 1} harus dimulai dari awal.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext),
            icon: const Icon(Icons.replay_rounded),
            label: Text('ULANGI LEVEL ${levelIndex + 1}'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _loadLevel(levelIndex));
    unawaited(GameAudio.instance.resumeGameplay());
  }

  String get _clock {
    final shown = challengeMode ? remainingSeconds : elapsedSeconds;
    final minutes = shown ~/ 60;
    final seconds = shown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _showHint() async {
    setState(() => paused = true);
    unawaited(GameAudio.instance.pauseGameplay());
    final freeRemaining = math.max(0, 10 - freeHintsUsed);
    final needsToken = freeRemaining == 0;
    final action = await showDialog<_HintDialogAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff24103c),
        icon: Icon(
          needsToken ? Icons.diamond_outlined : Icons.lightbulb_rounded,
          color: const Color(0xffd8a5ff),
          size: 44,
        ),
        title: const Text(
          'Gunakan Petunjuk?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          needsToken
              ? tokens > 0
                    ? 'Batas 10 petunjuk gratis sudah habis. Lanjut akan '
                          'memakai 1 token.\n\nToken tersedia: $tokens\n'
                          'Token juga bisa didapat dengan menonton iklan.'
                    : 'Batas 10 petunjuk gratis sudah habis. Petunjuk '
                          'berikutnya memerlukan 1 token.\n\nLanjut untuk '
                          'membuka Toko & Hadiah, lalu beli token atau '
                          'tonton iklan.'
              : 'Petunjuk gratis hanya dapat dipakai 10 kali total untuk '
                    'akun ini.\n\n'
                    'Sisa petunjuk gratis: $freeRemaining\n'
                    'Setelah habis, gunakan 1 token atau tonton iklan.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _HintDialogAction.back),
            child: const Text('Kembali'),
          ),
          if (needsToken && tokens <= 0)
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pop(dialogContext, _HintDialogAction.watchAd),
              icon: const Icon(Icons.ondemand_video_rounded),
              label: const Text('Tonton Iklan'),
            )
          else
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, _HintDialogAction.continueHint),
              child: const Text('Lanjut'),
            ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == null || action == _HintDialogAction.back) {
      setState(() => paused = false);
      unawaited(GameAudio.instance.resumeGameplay());
      return;
    }
    if (action == _HintDialogAction.watchAd) {
      setState(() => tokens += 3);
      await _persistHintUsage();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iklan selesai · +3 token'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    if (hintedPieceId != null) {
      setState(() => paused = false);
      unawaited(GameAudio.instance.resumeGameplay());
      return;
    }

    PuzzlePiece? best;
    var bestDistance = -1;
    for (final piece in engine.pieces) {
      for (final sign in const [-1, 1]) {
        final distance = engine.maxTravel(piece, sign);
        if (distance <= 0) continue;
        if (engine.isOutside(piece, distance * sign)) {
          best = piece;
          bestDistance = 9999;
          break;
        }
        if (distance > bestDistance) {
          best = piece;
          bestDistance = distance;
        }
      }
      if (bestDistance == 9999) break;
    }
    if (best == null) {
      setState(() => paused = false);
      unawaited(GameAudio.instance.resumeGameplay());
      return;
    }
    setState(() {
      if (needsToken) {
        tokens--;
      } else {
        freeHintsUsed++;
      }
      hintedPieceId = best?.id;
      hintsUsed++;
      paused = false;
    });
    unawaited(GameAudio.instance.resumeGameplay());
    await _persistHintUsage();
  }

  Future<void> _persistHintUsage() async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setInt('balok_tokens', tokens),
      preferences.setInt('balok_free_hints_used', freeHintsUsed),
    ]);
    await FirebaseService.instance.saveInventory(
      tokens: tokens,
      energy: preferences.getInt('balok_energy') ?? 5,
      unlimited: preferences.getBool('balok_unlimited') ?? false,
      themePack: preferences.getBool('balok_theme_pack') ?? false,
      noAds: preferences.getBool('balok_no_ads') ?? false,
      gridUnlockedLevels:
          (preferences.getStringList('balok_grid_unlocked_levels') ?? const [])
              .map(int.tryParse)
              .whereType<int>()
              .toList(),
      freeHintsUsed: freeHintsUsed,
    );
  }

  void _showMode() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (modeContext) => ModeSelectionScreen(
        onRelaxed: () {
          Navigator.pop(modeContext);
          setState(() {
            challengeMode = false;
            _loadLevel(levelIndex);
          });
          unawaited(GameAudio.instance.resumeGameplay());
        },
        onChallenge: () {
          Navigator.pop(modeContext);
          setState(() {
            challengeMode = true;
            _loadLevel(levelIndex);
          });
          unawaited(GameAudio.instance.resumeGameplay());
        },
        onRelaxedSelected: (startFromLevelOne) {
          Navigator.pop(modeContext);
          setState(() {
            challengeMode = false;
            _loadLevel(startFromLevelOne ? 0 : levelIndex);
          });
          unawaited(GameAudio.instance.resumeGameplay());
        },
        onChallengeSelected: (startFromLevelOne) {
          Navigator.pop(modeContext);
          setState(() {
            challengeMode = true;
            _loadLevel(startFromLevelOne ? 0 : levelIndex);
          });
          unawaited(GameAudio.instance.resumeGameplay());
        },
        onCancel: () => Navigator.pop(modeContext),
        hasProgress: true,
        onSettings: () {
          Navigator.pop(modeContext);
          Future<void>.delayed(
            const Duration(milliseconds: 180),
            _showSettings,
          );
        },
      ),
    ),
  );

  void _showTimeout() => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xff24103c),
      icon: const Icon(
        Icons.timer_off_outlined,
        color: Color(0xffd8a5ff),
        size: 54,
      ),
      title: const Text(
        'Waktu habis!',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: Text(
        'Ulangi Level ${levelIndex + 1} dan coba jalur yang lebih cepat.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            setState(() {
              timeoutDialogOpen = false;
              _loadLevel(levelIndex);
            });
            unawaited(GameAudio.instance.resumeGameplay());
          },
          child: const Text('Ulangi level'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            setState(() {
              timeoutDialogOpen = false;
              challengeMode = false;
              _loadLevel(levelIndex);
            });
            unawaited(GameAudio.instance.resumeGameplay());
          },
          child: const Text('Mode Santai'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final palette = _themes[themeName]!;
    return PopScope(
      canPop: widget.settingsOnly,
      child: Scaffold(
        backgroundColor: palette.$1,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child:
                    themeName == 'Custom' &&
                        customBackgroundPath != null &&
                        File(customBackgroundPath!).existsSync()
                    ? _CustomThemeBackdrop(path: customBackgroundPath!)
                    : _ThemeBackdrop(themeName: themeName),
              ),
              Column(
                children: [
                  Expanded(
                    child: PuzzleCanvas(
                      engine: engine,
                      boardColor: palette.$2,
                      themeName: themeName,
                      showGrid: _gridAvailable && gridVisible,
                      disabled: paused,
                      hintedPieceId: hintedPieceId,
                      onHintConsumed: () =>
                          setState(() => hintedPieceId = null),
                      onExit: _onPieceExit,
                      onMove: () => setState(() => moves++),
                      onWrong: _onWrongMove,
                    ),
                  ),
                  _GameHud(
                    level: levelIndex + 1,
                    score: score,
                    time: _clock,
                    timeLabel: challengeMode ? 'TANTANGAN' : 'WAKTU',
                    remainingMistakes: math.max(
                      0,
                      _maximumAllowedMistakes - mistakes,
                    ),
                    onPause: () {
                      setState(() => paused = true);
                      unawaited(GameAudio.instance.pauseGameplay());
                    },
                    onHint: _showHint,
                  ),
                ],
              ),
              if (paused)
                _PauseOverlay(
                  level: levelIndex + 1,
                  canPrevious: levelIndex > 0,
                  canNext: canNavigateToNextLevel(
                    currentLevelCompleted: engine.pieces.isEmpty,
                    levelIndex: levelIndex,
                  ),
                  onContinue: () {
                    setState(() => paused = false);
                    unawaited(GameAudio.instance.resumeGameplay());
                  },
                  onRestart: _restart,
                  onMode: _showMode,
                  onPrevious: () => setState(
                    () => _loadLevel(levelIndex - 1, keepPaused: true),
                  ),
                  onNext: () => setState(
                    () => _loadLevel(levelIndex + 1, keepPaused: true),
                  ),
                  onSettings: _showSettings,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRules() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (guideContext) => HowToPlayScreen(
        finalLabel: 'Lanjut',
        onFinished: () => Navigator.pop(guideContext),
      ),
    ),
  );

  void _showHelp() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (helpContext) => HelpFeedbackScreen(
        onOpenGuide: () {
          Navigator.pop(helpContext);
          Future<void>.delayed(const Duration(milliseconds: 180), _showRules);
        },
      ),
    ),
  );

  void _showChangelog() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xff24103c),
      title: const Text(
        'Changelog',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Versi 1.0.0 · Build 1',
            style: TextStyle(color: Color(0xffd8a5ff)),
          ),
          SizedBox(height: 14),
          Text('• Mesin puzzle native 28×42'),
          Text('• Mode Santai dan Tantangan'),
          Text('• Tutorial, Petunjuk, Toko & Hadiah'),
          Text('• Tema ungu dan pengaturan aksesibilitas'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );

  Future<void> _showProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      tokens = preferences.getInt('balok_tokens') ?? tokens;
      themePack = preferences.getBool('balok_theme_pack') ?? themePack;
      gridUnlockedLevels =
          (preferences.getStringList('balok_grid_unlocked_levels') ?? const [])
              .map(int.tryParse)
              .whereType<int>()
              .toSet();
    });
  }

  Future<void> _showSettings() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (_, updateSheet) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: .97,
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              color: const Color(0xff1b082f),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white12),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'ATURAN & PENGATURAN',
                          style: GoogleFonts.fredoka(
                            color: const Color(0xffd9a9ff),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        if (FirebaseService.instance.user != null &&
                            FirebaseService.instance.user?.isAnonymous == false)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton.filled(
                              tooltip: 'Profil',
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                Future<void>.delayed(
                                  const Duration(milliseconds: 180),
                                  _showProfile,
                                );
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xff6f35a8),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(
                                Icons.person_outline_rounded,
                                size: 22,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const NativeLogo(compact: true),
                  const SizedBox(height: 20),
                  const Text(
                    'Keluarkan semua balok. Balok horizontal hanya bergerak '
                    'kiri–kanan dan balok vertikal hanya bergerak atas–bawah.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SettingsActionCard(
                    icon: Icons.play_arrow_rounded,
                    title: 'Lihat cara bermain',
                    subtitle: 'Panduan singkat 4 halaman',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Future<void>.delayed(
                        const Duration(milliseconds: 180),
                        _showRules,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _SettingsActionCard(
                    icon: Icons.home_rounded,
                    title: 'Kembali ke halaman utama',
                    subtitle: 'Panah kembali tersedia untuk kembali bermain',
                    onTap: () {
                      if (widget.settingsOnly) {
                        settingsRouteReplaced = true;
                        Navigator.pop(sheetContext);
                        Future<void>.delayed(
                          const Duration(milliseconds: 180),
                          () {
                            if (!mounted) return;
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: widget.homeBuilder),
                            );
                          },
                        );
                        return;
                      }
                      Navigator.pop(sheetContext);
                      Future<void>.delayed(
                        const Duration(milliseconds: 180),
                        () {
                          if (!mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: widget.homeBuilder),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _SettingsActionCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Toko & hadiah',
                    subtitle: 'Token petunjuk, energy, tema, dan bebas iklan',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Future<void>.delayed(
                        const Duration(milliseconds: 180),
                        _showStore,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _gridAvailable
                        ? null
                        : () => _unlockGridForCurrentLevel(updateSheet),
                    child: Opacity(
                      opacity: _gridAvailable ? 1 : .48,
                      child: Material(
                        color: Colors.white.withValues(alpha: .045),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(color: Colors.white12),
                        ),
                        child: SwitchListTile(
                          title: const Text(
                            'Tampilkan grid',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            _gridAvailable
                                ? 'Gratis di Level 1–3'
                                : 'Level ${levelIndex + 1} membutuhkan 1 token',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          secondary: Icon(
                            _gridAvailable
                                ? Icons.grid_on_rounded
                                : Icons.lock_rounded,
                            color: const Color(0xffd8a5ff),
                          ),
                          value: _gridAvailable && gridVisible,
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xff8d4fe0),
                          onChanged: !_gridAvailable
                              ? null
                              : (value) async {
                                  setState(() => gridVisible = value);
                                  updateSheet(() {});
                                  final preferences =
                                      await SharedPreferences.getInstance();
                                  await preferences.setBool(
                                    'balok_grid_visible',
                                    value,
                                  );
                                  await FirebaseService.instance.saveSettings(
                                    gridVisible: value,
                                  );
                                },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.white.withValues(alpha: .045),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: const BorderSide(color: Colors.white12),
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        'Musik',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        musicEnabled
                            ? 'Musik latar aktif'
                            : 'Musik latar dimatikan',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      secondary: Icon(
                        musicEnabled
                            ? Icons.music_note_rounded
                            : Icons.music_off_rounded,
                        color: const Color(0xffd8a5ff),
                      ),
                      value: musicEnabled,
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xff8d4fe0),
                      onChanged: (value) async {
                        setState(() => musicEnabled = value);
                        updateSheet(() {});
                        await GameAudio.instance.setEnabled(value);
                        final preferences =
                            await SharedPreferences.getInstance();
                        await preferences.setBool('balok_music_enabled', value);
                        await FirebaseService.instance.saveSettings(
                          musicEnabled: value,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SettingsActionCard(
                    icon: Icons.notifications_active_rounded,
                    title: 'Notifikasi',
                    onTap: () async {
                      await NotificationService.instance.requestPermission();
                      await AppSettings.openAppSettings(
                        type: AppSettingsType.notification,
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'TEMA LATAR',
                      style: GoogleFonts.fredoka(
                        color: const Color(0xffd4a9ff),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 9,
                    crossAxisSpacing: 9,
                    childAspectRatio: 3.15,
                    children: [
                      for (final entry in _themes.entries.where(
                        (entry) => entry.key != 'Neon' && entry.key != 'Ocean',
                      ))
                        _ThemeOption(
                          name: entry.key,
                          color: entry.value.$2,
                          selected: themeName == entry.key,
                          onTap: () async {
                            setState(() => themeName = entry.key);
                            updateSheet(() {});
                            final preferences =
                                await SharedPreferences.getInstance();
                            await preferences.setString(
                              'balok_theme_name',
                              entry.key,
                            );
                            await FirebaseService.instance.saveSettings(
                              themeName: entry.key,
                            );
                          },
                        ),
                      _ThemeOption(
                        name: 'Neon · ✦',
                        color: Color(0xff130624),
                        selected: themeName == 'Neon',
                        locked: !themePack,
                        onTap: themePack
                            ? () => _selectTheme('Neon', updateSheet)
                            : _showPremiumThemeInfo,
                      ),
                      _ThemeOption(
                        name: 'Ocean · ✦',
                        color: Color(0xff102b48),
                        selected: themeName == 'Ocean',
                        locked: !themePack,
                        onTap: themePack
                            ? () => _selectTheme('Ocean', updateSheet)
                            : _showPremiumThemeInfo,
                      ),
                      _ThemeOption(
                        name: customThemeUnlocked ? 'Custom' : 'Custom · 15◆',
                        color: const Color(0xff4f2879),
                        imagePath: customBackgroundPath,
                        selected: themeName == 'Custom',
                        locked: !customThemeUnlocked,
                        onTap: () => _chooseCustomTheme(updateSheet),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SettingsActionCard(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Feedback',
                    subtitle: 'FAQ, bantuan bermain, laporkan masalah & saran',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Future<void>.delayed(
                        const Duration(milliseconds: 180),
                        _showHelp,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _SettingsActionCard(
                    icon: Icons.history_rounded,
                    title: 'Changelog',
                    subtitle: 'Lihat perubahan pada versi terbaru',
                    onTap: _showChangelog,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'BALOK KOSONG · Versi 1.0.0 · Build 1',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: .5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff8d4fe0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _showStore() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StoreScreen()));
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      tokens = preferences.getInt('balok_tokens') ?? 0;
      themePack = preferences.getBool('balok_theme_pack') ?? false;
      customThemeUnlocked =
          preferences.getBool('balok_custom_theme_unlocked') ?? false;
    });
  }

  Future<void> _selectTheme(String name, StateSetter updateSheet) async {
    setState(() => themeName = name);
    updateSheet(() {});
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('balok_theme_name', name);
    await FirebaseService.instance.saveSettings(themeName: name);
  }

  Future<void> _chooseCustomTheme(StateSetter updateSheet) async {
    const unlockCost = 15;
    if (!customThemeUnlocked && tokens < unlockCost) {
      final openStore = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xff24103c),
          icon: const Icon(
            Icons.photo_library_rounded,
            color: Color(0xffd8a5ff),
            size: 46,
          ),
          title: const Text(
            'Latar Custom',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Fitur ini membutuhkan $unlockCost token dan tidak dapat dibuka '
            'langsung dengan menonton iklan.\n\nToken Anda: $tokens',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Nanti'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('BUKA TOKO'),
            ),
          ],
        ),
      );
      if (openStore == true && mounted) {
        Navigator.pop(context);
        await Future<void>.delayed(const Duration(milliseconds: 180));
        if (mounted) await _showStore();
      }
      return;
    }

    if (!customThemeUnlocked) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xff24103c),
          icon: const Icon(
            Icons.workspace_premium_rounded,
            color: Color(0xffffcf5a),
            size: 46,
          ),
          title: const Text(
            'Buka Latar Custom?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Gunakan $unlockCost token satu kali. Setelah terbuka, Anda bebas '
            'mengganti gambar dari album kapan saja tanpa iklan.\n\n'
            'Token tersedia: $tokens',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('GUNAKAN 15 TOKEN'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    try {
      final selected = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 2048,
        maxHeight: 2048,
        requestFullMetadata: false,
      );
      if (selected == null || !mounted) return;
      final directory = await getApplicationDocumentsDirectory();
      final suffix = selected.path.toLowerCase().endsWith('.png')
          ? '.png'
          : '.jpg';
      final destination =
          '${directory.path}${Platform.pathSeparator}'
          'balokkosong_custom_background$suffix';
      await File(selected.path).copy(destination);

      final preferences = await SharedPreferences.getInstance();
      final firstUnlock = !customThemeUnlocked;
      final purchaseHistory =
          preferences.getStringList('balok_purchase_history') ?? <String>[];
      if (firstUnlock) {
        final now = DateTime.now();
        final date =
            '${now.day.toString().padLeft(2, '0')}/'
            '${now.month.toString().padLeft(2, '0')}/${now.year}';
        purchaseHistory.insert(0, 'Latar Custom · $date');
      }
      setState(() {
        if (firstUnlock) tokens -= unlockCost;
        customThemeUnlocked = true;
        customBackgroundPath = destination;
        themeName = 'Custom';
      });
      updateSheet(() {});
      await Future.wait([
        preferences.setInt('balok_tokens', tokens),
        preferences.setBool('balok_custom_theme_unlocked', true),
        preferences.setString('balok_custom_background_path', destination),
        preferences.setString('balok_theme_name', 'Custom'),
        preferences.setStringList('balok_purchase_history', purchaseHistory),
      ]);
      await FirebaseService.instance.saveSettings(themeName: 'Custom');
      await FirebaseService.instance.saveInventory(
        tokens: tokens,
        energy: preferences.getInt('balok_energy') ?? 5,
        unlimited: preferences.getBool('balok_unlimited') ?? false,
        themePack: preferences.getBool('balok_theme_pack') ?? false,
        noAds: preferences.getBool('balok_no_ads') ?? false,
        gridUnlockedLevels: gridUnlockedLevels.toList()..sort(),
        freeHintsUsed: freeHintsUsed,
        purchaseHistory: purchaseHistory,
        customThemeUnlocked: true,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gambar belum dapat dibuka. Silakan coba kembali.'),
        ),
      );
    }
  }

  Future<void> _showPremiumThemeInfo() async {
    final openStore = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff24103c),
        icon: const Icon(
          Icons.workspace_premium_rounded,
          color: Color(0xffffcf5a),
          size: 46,
        ),
        title: const Text(
          'Tema Premium',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Neon dan Ocean dapat dibuka melalui pembelian Paket Tema '
          'atau dengan memasukkan kupon di Toko & Hadiah.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('BUKA TOKO'),
          ),
        ],
      ),
    );
    if (openStore != true || !mounted) return;
    Navigator.pop(context);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (mounted) await _showStore();
  }

  Future<void> _unlockGridForCurrentLevel(StateSetter updateSheet) async {
    if (tokens <= 0) {
      final openStore = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xff24103c),
          icon: const Icon(
            Icons.grid_off_rounded,
            color: Color(0xffd8a5ff),
            size: 44,
          ),
          title: const Text(
            'Grid terkunci',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Mulai Level 4, grid membutuhkan 1 token per level. '
            'Token Anda saat ini: $tokens.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Nanti'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('BELI TOKEN'),
            ),
          ],
        ),
      );
      if (openStore == true && mounted) {
        Navigator.pop(context);
        await Future<void>.delayed(const Duration(milliseconds: 180));
        if (mounted) await _showStore();
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff24103c),
        title: Text(
          'Buka grid Level ${levelIndex + 1}?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Gunakan 1 token. Setelah dibuka, grid untuk level ini '
          'dapat dinyalakan atau dimatikan kapan saja.\n\n'
          'Token tersedia: $tokens',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('GUNAKAN 1 TOKEN'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final preferences = await SharedPreferences.getInstance();
    final unlockedLevel = levelIndex + 1;
    setState(() {
      tokens--;
      gridUnlockedLevels.add(unlockedLevel);
      gridVisible = true;
    });
    updateSheet(() {});
    await Future.wait([
      preferences.setInt('balok_tokens', tokens),
      preferences.setBool('balok_grid_visible', true),
      preferences.setStringList(
        'balok_grid_unlocked_levels',
        gridUnlockedLevels.map((level) => '$level').toList()..sort(),
      ),
    ]);
    await FirebaseService.instance.saveSettings(gridVisible: true);
    await FirebaseService.instance.saveInventory(
      tokens: tokens,
      energy: preferences.getInt('balok_energy') ?? 5,
      unlimited: preferences.getBool('balok_unlimited') ?? false,
      themePack: preferences.getBool('balok_theme_pack') ?? false,
      noAds: preferences.getBool('balok_no_ads') ?? false,
      gridUnlockedLevels: gridUnlockedLevels.toList()..sort(),
    );
  }

  void _showComplete() {
    unawaited(GameAudio.instance.playVictory());
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final stars = mistakes == 0 && hintsUsed == 0
            ? 3
            : mistakes <= 3 && hintsUsed <= 1
            ? 2
            : 1;
        unawaited(
          FirebaseService.instance.saveProgress(
            level: levelIndex == totalLevels - 1 ? totalLevels : levelIndex + 2,
            score: score,
            bestTimeSeconds: elapsedSeconds,
            moves: moves,
            mistakes: mistakes,
            hintsUsed: hintsUsed,
            stars: stars,
            challengeMode: challengeMode,
          ),
        );
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
            decoration: BoxDecoration(
              color: const Color(0xff24103c),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xff7f4bb0)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        index < stars
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xffffc247),
                        size: 38,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Papan kosong!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Waktu $_clock · $mistakes salah · $hintsUsed petunjuk',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'NILAI',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      unawaited(GameAudio.instance.playGameplay());
                      setState(
                        () => _loadLevel(
                          levelIndex == totalLevels - 1 ? 0 : levelIndex + 1,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff9754e8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      levelIndex == totalLevels - 1
                          ? 'MAIN LAGI'
                          : 'LEVEL BERIKUTNYA  →',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeBackdrop extends StatelessWidget {
  const _ThemeBackdrop({required this.themeName});

  final String themeName;

  @override
  Widget build(BuildContext context) {
    if (themeName != 'Neon' && themeName != 'Ocean') {
      return const SizedBox.expand();
    }
    return IgnorePointer(
      child: CustomPaint(
        painter: _ThemeBackdropPainter(themeName),
        size: Size.infinite,
      ),
    );
  }
}

class _CustomThemeBackdrop extends StatelessWidget {
  const _CustomThemeBackdrop({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.file(
        File(path),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xff130522)),
      ),
      const ColoredBox(color: Color(0x730b0313)),
    ],
  );
}

class _ThemeBackdropPainter extends CustomPainter {
  const _ThemeBackdropPainter(this.themeName);

  final String themeName;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    if (themeName == 'Neon') {
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff05000f), Color(0xff21033f), Color(0xff001a2c)],
          ).createShader(bounds),
      );
      final pink = Paint()
        ..color = const Color(0xffff47df).withValues(alpha: .16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
      final cyan = Paint()
        ..color = const Color(0xff36e8ff).withValues(alpha: .13)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
      canvas.drawCircle(Offset(size.width * .12, size.height * .20), 74, pink);
      canvas.drawCircle(Offset(size.width * .88, size.height * .72), 92, cyan);
      final starPaint = Paint()..color = Colors.white.withValues(alpha: .48);
      for (var i = 0; i < 24; i++) {
        final x = ((i * 61) % 101) / 101 * size.width;
        final y = ((i * 43) % 97) / 97 * size.height;
        canvas.drawCircle(Offset(x, y), i % 5 == 0 ? 1.4 : .7, starPaint);
      }
    } else {
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff063b58), Color(0xff031c32), Color(0xff010b19)],
          ).createShader(bounds),
      );
      final wavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xff54d7ff).withValues(alpha: .15);
      for (var row = 0; row < 4; row++) {
        final y = size.height * (.18 + row * .23);
        final wave = Path()..moveTo(-20, y);
        for (var x = -20.0; x <= size.width + 40; x += 40) {
          wave.quadraticBezierTo(x + 20, y - 12, x + 40, y);
        }
        canvas.drawPath(wave, wavePaint);
      }
      final bubblePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .20);
      for (var i = 0; i < 22; i++) {
        final x = ((i * 71) % 103) / 103 * size.width;
        final y = ((i * 37) % 97) / 97 * size.height;
        canvas.drawCircle(Offset(x, y), 2.0 + i % 5, bubblePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ThemeBackdropPainter oldDelegate) =>
      oldDelegate.themeName != themeName;
}

class PuzzleCanvas extends StatefulWidget {
  const PuzzleCanvas({
    super.key,
    required this.engine,
    required this.boardColor,
    required this.themeName,
    required this.showGrid,
    required this.disabled,
    required this.hintedPieceId,
    required this.onHintConsumed,
    required this.onExit,
    required this.onMove,
    required this.onWrong,
  });

  final PuzzleEngine engine;
  final Color boardColor;
  final String themeName;
  final bool showGrid;
  final bool disabled;
  final String? hintedPieceId;
  final VoidCallback onHintConsumed;
  final ValueChanged<PuzzlePiece> onExit;
  final VoidCallback onMove;
  final VoidCallback onWrong;

  @override
  State<PuzzleCanvas> createState() => _PuzzleCanvasState();
}

class _PuzzleCanvasState extends State<PuzzleCanvas>
    with SingleTickerProviderStateMixin {
  PuzzlePiece? active;
  double dragCells = 0;
  double maxNegative = 0;
  double maxPositive = 0;
  bool dragAttempted = false;
  bool slideSoundPlaying = false;
  int? slideSoundSession;
  double collisionDirection = 0;
  late final AnimationController bumpController;

  @override
  void initState() {
    super.initState();
    bumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    unawaited(GameAudio.instance.stopBlockSlide());
    bumpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final cell = math.min(
        constraints.maxWidth / boardCols,
        constraints.maxHeight / boardRows,
      );
      final width = cell * boardCols;
      final height = cell * boardRows;
      return Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onPanDown: widget.disabled
              ? null
              : (details) => _start(details.localPosition, cell),
          onPanUpdate: widget.disabled
              ? null
              : (details) => _update(details.delta, cell),
          onPanEnd: widget.disabled ? null : (_) => _end(),
          onPanCancel: widget.disabled ? null : _cancelDrag,
          child: CustomPaint(
            size: Size(width, height),
            painter: _PuzzlePainter(
              pieces: widget.engine.pieces,
              boardColor: widget.boardColor,
              themeName: widget.themeName,
              active: active,
              activeOffset: dragCells,
              showGrid: widget.showGrid,
              hintedPieceId: widget.hintedPieceId,
              cell: cell,
              bumpAnimation: bumpController,
              collisionDirection: collisionDirection,
            ),
          ),
        ),
      );
    },
  );

  void _start(Offset point, double cellSize) {
    final touchX = point.dx / cellSize;
    final touchY = point.dy / cellSize;
    const hitPadding = .40;
    for (final piece in widget.engine.pieces.reversed) {
      if (pieceCells(piece).any(
        (cell) =>
            touchX >= cell.x - hitPadding &&
            touchX <= cell.x + 1 + hitPadding &&
            touchY >= cell.y - hitPadding &&
            touchY <= cell.y + 1 + hitPadding,
      )) {
        setState(() {
          active = piece;
          dragCells = 0;
          maxNegative = widget.engine.maxTravel(piece, -1).toDouble();
          maxPositive = widget.engine.maxTravel(piece, 1).toDouble();
          dragAttempted = false;
        });
        return;
      }
    }
  }

  void _update(Offset delta, double cellSize) {
    final piece = active;
    if (piece == null) return;
    final rawDelta = piece.horizontal ? delta.dx : delta.dy;
    if (rawDelta.abs() > .20) {
      dragAttempted = true;
      if (!slideSoundPlaying) {
        slideSoundPlaying = true;
        slideSoundSession = GameAudio.instance.beginBlockSlide();
      }
    }
    if (piece.id == widget.hintedPieceId && rawDelta.abs() > .20) {
      widget.onHintConsumed();
    }
    final proposed = dragCells + (rawDelta / cellSize) * 1.36;
    if (proposed < -maxNegative - .03 || proposed > maxPositive + .03) {
      _triggerBump(rawDelta.sign);
    }
    setState(() {
      dragCells = proposed.clamp(-maxNegative, maxPositive);
    });
  }

  void _triggerBump(double direction) {
    if (bumpController.isAnimating) return;
    collisionDirection = direction;
    unawaited(HapticFeedback.lightImpact());
    bumpController.forward(from: 0);
  }

  void _end() {
    _endSlideSound();
    final piece = active;
    if (piece == null) return;
    var moved = false;
    var snapped = dragCells.round();
    if (snapped == 0 && dragCells.abs() >= .18) {
      snapped = dragCells.isNegative ? -1 : 1;
    }
    if (widget.engine.isOutside(piece, snapped)) {
      moved = true;
      widget.onExit(piece);
    } else if (snapped != 0 &&
        widget.engine.canPlace(
          piece,
          piece.horizontal ? snapped : 0,
          piece.horizontal ? 0 : snapped,
        )) {
      widget.engine.commit(piece, snapped);
      moved = true;
      widget.onMove();
    }
    if (dragAttempted && !moved) widget.onWrong();
    setState(() {
      active = null;
      dragCells = 0;
      dragAttempted = false;
      slideSoundPlaying = false;
    });
  }

  void _cancelDrag() {
    _endSlideSound();
    if (active == null) return;
    setState(() {
      active = null;
      dragCells = 0;
      dragAttempted = false;
      slideSoundPlaying = false;
    });
  }

  void _endSlideSound() {
    final session = slideSoundSession;
    slideSoundSession = null;
    slideSoundPlaying = false;
    if (session != null) {
      unawaited(GameAudio.instance.endBlockSlide(session));
    }
  }
}

class _PuzzlePainter extends CustomPainter {
  _PuzzlePainter({
    required this.pieces,
    required this.boardColor,
    required this.themeName,
    required this.active,
    required this.activeOffset,
    required this.showGrid,
    required this.hintedPieceId,
    required this.cell,
    required this.bumpAnimation,
    required this.collisionDirection,
  }) : super(repaint: bumpAnimation);

  final List<PuzzlePiece> pieces;
  final Color boardColor;
  final String themeName;
  final PuzzlePiece? active;
  final double activeOffset;
  final bool showGrid;
  final String? hintedPieceId;
  final double cell;
  final Animation<double> bumpAnimation;
  final double collisionDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final denseBoard = pieces.length > 60;
    final board = Offset.zero & size;
    final boardPaint = Paint();
    if (themeName == 'Neon') {
      boardPaint.shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xff120333), Color(0xff32106d), Color(0xff07152e)],
      ).createShader(board);
    } else if (themeName == 'Ocean') {
      boardPaint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xff0a5574), Color(0xff07334f), Color(0xff021b31)],
      ).createShader(board);
    } else {
      boardPaint.color = boardColor;
    }
    canvas.drawRect(board, boardPaint);
    if (themeName == 'Neon') {
      _paintNeonBoardDetails(canvas, size);
    } else if (themeName == 'Ocean') {
      _paintOceanBoardDetails(canvas, size);
    }
    canvas.drawRect(
      board.deflate(.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: .11),
    );
    canvas.clipRect(board);
    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: .055)
        ..strokeWidth = .7;
      for (var x = 1; x < boardCols; x++) {
        canvas.drawLine(
          Offset(x * cell, 0),
          Offset(x * cell, size.height),
          gridPaint,
        );
      }
      for (var y = 1; y < boardRows; y++) {
        canvas.drawLine(
          Offset(0, y * cell),
          Offset(size.width, y * cell),
          gridPaint,
        );
      }
    }
    for (final piece in pieces) {
      final isActive = identical(piece, active);
      final bump = isActive
          ? -collisionDirection * math.sin(bumpAnimation.value * math.pi) * .13
          : 0.0;
      final offset = isActive ? activeOffset + bump : 0.0;
      final color = _pieceColors[piece.colorIndex % _pieceColors.length];
      final hinted = piece.id == hintedPieceId;
      final cells = pieceCells(piece);
      Path? silhouette;
      for (final own in cells) {
        final dx = piece.horizontal ? offset : 0;
        final dy = piece.horizontal ? 0 : offset;
        final rect = Rect.fromLTWH(
          (own.x + dx) * cell + .35,
          (own.y + dy) * cell + .35,
          cell + .3,
          cell + .3,
        );
        final cellPath = Path()
          ..addRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(cell * .10)),
          );
        silhouette = silhouette == null
            ? cellPath
            : Path.combine(PathOperation.union, silhouette, cellPath);
      }
      if (silhouette != null) {
        if (hinted) {
          canvas.drawShadow(
            silhouette,
            const Color(0xfffff176),
            cell * 1.4,
            false,
          );
          canvas.drawShadow(
            silhouette,
            const Color(0xfff5c7ff),
            cell * .8,
            false,
          );
        }
        final bounds = silhouette.getBounds();
        final topColor = hinted
            ? Color.lerp(color, Colors.white, .60)!
            : Color.lerp(color, Colors.white, .36)!;
        final bottomColor = hinted
            ? Color.lerp(color, Colors.white, .36)!
            : Color.lerp(color, Colors.black, .24)!;
        canvas.drawShadow(
          silhouette,
          Colors.black87,
          cell * (denseBoard ? .24 : .40),
          false,
        );
        canvas.drawPath(
          silhouette,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [topColor, color, bottomColor],
              stops: const [0, .42, 1],
            ).createShader(bounds),
        );
        if (!denseBoard) {
          canvas.drawPath(
            silhouette,
            Paint()
              ..shader = RadialGradient(
                center: const Alignment(-.65, -.72),
                radius: .9,
                colors: [
                  Colors.white.withValues(alpha: hinted ? .34 : .18),
                  Colors.transparent,
                ],
              ).createShader(bounds),
          );
        }
        canvas.save();
        canvas.clipPath(silhouette);
        final stripePaint = Paint()
          ..color = Colors.white.withValues(alpha: hinted ? .34 : .18)
          ..strokeWidth = math.max(1.0, cell * .075)
          ..strokeCap = StrokeCap.round;
        final stripeStep = math.max(6.0, cell * .62);
        for (
          var x = bounds.left - bounds.height;
          x < bounds.right + bounds.height;
          x += stripeStep
        ) {
          canvas.drawLine(
            Offset(x, bounds.bottom + cell),
            Offset(x + bounds.height + cell * 2, bounds.top - cell),
            stripePaint,
          );
        }
        final sparklePaint = Paint()
          ..color = Colors.white.withValues(alpha: hinted ? .95 : .76)
          ..style = PaintingStyle.fill;
        if (!denseBoard) {
          _drawSparkle(
            canvas,
            Offset(
              bounds.left + bounds.width * .25,
              bounds.top + bounds.height * .24,
            ),
            math.max(1.2, cell * .16),
            sparklePaint,
          );
          if (bounds.longestSide > cell * 2.6) {
            _drawSparkle(
              canvas,
              Offset(
                bounds.left + bounds.width * .72,
                bounds.top + bounds.height * .36,
              ),
              math.max(1.0, cell * .11),
              sparklePaint..color = Colors.white.withValues(alpha: .58),
            );
          }
        }
        canvas.restore();
        if (isActive && bumpAnimation.value > 0) {
          canvas.drawPath(
            silhouette,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4
              ..color = Colors.white.withValues(
                alpha: math.sin(bumpAnimation.value * math.pi) * .72,
              ),
          );
        }
        canvas.drawPath(
          silhouette,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = hinted ? 2.8 : 1.35
            ..color = hinted
                ? const Color(0xffffffb0)
                : Color.lerp(color, Colors.black, .28)!,
        );
        canvas.drawPath(
          silhouette,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = hinted ? 1.6 : .65
            ..color = hinted
                ? Colors.white
                : Colors.white.withValues(alpha: .46),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PuzzlePainter old) => true;

  static void _drawSparkle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final narrow = radius * .24;
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + narrow, center.dy - narrow)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx + narrow, center.dy + narrow)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - narrow, center.dy + narrow)
      ..lineTo(center.dx - radius, center.dy)
      ..lineTo(center.dx - narrow, center.dy - narrow)
      ..close();
    canvas.drawPath(path, paint);
  }

  static void _paintNeonBoardDetails(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xffe653ff).withValues(alpha: .20),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .78, size.height * .18),
              radius: size.width * .42,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);
    final line = Paint()
      ..color = const Color(0xff6bf7ff).withValues(alpha: .09)
      ..strokeWidth = .8;
    for (var i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var i = 1; i < 12; i++) {
      final y = size.height * i / 12;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  static void _paintOceanBoardDetails(Canvas canvas, Size size) {
    final bubblePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withValues(alpha: .10);
    for (var i = 0; i < 16; i++) {
      final x = ((i * 47) % 97) / 97 * size.width;
      final y = ((i * 83) % 101) / 101 * size.height;
      final radius = 1.8 + (i % 4) * 1.25;
      canvas.drawCircle(Offset(x, y), radius, bubblePaint);
    }
    final rayPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withValues(alpha: .08), Colors.transparent],
      ).createShader(Offset.zero & size);
    final ray = Path()
      ..moveTo(size.width * .08, 0)
      ..lineTo(size.width * .28, 0)
      ..lineTo(size.width * .58, size.height)
      ..lineTo(size.width * .42, size.height)
      ..close();
    canvas.drawPath(ray, rayPaint);
  }
}

class _GameHud extends StatelessWidget {
  const _GameHud({
    required this.level,
    required this.score,
    required this.time,
    required this.timeLabel,
    required this.remainingMistakes,
    required this.onPause,
    required this.onHint,
  });
  final int level;
  final int score;
  final String time;
  final String timeLabel;
  final int remainingMistakes;
  final VoidCallback onPause;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 78,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: IconButton.filled(
                tooltip: 'Pause',
                onPressed: onPause,
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(44),
                  maximumSize: const Size.square(44),
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xff9d4edd),
                  side: const BorderSide(color: Color(0xffd8b4fe), width: 1.3),
                  shadowColor: const Color(0xffb66aff),
                  elevation: 5,
                ),
                icon: const Icon(Icons.pause, size: 24),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: IconButton.filled(
                tooltip: 'Petunjuk',
                onPressed: onHint,
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(44),
                  maximumSize: const Size.square(44),
                  foregroundColor: const Color(0xffffefad),
                  backgroundColor: const Color(0xff5d2d91),
                  side: const BorderSide(color: Color(0xffb985e8), width: 1.2),
                ),
                icon: const Icon(Icons.lightbulb_rounded, size: 22),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: _HudValue(label: 'SCORE', value: '$score'),
            ),
          ),
          Expanded(
            child: Center(
              child: _HudValue(
                label: 'LEVEL',
                value: level.toString().padLeft(2, '0'),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: _HudValue(label: timeLabel, value: time),
            ),
          ),
          Expanded(
            child: Center(
              child: _HudValue(
                label: 'SISA SALAH',
                value: '$remainingMistakes/$_maximumAllowedMistakes',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _HudValue extends StatelessWidget {
  const _HudValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        height: 10,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 8,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.level,
    required this.canPrevious,
    required this.canNext,
    required this.onContinue,
    required this.onRestart,
    required this.onMode,
    required this.onPrevious,
    required this.onNext,
    required this.onSettings,
  });
  final int level;
  final bool canPrevious;
  final bool canNext;
  final VoidCallback onContinue;
  final VoidCallback onRestart;
  final VoidCallback onMode;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xee100522),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NativeLogo(compact: true),
            const SizedBox(height: 24),
            const Text(
              'LEVEL',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: canPrevious ? onPrevious : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text(
                  level.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                IconButton(
                  onPressed: canNext ? onNext : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .06),
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _PauseAction(
                    icon: Icons.refresh_rounded,
                    label: 'Ulangi',
                    onTap: onRestart,
                  ),
                  _PauseAction(
                    icon: Icons.timer_outlined,
                    label: 'Mode',
                    onTap: onMode,
                  ),
                  _PauseAction(
                    icon: Icons.settings_rounded,
                    label: 'Aturan',
                    onTap: onSettings,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 17),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff8d4fe0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 28),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PauseAction extends StatelessWidget {
  const _PauseAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: Column(
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _SettingsActionCard extends StatelessWidget {
  const _SettingsActionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .045),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: const BorderSide(color: Colors.white12),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xff8d4fe0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 27),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  if (subtitle case final subtitle?) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.name,
    required this.color,
    this.selected = false,
    this.locked = false,
    this.imagePath,
    this.onTap,
  });

  final String name;
  final Color color;
  final bool selected;
  final bool locked;
  final String? imagePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: locked ? .025 : .045),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: BorderSide(
        color: selected ? const Color(0xffb66aff) : Colors.white12,
        width: selected ? 1.5 : 1,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 32,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: Colors.white24),
                ),
                child: imagePath != null && File(imagePath!).existsSync()
                    ? Image.file(File(imagePath!), fit: BoxFit.cover)
                    : name.startsWith('Custom')
                    ? const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 17,
                        color: Colors.white70,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: locked ? Colors.white38 : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (locked)
              const Icon(Icons.lock_rounded, size: 16, color: Color(0xffffcf5a))
            else if (selected)
              const Icon(
                Icons.check_rounded,
                size: 17,
                color: Color(0xffd4a9ff),
              ),
          ],
        ),
      ),
    ),
  );
}

class NativeLogo extends StatelessWidget {
  const NativeLogo({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 48.0;
    return Column(
      children: [
        Text(
          'BALOK',
          style: GoogleFonts.fredoka(
            color: const Color(0xfffff0cf),
            fontSize: size,
            height: .78,
            letterSpacing: -2.5,
            fontWeight: FontWeight.w700,
            shadows: const [
              Shadow(color: Color(0xff210834), offset: Offset(0, 3)),
            ],
          ),
        ),
        Text(
          'KOSONG',
          style: GoogleFonts.fredoka(
            color: const Color(0xffbd6cff),
            fontSize: size,
            height: .82,
            letterSpacing: -2.9,
            fontWeight: FontWeight.w700,
            shadows: const [
              Shadow(color: Color(0xff210834), offset: Offset(0, 3)),
            ],
          ),
        ),
      ],
    );
  }
}
