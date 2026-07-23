import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({
    super.key,
    required this.onFinished,
    this.finalLabel = 'Mulai bermain',
  });

  final VoidCallback onFinished;
  final String finalLabel;

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  static const _steps = [
    (
      icon: '◎',
      title: 'Kosongkan papan',
      text:
          'Tujuannya sederhana: keluarkan semua balok sampai tidak ada satu pun yang tersisa.',
    ),
    (
      icon: '↔',
      title: 'Geret lurus',
      text:
          'Balok horizontal hanya dapat digeret ke kiri atau kanan. Ikuti arah panjang balok.',
    ),
    (
      icon: '↕',
      title: 'Buka jalannya',
      text:
          'Balok vertikal hanya dapat digeret ke atas atau bawah. Keluarkan balok yang tidak terhalang lebih dahulu.',
    ),
    (
      icon: '★',
      title: 'Siap bermain!',
      text:
          'Pilih mode Santai atau Tantangan. Selesaikan lebih cepat dan gunakan sedikit petunjuk untuk mendapat 3 bintang.',
    ),
  ];

  int page = 0;

  @override
  Widget build(BuildContext context) {
    final step = _steps[page];
    final last = page == _steps.length - 1;
    return Scaffold(
      backgroundColor: const Color(0xff130522),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: const Color(0xff210b39),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xff70419b)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 28,
                      offset: Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'CARA BERMAIN · ${page + 1}/${_steps.length}',
                      style: GoogleFonts.fredoka(
                        color: const Color(0xffd8a5ff),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.25,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: _GuideVisual(
                        key: ValueKey(page),
                        page: page,
                        icon: step.icon,
                      ),
                    ),
                    const SizedBox(height: 26),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Column(
                        key: ValueKey('text-$page'),
                        children: [
                          Text(
                            step.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 13),
                          Text(
                            step.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 23),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _steps.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: index == page ? 27 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: index == page
                                ? const Color(0xffb45cff)
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        if (page > 0) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() => page--),
                              style: _buttonStyle(outlined: true),
                              child: const Text('Kembali'),
                            ),
                          ),
                          const SizedBox(width: 11),
                        ],
                        Expanded(
                          flex: page > 0 ? 1 : 2,
                          child: FilledButton(
                            onPressed: last
                                ? widget.onFinished
                                : () => setState(() => page++),
                            style: _buttonStyle(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    last ? widget.finalLabel : 'Berikutnya',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle({bool outlined = false}) =>
      (outlined ? OutlinedButton.styleFrom() : FilledButton.styleFrom())
          .copyWith(
            minimumSize: const WidgetStatePropertyAll(Size.fromHeight(54)),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
            backgroundColor: WidgetStatePropertyAll(
              outlined ? Colors.transparent : const Color(0xff9147df),
            ),
            side: WidgetStatePropertyAll(
              BorderSide(
                color: outlined ? const Color(0xffa869e4) : Colors.transparent,
              ),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
          );
}

class _GuideVisual extends StatelessWidget {
  const _GuideVisual({super.key, required this.page, required this.icon});

  final int page;
  final String icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 210,
    height: 210,
    decoration: BoxDecoration(
      color: const Color(0xff35175a),
      borderRadius: BorderRadius.circular(42),
      border: Border.all(color: const Color(0xff70419b), width: 2),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: page.isEven ? 24 : 92,
          top: 27,
          child: const _MiniBlock(width: 70, color: Color(0xfff47b58)),
        ),
        Positioned(
          right: page.isEven ? 28 : 104,
          bottom: 28,
          child: const _MiniBlock(width: 52, color: Color(0xff56c2ae)),
        ),
        if (page >= 2)
          const Positioned(
            right: 30,
            top: 75,
            child: _MiniBlock(width: 22, height: 75, color: Color(0xffb05cff)),
          ),
        Text(
          icon,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.w500,
            shadows: [Shadow(color: Color(0xffb45cff), blurRadius: 20)],
          ),
        ),
      ],
    ),
  );
}

class _MiniBlock extends StatelessWidget {
  const _MiniBlock({
    required this.width,
    this.height = 20,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(7),
    ),
  );
}
