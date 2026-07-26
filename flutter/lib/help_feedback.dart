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
  final nameController = TextEditingController();
  final controller = TextEditingController();
  bool sending = false;

  bool get _canSendFeedback {
    final user = FirebaseService.instance.user;
    return user != null && !user.isAnonymous;
  }

  @override
  void dispose() {
    nameController.dispose();
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
            question: 'Bagaimana cara kerja dan membeli Token?',
            answer:
                'Token adalah saldo virtual untuk memakai petunjuk setelah 10 kali gratis, membuka grid Level 4 ke atas, membuka tema premium, dan menambah Energy Tantangan. Token bisa diperoleh dari iklan berhadiah (+3), kupon, atau membeli paket sekali bayar di Toko & Hadiah melalui App Store atau Google Play. Token bukan langganan, tidak kedaluwarsa, dan dapat disinkronkan ke perangkat lain setelah login.',
          ),
          const _FaqTile(
            question: 'Apa perbedaan Santai dan Tantangan?',
            answer:
                'Santai tidak memiliki batas waktu. Tantangan memakai countdown dan energy per percobaan.',
          ),
          const _FaqTile(
            question: 'Berapa batas kesalahan menabrak balok?',
            answer:
                'Maksimal 10 kesalahan atau benturan diperbolehkan dalam satu level. Jika terjadi kesalahan ke-11, level dianggap gagal dan akan dimulai kembali dari awal.',
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
          if (!_canSendFeedback) ...[
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xff32154d),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xff70419b)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: Color(0xffd8a5ff)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Masuk dengan Email atau Google untuk mengirim feedback.',
                      style: TextStyle(color: Colors.white70, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: nameController,
            enabled: _canSendFeedback,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: InputDecoration(
              hintText: 'Nama (wajib diisi)',
              filled: true,
              fillColor: Colors.white.withValues(alpha: .05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.white12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            enabled: _canSendFeedback,
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
              onPressed: sending || !_canSendFeedback ? null : _submit,
              icon: sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                sending
                    ? 'Mengirim…'
                    : _canSendFeedback
                    ? 'Kirim feedback'
                    : 'Login diperlukan',
              ),
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
    if (!_canSendFeedback) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Masuk dengan Email atau Google untuk mengirim feedback.',
          ),
        ),
      );
      return;
    }
    final name = nameController.text.trim();
    final feedback = controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama wajib diisi.')));
      return;
    }
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tuliskan feedback terlebih dahulu.')),
      );
      return;
    }
    setState(() => sending = true);
    try {
      await FirebaseService.instance.submitFeedback(
        name: name,
        message: feedback,
      );
      if (!mounted) return;
      nameController.clear();
      controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terima kasih. Feedback sudah terkirim.')),
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
