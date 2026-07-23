import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_service.dart';
import 'game_engine.dart';
import 'help_feedback.dart';
import 'how_to_play.dart';
import 'mode_selection.dart';
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

const _themes = {
  'Gelap': (Color(0xff170b2d), Color(0xff35215e)),
  'Midnight': (Color(0xff18082d), Color(0xff42206f)),
  'Forest': (Color(0xff132a24), Color(0xff294b40)),
  'Plum': (Color(0xff281c30), Color(0xff4b3653)),
  'Sand': (Color(0xff3b3025), Color(0xff695845)),
};

class NativeGameScreen extends StatefulWidget {
  const NativeGameScreen({
    super.key,
    required this.homeBuilder,
    this.challengeMode = false,
  });

  final bool challengeMode;
  final WidgetBuilder homeBuilder;

  @override
  State<NativeGameScreen> createState() => _NativeGameScreenState();
}

class _NativeGameScreenState extends State<NativeGameScreen> {
  int levelIndex = 0;
  int score = 0;
  int moves = 0;
  int elapsedSeconds = 0;
  int remainingSeconds = 0;
  bool paused = false;
  late bool challengeMode;
  bool timeoutDialogOpen = false;
  bool gridVisible = true;
  bool musicEnabled = true;
  String? hintedPieceId;
  String themeName = 'Midnight';
  late PuzzleEngine engine;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    challengeMode = widget.challengeMode;
    _loadLevel(0);
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
        if (timedOut) _showTimeout();
      }
    });
  }

  Future<void> _loadSettings() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      levelIndex =
          (preferences.getInt('balok_level') ?? 1).clamp(1, totalLevels) - 1;
      score = preferences.getInt('balok_score') ?? 0;
      gridVisible = preferences.getBool('balok_grid_visible') ?? true;
      musicEnabled = preferences.getBool('balok_music_enabled') ?? true;
      themeName = preferences.getString('balok_theme_name') ?? 'Midnight';
      if (!_themes.containsKey(themeName)) themeName = 'Midnight';
      _loadLevel(levelIndex);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _loadLevel(int next) {
    levelIndex = next.clamp(0, totalLevels - 1);
    engine = PuzzleEngine(
      generateLevel(levelIndex + 4, levelPieceCount(levelIndex)),
    );
    remainingSeconds = 45 + engine.pieces.length * 3;
    elapsedSeconds = 0;
    moves = 0;
    paused = false;
    timeoutDialogOpen = false;
    hintedPieceId = null;
  }

  void _restart() => setState(() => _loadLevel(levelIndex));

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

  String get _clock {
    final shown = challengeMode ? remainingSeconds : elapsedSeconds;
    final minutes = shown ~/ 60;
    final seconds = shown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showHint() {
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
    setState(() {
      hintedPieceId = best?.id;
      paused = false;
    });
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
        },
        onChallenge: () {
          Navigator.pop(modeContext);
          setState(() {
            challengeMode = true;
            _loadLevel(levelIndex);
          });
        },
        onCancel: () => Navigator.pop(modeContext),
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
          },
          child: const Text('Mode Santai'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final palette = _themes[themeName]!;
    return Scaffold(
      backgroundColor: palette.$1,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PuzzleCanvas(
                    engine: engine,
                    boardColor: palette.$2,
                    showGrid: gridVisible,
                    disabled: paused,
                    hintedPieceId: hintedPieceId,
                    onHintConsumed: () => setState(() => hintedPieceId = null),
                    onExit: _onPieceExit,
                    onMove: () => setState(() => moves++),
                  ),
                ),
                _GameHud(
                  level: levelIndex + 1,
                  score: score,
                  time: _clock,
                  timeLabel: challengeMode ? 'TANTANGAN' : 'WAKTU',
                  onPause: () => setState(() => paused = true),
                ),
              ],
            ),
            if (paused)
              _PauseOverlay(
                level: levelIndex + 1,
                canPrevious: levelIndex > 0,
                canNext: levelIndex < totalLevels - 1,
                onContinue: () => setState(() => paused = false),
                onRestart: _restart,
                onHint: _showHint,
                onMode: _showMode,
                onPrevious: () => setState(() => _loadLevel(levelIndex - 1)),
                onNext: () => setState(() => _loadLevel(levelIndex + 1)),
                onSettings: _showSettings,
                onHome: () => Navigator.pop(context),
              ),
          ],
        ),
      ),
    );
  }

  void _showRules() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (guideContext) => HowToPlayScreen(
        finalLabel: 'Kembali bermain',
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

  void _showSettings() => showModalBottomSheet<void>(
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
                  Text(
                    'ATURAN & PENGATURAN',
                    style: GoogleFonts.fredoka(
                      color: const Color(0xffd9a9ff),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
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
                    subtitle: 'Pilih akun atau Main sebagai Tamu',
                    onTap: () {
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .045),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        'Tampilkan grid',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: const Text(
                        'Garis bantu pada papan permainan',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      value: gridVisible,
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xff8d4fe0),
                      onChanged: (value) async {
                        setState(() => gridVisible = value);
                        updateSheet(() {});
                        final preferences =
                            await SharedPreferences.getInstance();
                        await preferences.setBool('balok_grid_visible', value);
                        await FirebaseService.instance.saveSettings(
                          gridVisible: value,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .045),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white12),
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
                        final preferences =
                            await SharedPreferences.getInstance();
                        await preferences.setBool('balok_music_enabled', value);
                        await FirebaseService.instance.saveSettings(
                          musicEnabled: value,
                        );
                      },
                    ),
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
                      for (final entry in _themes.entries)
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
                      const _ThemeOption(
                        name: 'Neon · ✦',
                        color: Color(0xff130624),
                        locked: true,
                      ),
                      const _ThemeOption(
                        name: 'Ocean · ✦',
                        color: Color(0xff102b48),
                        locked: true,
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

  void _showStore() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const StoreScreen()));

  void _showComplete() => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      unawaited(
        FirebaseService.instance.saveProgress(
          level: levelIndex == totalLevels - 1 ? totalLevels : levelIndex + 2,
          score: score,
          bestTimeSeconds: elapsedSeconds,
          moves: moves,
          challengeMode: challengeMode,
        ),
      );
      return AlertDialog(
        backgroundColor: const Color(0xff24103c),
        icon: const Icon(
          Icons.check_circle_rounded,
          color: Color(0xff54c889),
          size: 62,
        ),
        title: const Text(
          'Papan kosong!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Level ${levelIndex + 1} selesai dalam $_clock.\n$moves langkah · $score poin',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(
                () => _loadLevel(
                  levelIndex == totalLevels - 1 ? 0 : levelIndex + 1,
                ),
              );
            },
            child: Text(
              levelIndex == totalLevels - 1 ? 'MAIN LAGI' : 'LEVEL BERIKUTNYA',
            ),
          ),
        ],
      );
    },
  );
}

class PuzzleCanvas extends StatefulWidget {
  const PuzzleCanvas({
    super.key,
    required this.engine,
    required this.boardColor,
    required this.showGrid,
    required this.disabled,
    required this.hintedPieceId,
    required this.onHintConsumed,
    required this.onExit,
    required this.onMove,
  });

  final PuzzleEngine engine;
  final Color boardColor;
  final bool showGrid;
  final bool disabled;
  final String? hintedPieceId;
  final VoidCallback onHintConsumed;
  final ValueChanged<PuzzlePiece> onExit;
  final VoidCallback onMove;

  @override
  State<PuzzleCanvas> createState() => _PuzzleCanvasState();
}

class _PuzzleCanvasState extends State<PuzzleCanvas> {
  PuzzlePiece? active;
  double dragCells = 0;
  double maxNegative = 0;
  double maxPositive = 0;

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
          child: CustomPaint(
            size: Size(width, height),
            painter: _PuzzlePainter(
              pieces: widget.engine.pieces,
              boardColor: widget.boardColor,
              active: active,
              activeOffset: dragCells,
              showGrid: widget.showGrid,
              hintedPieceId: widget.hintedPieceId,
              cell: cell,
            ),
          ),
        ),
      );
    },
  );

  void _start(Offset point, double cellSize) {
    final touchX = point.dx / cellSize;
    final touchY = point.dy / cellSize;
    const hitPadding = .28;
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
        });
        return;
      }
    }
  }

  void _update(Offset delta, double cellSize) {
    final piece = active;
    if (piece == null) return;
    final rawDelta = piece.horizontal ? delta.dx : delta.dy;
    if (piece.id == widget.hintedPieceId && rawDelta.abs() > .5) {
      widget.onHintConsumed();
    }
    setState(() {
      dragCells = (dragCells + (rawDelta / cellSize) * 1.28).clamp(
        -maxNegative,
        maxPositive,
      );
    });
  }

  void _end() {
    final piece = active;
    if (piece == null) return;
    var snapped = dragCells.round();
    if (snapped == 0 && dragCells.abs() >= .18) {
      snapped = dragCells.isNegative ? -1 : 1;
    }
    if (widget.engine.isOutside(piece, snapped)) {
      widget.onExit(piece);
    } else if (snapped != 0 &&
        widget.engine.canPlace(
          piece,
          piece.horizontal ? snapped : 0,
          piece.horizontal ? 0 : snapped,
        )) {
      widget.engine.commit(piece, snapped);
      widget.onMove();
    }
    setState(() {
      active = null;
      dragCells = 0;
    });
  }
}

class _PuzzlePainter extends CustomPainter {
  _PuzzlePainter({
    required this.pieces,
    required this.boardColor,
    required this.active,
    required this.activeOffset,
    required this.showGrid,
    required this.hintedPieceId,
    required this.cell,
  });

  final List<PuzzlePiece> pieces;
  final Color boardColor;
  final PuzzlePiece? active;
  final double activeOffset;
  final bool showGrid;
  final String? hintedPieceId;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final board = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(22),
    );
    canvas.drawRRect(board, Paint()..color = boardColor);
    canvas.clipRRect(board);
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
      final offset = identical(piece, active) ? activeOffset : 0.0;
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
            : Color.lerp(color, Colors.white, .13)!;
        final bottomColor = hinted
            ? Color.lerp(color, Colors.white, .36)!
            : Color.lerp(color, Colors.black, .08)!;
        canvas.drawShadow(silhouette, Colors.black87, cell * .28, false);
        canvas.drawPath(
          silhouette,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [topColor, color, bottomColor],
              stops: const [0, .48, 1],
            ).createShader(bounds),
        );
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
        canvas.restore();
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
}

class _GameHud extends StatelessWidget {
  const _GameHud({
    required this.level,
    required this.score,
    required this.time,
    required this.timeLabel,
    required this.onPause,
  });
  final int level;
  final int score;
  final String time;
  final String timeLabel;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 70,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Row(
        children: [
          IconButton.filled(
            onPressed: onPause,
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xff9d4edd),
              side: const BorderSide(color: Color(0xffd8b4fe), width: 1.3),
              shadowColor: const Color(0xffb66aff),
              elevation: 5,
            ),
            icon: const Icon(Icons.pause, size: 24),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _HudValue(label: 'SCORE', value: '$score'),
                const SizedBox(width: 24),
                _HudValue(
                  label: 'LEVEL',
                  value: level.toString().padLeft(2, '0'),
                ),
              ],
            ),
          ),
          _HudValue(label: timeLabel, value: time, right: true),
        ],
      ),
    ),
  );
}

class _HudValue extends StatelessWidget {
  const _HudValue({
    required this.label,
    required this.value,
    this.right = false,
  });
  final String label;
  final String value;
  final bool right;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: right
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 8,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w800,
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
    required this.onHint,
    required this.onMode,
    required this.onPrevious,
    required this.onNext,
    required this.onSettings,
    required this.onHome,
  });
  final int level;
  final bool canPrevious;
  final bool canNext;
  final VoidCallback onContinue;
  final VoidCallback onRestart;
  final VoidCallback onHint;
  final VoidCallback onMode;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSettings;
  final VoidCallback onHome;

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
                    icon: Icons.lightbulb_rounded,
                    label: 'Petunjuk',
                    onTap: onHint,
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
                  _PauseAction(
                    icon: Icons.home_rounded,
                    label: 'Utama',
                    onTap: onHome,
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
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
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
    this.onTap,
  });

  final String name;
  final Color color;
  final bool selected;
  final bool locked;
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
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(13),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
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
            if (selected)
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
