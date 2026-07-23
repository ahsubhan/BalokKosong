import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_service.dart';

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key, required this.onOpenGuide});

  final VoidCallback onOpenGuide;

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> {
  final controller = TextEditingController();
  bool sending = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff130522),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      title: Text(
        'HELP & FEEDBACK',
        style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
      ),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _HelpCard(
            icon: Icons.play_arrow_rounded,
            title: 'Lihat cara bermain',
            subtitle: 'Buka kembali panduan singkat 4 halaman',
            onTap: widget.onOpenGuide,
          ),
          const SizedBox(height: 12),
          Text(
            'PERTANYAAN UMUM',
            style: GoogleFonts.fredoka(
              color: const Color(0xffd8a5ff),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const _FaqTile(
            question: 'Bagaimana cara mengeluarkan balok?',
            answer:
                'Geret sesuai arah panjangnya. Balok horizontal bergerak kiri–kanan dan balok vertikal bergerak atas–bawah.',
          ),
          const _FaqTile(
            question: 'Untuk apa Token Petunjuk?',
            answer:
                'Token menyalakan satu balok yang dapat digerakkan. Sorotan berhenti setelah balok digeser manual.',
          ),
          const _FaqTile(
            question: 'Apa perbedaan Santai dan Tantangan?',
            answer:
                'Santai tidak memiliki batas waktu. Tantangan memakai countdown dan energy per percobaan.',
          ),
          const SizedBox(height: 18),
          Text(
            'KIRIM FEEDBACK',
            style: GoogleFonts.fredoka(
              color: const Color(0xffd8a5ff),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            minLines: 4,
            maxLines: 7,
            decoration: InputDecoration(
              hintText: 'Tulis masalah atau saran Anda…',
              filled: true,
              fillColor: Colors.white.withValues(alpha: .05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.white12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: sending ? null : _submit,
              icon: sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(sending ? 'Mengirim…' : 'Kirim feedback'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff9147df),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    final feedback = controller.text.trim();
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tuliskan feedback terlebih dahulu.')),
      );
      return;
    }
    setState(() => sending = true);
    try {
      await FirebaseService.instance.submitFeedback(feedback);
      if (!mounted) return;
      controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terima kasih. Feedback sudah terkirim.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Feedback belum terkirim. Periksa internet lalu coba lagi.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
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
  Widget build(BuildContext context) => Card(
    color: const Color(0xff28113f),
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: const Color(0xff9147df),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xff28113f),
    child: ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Text(
          answer,
          style: const TextStyle(color: Colors.white60, height: 1.4),
        ),
      ],
    ),
  );
}
