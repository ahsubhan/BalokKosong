import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'game_engine.dart';

const _pieceColors = [
  Color(0xffe5534b),
  Color(0xff438fcb),
  Color(0xffe1b844),
  Color(0xff55b797),
  Color(0xff9476c1),
  Color(0xffec7e43),
  Color(0xffdc7295),
];

const _themes = {
  'Gelap': (Color(0xff170b2d), Color(0xff35215e)),
  'Midnight': (Color(0xff18082d), Color(0xff42206f)),
  'Forest': (Color(0xff132a24), Color(0xff294b40)),
  'Plum': (Color(0xff281c30), Color(0xff4b3653)),
  'Sand': (Color(0xff3b3025), Color(0xff695845)),
};

class NativeGameScreen extends StatefulWidget {
  const NativeGameScreen({super.key});

  @override
  State<NativeGameScreen> createState() => _NativeGameScreenState();
}

class _NativeGameScreenState extends State<NativeGameScreen> {
  int levelIndex = 0;
  int score = 0;
  int moves = 0;
  int elapsedSeconds = 0;
  bool paused = false;
  bool gridVisible = true;
  String themeName = 'Midnight';
  late PuzzleEngine engine;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _loadLevel(0);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !paused && engine.pieces.isNotEmpty) {
        setState(() => elapsedSeconds++);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _loadLevel(int next) {
    levelIndex = next.clamp(0, 16);
    engine = PuzzleEngine(
      generateLevel(levelIndex + 4, levelPieceCount(levelIndex)),
    );
    elapsedSeconds = 0;
    moves = 0;
    paused = false;
  }

  void _restart() => setState(() => _loadLevel(levelIndex));

  void _onPieceExit(PuzzlePiece piece) {
    setState(() {
      engine.pieces.removeWhere((candidate) => candidate.id == piece.id);
      moves++;
      score += math.max(25, 120 - elapsedSeconds ~/ 5);
    });
    if (engine.pieces.isEmpty) {
      Future<void>.delayed(const Duration(milliseconds: 260), _showComplete);
    }
  }

  String get _clock {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

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
                _GameHud(
                  level: levelIndex + 1,
                  score: score,
                  time: _clock,
                  onPause: () => setState(() => paused = true),
                ),
                Expanded(
                  child: PuzzleCanvas(
                    engine: engine,
                    boardColor: palette.$2,
                    showGrid: gridVisible,
                    disabled: paused,
                    onExit: _onPieceExit,
                    onMove: () => setState(() => moves++),
                  ),
                ),
              ],
            ),
            if (paused)
              _PauseOverlay(
                level: levelIndex + 1,
                canPrevious: levelIndex > 0,
                canNext: levelIndex < 16,
                onContinue: () => setState(() => paused = false),
                onRestart: _restart,
                onPrevious: () => setState(() => _loadLevel(levelIndex - 1)),
                onNext: () => setState(() => _loadLevel(levelIndex + 1)),
                onSettings: _showSettings,
                onRules: _showRules,
                onHome: () => Navigator.pop(context),
              ),
          ],
        ),
      ),
    );
  }

  void _showRules() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xff1b082f),
    builder: (_) => const _RulesSheet(),
  );

  void _showSettings() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xff1b082f),
    builder: (sheetContext) => StatefulBuilder(
      builder: (_, updateSheet) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 38),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NativeLogo(compact: true),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text(
                'Tampilkan grid',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Garis bantu pada papan permainan'),
              value: gridVisible,
              activeThumbColor: const Color(0xffb66aff),
              onChanged: (value) {
                setState(() => gridVisible = value);
                updateSheet(() {});
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'TEMA LATAR',
                style: GoogleFonts.fredoka(
                  color: const Color(0xffd4a9ff),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: _themes.entries.map((entry) {
                final selected = themeName == entry.key;
                return ChoiceChip(
                  label: Text(entry.key),
                  selected: selected,
                  avatar: CircleAvatar(backgroundColor: entry.value.$2),
                  selectedColor: const Color(0xff7540b5),
                  onSelected: (_) {
                    setState(() => themeName = entry.key);
                    updateSheet(() {});
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ),
  );

  void _showComplete() => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
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
            setState(() => _loadLevel(levelIndex == 16 ? 0 : levelIndex + 1));
          },
          child: Text(levelIndex == 16 ? 'MAIN LAGI' : 'LEVEL BERIKUTNYA'),
        ),
      ],
    ),
  );
}

class PuzzleCanvas extends StatefulWidget {
  const PuzzleCanvas({
    super.key,
    required this.engine,
    required this.boardColor,
    required this.showGrid,
    required this.disabled,
    required this.onExit,
    required this.onMove,
  });

  final PuzzleEngine engine;
  final Color boardColor;
  final bool showGrid;
  final bool disabled;
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
          onPanStart: widget.disabled
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
              cell: cell,
            ),
          ),
        ),
      );
    },
  );

  void _start(Offset point, double cellSize) {
    final x = (point.dx / cellSize).floor();
    final y = (point.dy / cellSize).floor();
    for (final piece in widget.engine.pieces.reversed) {
      if (pieceCells(piece).any((cell) => cell.x == x && cell.y == y)) {
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
    setState(() {
      dragCells = (dragCells + rawDelta / cellSize).clamp(
        -maxNegative,
        maxPositive,
      );
    });
  }

  void _end() {
    final piece = active;
    if (piece == null) return;
    final snapped = dragCells.round();
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
    required this.cell,
  });

  final List<PuzzlePiece> pieces;
  final Color boardColor;
  final PuzzlePiece? active;
  final double activeOffset;
  final bool showGrid;
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
        canvas.drawShadow(silhouette, Colors.black54, cell * .16, false);
        canvas.drawPath(silhouette, Paint()..color = color);
        canvas.drawPath(
          silhouette,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = .75
            ..color = Colors.white.withValues(alpha: .32),
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
    required this.onPause,
  });
  final int level;
  final int score;
  final String time;
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
              backgroundColor: const Color(0xff080312),
              side: const BorderSide(color: Colors.white24),
            ),
            icon: const Icon(Icons.pause_rounded),
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
          _HudValue(label: 'WAKTU', value: time, right: true),
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
    required this.onPrevious,
    required this.onNext,
    required this.onSettings,
    required this.onRules,
    required this.onHome,
  });
  final int level;
  final bool canPrevious;
  final bool canNext;
  final VoidCallback onContinue;
  final VoidCallback onRestart;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSettings;
  final VoidCallback onRules;
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
                    icon: Icons.settings_rounded,
                    label: 'Aturan',
                    onTap: onSettings,
                  ),
                  _PauseAction(
                    icon: Icons.help_rounded,
                    label: 'Cara main',
                    onTap: onRules,
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

class _RulesSheet extends StatelessWidget {
  const _RulesSheet();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 30, 28, 42),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'CARA BERMAIN',
          style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        const Text(
          'Geret balok mengikuti arah panjangnya. Balok horizontal hanya bergerak kiri–kanan dan balok vertikal hanya bergerak atas–bawah.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, height: 1.45),
        ),
        const SizedBox(height: 12),
        const Text(
          'Keluarkan semua balok sampai papan benar-benar kosong.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xffd4a9ff),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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
