import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({
    super.key,
    required this.onRelaxed,
    required this.onChallenge,
    required this.onCancel,
    this.energy = 5,
  });

  final VoidCallback onRelaxed;
  final VoidCallback onChallenge;
  final VoidCallback onCancel;
  final int energy;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff130522),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
              decoration: BoxDecoration(
                color: const Color(0xff210b39),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xff70419b)),
              ),
              child: Column(
                children: [
                  Text(
                    'PILIH MODE',
                    style: GoogleFonts.fredoka(
                      color: const Color(0xffd8a5ff),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cara bermain',
                    style: GoogleFonts.fredoka(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 19),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .045),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '⚡ $energy/5 ENERGY',
                          style: const TextStyle(
                            color: Color(0xffd8a5ff),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Pulih 1 energy setiap 25 menit',
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 19),
                  _ModeCard(
                    icon: Icons.all_inclusive_rounded,
                    title: 'Santai',
                    description:
                        'Timer menghitung waktu, tidak ada batas energy.',
                    selected: true,
                    onTap: onRelaxed,
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    icon: Icons.timer_outlined,
                    title: 'Tantangan · 1 ⚡',
                    description:
                        'Countdown habis = ulang level. Energy dipakai per percobaan.',
                    onTap: energy > 0 ? onChallenge : null,
                  ),
                  const SizedBox(height: 20),
                  TextButton(onPressed: onCancel, child: const Text('Batal')),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: onTap == null ? .025 : .055),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: BorderSide(
        color: selected ? const Color(0xffa855f7) : Colors.white12,
        width: selected ? 1.6 : 1,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 49,
              height: 49,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xff4f2879),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: Colors.white, size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      height: 1.3,
                    ),
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
