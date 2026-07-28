import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({
    super.key,
    required this.onRelaxed,
    required this.onChallenge,
    required this.onCancel,
    this.onRelaxedSelected,
    this.onChallengeSelected,
    this.hasProgress = false,
    this.energy = 5,
  });

  final VoidCallback onRelaxed;
  final VoidCallback onChallenge;
  final VoidCallback onCancel;
  final ValueChanged<bool>? onRelaxedSelected;
  final ValueChanged<bool>? onChallengeSelected;
  final bool hasProgress;
  final int energy;

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  bool challengeSelected = false;

  void _selectMode({required bool challenge}) {
    if (challenge && widget.energy <= 0) return;
    setState(() => challengeSelected = challenge);
    _startMode(challenge: challenge, fromLevelOne: !widget.hasProgress);
  }

  void _startMode({required bool challenge, required bool fromLevelOne}) {
    if (challenge) {
      if (widget.energy <= 0) return;
      final callback = widget.onChallengeSelected;
      if (callback != null) {
        callback(fromLevelOne);
      } else {
        widget.onChallenge();
      }
      return;
    }
    final callback = widget.onRelaxedSelected;
    if (callback != null) {
      callback(fromLevelOne);
    } else {
      widget.onRelaxed();
    }
  }

  void _start({required bool fromLevelOne}) {
    _startMode(challenge: challengeSelected, fromLevelOne: fromLevelOne);
  }

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
                          '⚡ ${widget.energy}/5 ENERGY',
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .045),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Lanjutkan permainan sebelumnya atau mulai lagi dari Level 1?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            Expanded(
                              child: _ProgressChoice(
                                label: 'Lanjutkan',
                                icon: Icons.play_arrow_rounded,
                                emphasized: true,
                                onTap: widget.hasProgress
                                    ? () => _start(fromLevelOne: false)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _ProgressChoice(
                                label: 'Dari Level 1',
                                icon: Icons.replay_rounded,
                                onTap: widget.hasProgress
                                    ? () => _start(fromLevelOne: true)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 19),
                  Text(
                    widget.hasProgress
                        ? 'Atau ketuk mode untuk langsung melanjutkan:'
                        : 'Ketuk mode untuk mulai bermain:',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 9),
                  _ModeCard(
                    icon: Icons.all_inclusive_rounded,
                    title: 'Santai',
                    description:
                        'Timer menghitung waktu, tidak ada batas energy.',
                    selected: !challengeSelected,
                    onTap: () => _selectMode(challenge: false),
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    icon: Icons.timer_outlined,
                    title: 'Tantangan · 1 ⚡',
                    description:
                        'Countdown habis = ulang level. Energy dipakai per percobaan.',
                    selected: challengeSelected,
                    onTap: widget.energy > 0
                        ? () => _selectMode(challenge: true)
                        : null,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: Center(
                      child: TextButton(
                        onPressed: widget.onCancel,
                        child: const Text('Batal'),
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
}

class _ProgressChoice extends StatelessWidget {
  const _ProgressChoice({
    required this.label,
    required this.icon,
    this.onTap,
    this.emphasized = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : .38,
      child: Material(
        color: emphasized && enabled
            ? const Color(0xff6f35a8)
            : Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: emphasized && enabled
                    ? const Color(0xffc084fc)
                    : Colors.white24,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
