import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() => runApp(const BalokKosongApp());

class BalokKosongApp extends StatelessWidget {
  const BalokKosongApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BALOK KOSONG',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Arial',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xffa855f7),
            brightness: Brightness.dark,
          ),
        ),
        home: const HomeScreen(),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xff170627),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const _Logo(),
                const SizedBox(height: 18),
                const Text('HABISKAN SEMUA BALOK',
                    style: TextStyle(
                      color: Color(0xffffd166),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    )),
                const Spacer(),
                _PrimaryButton(
                  label: 'MAIN',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GameScreen()),
                  ),
                ),
                const SizedBox(height: 13),
                _SecondaryButton(
                  label: 'CARA BERMAIN',
                  icon: Icons.help_outline_rounded,
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: const Color(0xff2d1246),
                    builder: (_) => const _HowToPlay(),
                  ),
                ),
                const Spacer(flex: 2),
                const Text('Main sebagai Tamu',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Masuk untuk menyinkronkan skor, level, dan bonus Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _level = 1;
  int _score = 0;
  bool _paused = false;
  late List<Block> _blocks;

  @override
  void initState() {
    super.initState();
    _resetLevel();
  }

  void _resetLevel() => _blocks = demoBlocks(_level);

  void _restart() => setState(_resetLevel);

  void _nextLevel() => setState(() {
        _level++;
        _resetLevel();
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xff11031d),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TopCircle(
                      icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      onTap: () => setState(() => _paused = !_paused),
                    ),
                    Column(children: [
                      const Text('SCORE', style: _topLabel),
                      Text('$_score', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                      Text('LEVEL $_level', style: const TextStyle(color: Color(0xffd8a5ff), fontWeight: FontWeight.w800)),
                    ]),
                    const _TimerPill(),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: _paused
                      ? _PausePanel(onContinue: () => setState(() => _paused = false), onRestart: _restart)
                      : PuzzleBoard(
                          blocks: _blocks,
                          onExit: (block) => setState(() {
                            _blocks.remove(block);
                            _score += 100;
                            if (_blocks.isEmpty) {
                              WidgetsBinding.instance.addPostFrameCallback((_) => _showWin());
                            }
                          }),
                        ),
                ),
              ),
            ],
          ),
        ),
      );

  void _showWin() => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xff2c1045),
          title: const Text('Papan kosong!'),
          content: const Text('Semua balok sudah keluar.'),
          actions: [
            TextButton(onPressed: () { Navigator.pop(context); _restart(); }, child: const Text('ULANGI')),
            FilledButton(onPressed: () { Navigator.pop(context); _nextLevel(); }, child: const Text('LEVEL BERIKUTNYA')),
          ],
        ),
      );
}

const _topLabel = TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.6);

class PuzzleBoard extends StatefulWidget {
  const PuzzleBoard({super.key, required this.blocks, required this.onExit});
  final List<Block> blocks;
  final ValueChanged<Block> onExit;
  @override
  State<PuzzleBoard> createState() => _PuzzleBoardState();
}

class _PuzzleBoardState extends State<PuzzleBoard> {
  Block? _active;
  double _origin = 0;
  double _dragDistance = 0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) {
          final side = math.min(c.maxWidth, c.maxHeight);
          final cell = side / boardSize;
          return Center(
            child: SizedBox(
              width: side,
              height: side,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xff25103a),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xff7f3fb0), width: 2),
                ),
                child: Stack(
                  children: [
                    CustomPaint(size: Size.square(side), painter: GridPainter(cell)),
                    for (final block in widget.blocks)
                      _MovableBlock(
                        block: block,
                        cell: cell,
                        onStart: () { _active = block; _origin = block.axis == Axis.horizontal ? block.x : block.y; _dragDistance = 0; },
                        onUpdate: (delta) {
                          if (_active != block) return;
                          setState(() {
                            _dragDistance += delta;
                            final next = _origin + _dragDistance / cell;
                            if (block.axis == Axis.horizontal) {
                              block.x = next.clamp(-block.length + .18, boardSize - .18);
                            } else {
                              block.y = next.clamp(-block.length + .18, boardSize - .18);
                            }
                          });
                        },
                        onEnd: () {
                          if ((block.axis == Axis.horizontal && (block.x < -.7 || block.x > boardSize - .3)) ||
                              (block.axis == Axis.vertical && (block.y < -.7 || block.y > boardSize - .3))) {
                            widget.onExit(block);
                          }
                          _active = null;
                        },
                      ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Text('Geser balok sampai keluar', style: TextStyle(color: Colors.white.withValues(alpha: .38), fontSize: 10)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

class _MovableBlock extends StatelessWidget {
  const _MovableBlock({required this.block, required this.cell, required this.onStart, required this.onUpdate, required this.onEnd});
  final Block block;
  final double cell;
  final VoidCallback onStart;
  final ValueChanged<double> onUpdate;
  final VoidCallback onEnd;
  @override
  Widget build(BuildContext context) {
    final horizontal = block.axis == Axis.horizontal;
    return Positioned(
      left: block.x * cell + 4,
      top: block.y * cell + 4,
      width: (horizontal ? block.length : 1) * cell - 8,
      height: (horizontal ? 1 : block.length) * cell - 8,
      child: GestureDetector(
        onPanStart: (_) => onStart(),
        onPanUpdate: (d) => onUpdate(horizontal ? d.delta.dx : d.delta.dy),
        onPanEnd: (_) => onEnd(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cell * .24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(block.color, Colors.white, .32)!, block.color, Color.lerp(block.color, Colors.black, .22)!],
            ),
            boxShadow: [BoxShadow(color: block.color.withValues(alpha: .5), blurRadius: 10, spreadRadius: 1)],
            border: Border.all(color: Colors.white.withValues(alpha: .32)),
          ),
          child: Center(child: Container(width: horizontal ? 28 : 4, height: horizontal ? 4 : 28, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .38), borderRadius: BorderRadius.circular(9)))),
        ),
      ),
    );
  }
}

class Block {
  Block(this.x, this.y, this.length, this.axis, this.color);
  double x;
  double y;
  final int length;
  final Axis axis;
  final Color color;
}

const boardSize = 7;
List<Block> demoBlocks(int level) {
  const colors = [Color(0xffa855f7), Color(0xffff6ba6), Color(0xff39d9c0), Color(0xffffc857), Color(0xff5597ff), Color(0xfff47752)];
  final base = [
    Block(.8, .7, 3, Axis.horizontal, colors[0]), Block(4.7, .5, 4, Axis.vertical, colors[1]),
    Block(.2, 2.1, 4, Axis.horizontal, colors[2]), Block(2.1, 3.2, 3, Axis.vertical, colors[3]),
    Block(3.4, 5.3, 3, Axis.horizontal, colors[4]), Block(5.8, 3.5, 3, Axis.vertical, colors[5]),
  ];
  if (level > 1) base.addAll([Block(.4, 5.5, 3, Axis.horizontal, colors[1]), Block(1.1, .1, 3, Axis.vertical, colors[2])]);
  return base;
}

class GridPainter extends CustomPainter {
  GridPainter(this.cell);
  final double cell;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: .065)..strokeWidth = 1;
    for (var i = 1; i < boardSize; i++) { canvas.drawLine(Offset(i * cell, 0), Offset(i * cell, size.height), p); canvas.drawLine(Offset(0, i * cell), Offset(size.width, i * cell), p); }
  }
  @override bool shouldRepaint(covariant GridPainter old) => old.cell != cell;
}

class _Logo extends StatelessWidget { const _Logo(); @override Widget build(BuildContext context) => const Column(children:[Text('BALOK',style:TextStyle(fontSize:48,fontWeight:FontWeight.w900,color:Color(0xfffff0cf),height:.85)),Text('KOSONG',style:TextStyle(fontSize:48,fontWeight:FontWeight.w900,color:Color(0xffbd6cff),height:.9))]); }
class _PrimaryButton extends StatelessWidget { const _PrimaryButton({required this.label,required this.icon,required this.onPressed}); final String label; final IconData icon; final VoidCallback onPressed; @override Widget build(BuildContext context)=>SizedBox(width:double.infinity,height:60,child:FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:const Color(0xffa855f7),foregroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18))),onPressed:onPressed,icon:Icon(icon),label:Text(label,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900)))); }
class _SecondaryButton extends StatelessWidget { const _SecondaryButton({required this.label,required this.icon,required this.onPressed}); final String label; final IconData icon; final VoidCallback onPressed; @override Widget build(BuildContext context)=>SizedBox(width:double.infinity,height:54,child:OutlinedButton.icon(style:OutlinedButton.styleFrom(foregroundColor:Colors.white,side:const BorderSide(color:Color(0xffa855f7)),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18))),onPressed:onPressed,icon:Icon(icon),label:Text(label,style:const TextStyle(fontWeight:FontWeight.w900)))); }
class _TopCircle extends StatelessWidget { const _TopCircle({required this.icon,required this.onTap}); final IconData icon; final VoidCallback onTap; @override Widget build(BuildContext context)=>IconButton.filled(onPressed:onTap,icon:Icon(icon),style:IconButton.styleFrom(backgroundColor:const Color(0xff31134c),foregroundColor:Colors.white)); }
class _TimerPill extends StatelessWidget { const _TimerPill(); @override Widget build(BuildContext context)=>const DecoratedBox(decoration:BoxDecoration(color:Color(0xff31134c),borderRadius:BorderRadius.all(Radius.circular(20))),child:Padding(padding:EdgeInsets.symmetric(horizontal:14,vertical:10),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.timer_outlined,color:Color(0xffffd166),size:18),SizedBox(width:6),Text('00:00',style:TextStyle(fontWeight:FontWeight.w900))]))); }
class _PausePanel extends StatelessWidget { const _PausePanel({required this.onContinue,required this.onRestart}); final VoidCallback onContinue,onRestart; @override Widget build(BuildContext context)=>Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const _Logo(),const SizedBox(height:32),const Text('DIJEDA',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:20),_PrimaryButton(label:'LANJUTKAN',icon:Icons.play_arrow_rounded,onPressed:onContinue),const SizedBox(height:10),_SecondaryButton(label:'ULANGI LEVEL',icon:Icons.refresh_rounded,onPressed:onRestart)])); }
class _HowToPlay extends StatelessWidget { const _HowToPlay(); @override Widget build(BuildContext context)=>const Padding(padding:EdgeInsets.fromLTRB(28,34,28,50),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.swipe_rounded,size:48,color:Color(0xffd8a5ff)),SizedBox(height:18),Text('CARA BERMAIN',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),SizedBox(height:12),Text('Geser balok horizontal hanya ke kiri atau kanan. Geser balok vertikal hanya ke atas atau bawah. Keluarkan seluruh balok dari papan.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white70,fontSize:16,height:1.45))])); }
