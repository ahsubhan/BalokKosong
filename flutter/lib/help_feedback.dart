import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_service.dart';

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key, this.onLoginRequired});

  final Future<void> Function()? onLoginRequired;

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> {
  final controller = TextEditingController();
  bool sending = false;
  FeedbackAttachment? attachment;

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
                'Tamu mendapat 3 token awal satu kali. Akun Email atau Google mendapat bonus 10 token satu kali. Semua pemain juga mendapat 10 petunjuk gratis, 5 energy awal, grid Level 1–3, dan tema dasar. Token dipakai untuk petunjuk tambahan, grid Level 4 ke atas, tema premium, dan Energy Tantangan. Token juga bisa diperoleh dari iklan berhadiah (+3), kupon, atau membeli paket sekali bayar. Token bukan langganan dan tidak kedaluwarsa.',
          ),
          const _FaqTile(
            question: 'Apa perbedaan Santai dan Tantangan?',
            answer:
                'Santai tidak memiliki batas waktu. Tantangan memakai countdown dan energy per percobaan.',
          ),
          const _FaqTile(
            question: 'Berapa batas kesalahan menabrak balok?',
            answer:
                'Setiap level memiliki 5 kesempatan salah atau menabrak balok. '
                'Kesempatan kembali menjadi 5/5 setelah naik level atau mengulang '
                'level. Benturan ke-6 membuat level gagal dan dimulai kembali '
                'dari awal.',
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
          const SizedBox(height: 10),
          if (attachment == null)
            OutlinedButton.icon(
              key: const Key('addFeedbackAttachment'),
              onPressed: sending ? null : _chooseAttachment,
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text('Tambah file atau gambar'),
            )
          else
            _AttachmentCard(
              attachment: attachment!,
              onRemove: sending
                  ? null
                  : () => setState(() => attachment = null),
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
      await FirebaseService.instance.submitFeedback(
        message: feedback,
        attachment: attachment,
      );
      if (!mounted) return;
      controller.clear();
      setState(() => attachment = null);
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

  Future<void> _chooseAttachment() async {
    final source = await showModalBottomSheet<_AttachmentSource>(
      context: context,
      backgroundColor: const Color(0xff28113f),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih gambar dari album'),
                onTap: () => Navigator.pop(context, _AttachmentSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_rounded),
                title: const Text('Pilih file'),
                onTap: () => Navigator.pop(context, _AttachmentSource.file),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      FeedbackAttachment? selected;
      if (source == _AttachmentSource.gallery) {
        final image = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 2048,
        );
        if (image != null) {
          selected = FeedbackAttachment(
            fileName: image.name,
            contentType: _contentTypeFor(image.name, fallback: 'image/jpeg'),
            bytes: await image.readAsBytes(),
          );
        }
      } else {
        final file = await openFile();
        if (file != null) {
          selected = FeedbackAttachment(
            fileName: file.name,
            contentType: _contentTypeFor(file.name),
            bytes: await file.readAsBytes(),
          );
        }
      }
      if (selected == null || !mounted) return;
      if (selected.bytes.length > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ukuran lampiran maksimal 10 MB.')),
        );
        return;
      }
      setState(() => attachment = selected);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lampiran belum dapat dipilih.')),
      );
    }
  }
}

enum _AttachmentSource { gallery, file }

String _contentTypeFor(
  String fileName, {
  String fallback = 'application/octet-stream',
}) {
  final extension = fileName.split('.').last.toLowerCase();
  return switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    'pdf' => 'application/pdf',
    'txt' || 'log' => 'text/plain',
    'zip' => 'application/zip',
    _ => fallback,
  };
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.attachment, required this.onRemove});

  final FeedbackAttachment attachment;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('feedbackAttachmentPreview'),
    padding: const EdgeInsets.fromLTRB(13, 9, 6, 9),
    decoration: BoxDecoration(
      color: const Color(0xff32154d),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xff70419b)),
    ),
    child: Row(
      children: [
        const Icon(Icons.attach_file_rounded, color: Color(0xffd8a5ff)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attachment.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                '${(attachment.bytes.length / 1024).ceil()} KB',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Hapus lampiran',
          onPressed: onRemove,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
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
