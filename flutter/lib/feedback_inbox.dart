import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'developer_access.dart';
import 'firebase_service.dart';

class FeedbackItem {
  const FeedbackItem({
    required this.id,
    required this.senderName,
    required this.email,
    required this.message,
    required this.platform,
    required this.appVersion,
    required this.buildNumber,
    required this.status,
    required this.category,
    this.createdAt,
  });

  factory FeedbackItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAt = data['createdAt'];
    return FeedbackItem(
      id: document.id,
      senderName: _firstText([
        data['senderName'],
        data['displayName'],
        'Tanpa nama',
      ]),
      email: _firstText([data['email'], 'Email tidak tersedia']),
      message: _firstText([data['message'], 'Tidak ada isi pesan']),
      platform: _firstText([data['platform'], 'perangkat tidak diketahui']),
      appVersion: _firstText([data['appVersion'], '-']),
      buildNumber: _firstText([data['buildNumber'], '-']),
      status: _firstText([data['status'], 'new']),
      category: _firstText([data['category'], 'feedback']),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  final String id;
  final String senderName;
  final String email;
  final String message;
  final String platform;
  final String appVersion;
  final String buildNumber;
  final String status;
  final String category;
  final DateTime? createdAt;

  bool get isDeletionRequest => category == 'account_deletion';
}

String _firstText(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text != 'null') return text;
  }
  return '';
}

class FeedbackInboxScreen extends StatefulWidget {
  const FeedbackInboxScreen({super.key});

  @override
  State<FeedbackInboxScreen> createState() => _FeedbackInboxScreenState();
}

class _FeedbackInboxScreenState extends State<FeedbackInboxScreen> {
  String filter = 'all';

  bool get _isDeveloper {
    final user = FirebaseService.instance.user;
    return isDeveloperGoogleAccount(
      email: user?.email,
      providerIds:
          user?.providerData.map((provider) => provider.providerId) ??
          const <String>[],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff12021f),
    appBar: AppBar(
      backgroundColor: const Color(0xff1b082f),
      foregroundColor: Colors.white,
      centerTitle: true,
      title: Text(
        'KOTAK MASUK FEEDBACK',
        style: GoogleFonts.fredoka(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: .8,
        ),
      ),
    ),
    body: !_isDeveloper
        ? const _NoAccess()
        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('feedback')
                .orderBy('createdAt', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _MessageState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Feedback belum dapat dimuat',
                  message: snapshot.error.toString(),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xffa84cf5)),
                );
              }

              final all = snapshot.data!.docs
                  .map(FeedbackItem.fromDocument)
                  .toList();
              final visible = all.where((item) {
                if (filter == 'new') {
                  return item.status == 'new' ||
                      item.status == 'pending_review';
                }
                if (filter == 'resolved') return item.status == 'resolved';
                return true;
              }).toList();

              return Column(
                children: [
                  _InboxSummary(items: all),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Semua',
                          selected: filter == 'all',
                          onTap: () => setState(() => filter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Belum selesai',
                          selected: filter == 'new',
                          onTap: () => setState(() => filter = 'new'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Selesai',
                          selected: filter == 'resolved',
                          onTap: () => setState(() => filter = 'resolved'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: visible.isEmpty
                        ? const _MessageState(
                            icon: Icons.mark_email_read_outlined,
                            title: 'Tidak ada feedback',
                            message: 'Semua sudah tertangani.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                            itemCount: visible.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) => FeedbackInboxCard(
                              item: visible[index],
                              onStatusChanged: (status) =>
                                  _updateStatus(visible[index], status),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
  );

  Future<void> _updateStatus(FeedbackItem item, String status) async {
    try {
      final user = FirebaseService.instance.user;
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(item.id)
          .update({
            'status': status,
            'reviewedAt': FieldValue.serverTimestamp(),
            'reviewedBy': user!.uid,
          });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status belum tersimpan: $error')));
    }
  }
}

class FeedbackInboxCard extends StatelessWidget {
  const FeedbackInboxCard({
    super.key,
    required this.item,
    required this.onStatusChanged,
  });

  final FeedbackItem item;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final status = _statusPresentation(item.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff25103c),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xff5f377c)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.isDeletionRequest
                      ? 'PENGHAPUSAN AKUN'
                      : 'FEEDBACK PEMAIN',
                  style: GoogleFonts.fredoka(
                    color: const Color(0xffd5a7ff),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              _StatusBadge(label: status.$1, color: status.$2),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.senderName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.email,
            style: const TextStyle(color: Color(0xffcdbbd8), fontSize: 12),
          ),
          const SizedBox(height: 14),
          SelectableText(
            item.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 5,
            children: [
              _Metadata(
                icon: Icons.schedule_rounded,
                text: _formatDate(item.createdAt),
              ),
              _Metadata(icon: Icons.phone_iphone_rounded, text: item.platform),
              _Metadata(
                icon: Icons.info_outline_rounded,
                text: 'v${item.appVersion} (${item.buildNumber})',
              ),
            ],
          ),
          if (item.status != 'resolved') ...[
            const SizedBox(height: 15),
            Row(
              children: [
                if (item.status == 'new' ||
                    item.status == 'pending_review') ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onStatusChanged('read'),
                      child: const Text('Sudah dibaca'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => onStatusChanged('resolved'),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Selesai'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff9147df),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InboxSummary extends StatelessWidget {
  const _InboxSummary({required this.items});

  final List<FeedbackItem> items;

  @override
  Widget build(BuildContext context) {
    final pending = items.where((item) => item.status != 'resolved').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.inbox_rounded, color: Color(0xffc77dff), size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$pending belum selesai',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${items.length} feedback tersimpan',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff7d3ec1) : const Color(0xff25103c),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: .6)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: const Color(0xffcba7df)),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ],
  );
}

class _NoAccess extends StatelessWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context) => const _MessageState(
    icon: Icons.lock_outline_rounded,
    title: 'Khusus developer',
    message: 'Masuk dengan akun Google developer untuk membuka halaman ini.',
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xffbd7af3), size: 48),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, height: 1.4),
          ),
        ],
      ),
    ),
  );
}

(String, Color) _statusPresentation(String status) => switch (status) {
  'pending_review' => ('Perlu ditinjau', const Color(0xffffc857)),
  'read' => ('Sudah dibaca', const Color(0xff75c9ff)),
  'resolved' => ('Selesai', const Color(0xff69db9d)),
  _ => ('Baru', const Color(0xffff8db9)),
};

String _formatDate(DateTime? value) {
  if (value == null) return 'Waktu belum tersedia';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
