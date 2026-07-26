import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  int tokens = 0;
  bool loading = true;
  bool syncing = false;
  bool loggingOut = false;
  List<String> purchaseHistory = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await FirebaseService.instance.initialize();
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      user = FirebaseService.instance.user;
      tokens = preferences.getInt('balok_tokens') ?? 0;
      purchaseHistory =
          preferences.getStringList('balok_purchase_history') ?? const [];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff130522),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      title: const Text(
        'PROFIL',
        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    ),
    body: SafeArea(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              children: [
                _IdentityCard(user: user),
                const SizedBox(height: 14),
                _ProfileCard(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xff5b2d82),
                        child: Icon(
                          Icons.diamond_rounded,
                          color: Color(0xffffd369),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SALDO TOKEN',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              '$tokens token',
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: syncing ? null : _syncAccount,
                        child: const Text('Sinkronkan'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionTitle('RIWAYAT PEMBELIAN'),
                const SizedBox(height: 9),
                _ProfileCard(
                  child: purchaseHistory.isEmpty
                      ? const Row(
                          children: [
                            Icon(Icons.receipt_long_outlined),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Belum ada pembelian.',
                                style: TextStyle(color: Colors.white60),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            for (final purchase in purchaseHistory)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Color(0xffc084fc),
                                ),
                                title: Text(purchase),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 11),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: syncing ? null : _restorePurchases,
                    icon: syncing
                        ? const SizedBox.square(
                            dimension: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.restore_rounded),
                    label: const Text('PULIHKAN PEMBELIAN'),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Token dan progres dipulihkan melalui sinkronisasi akun. '
                  'Pulihkan Pembelian digunakan untuk item permanen dan '
                  'langganan dari App Store atau Google Play.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: TextButton.icon(
                    onPressed: loggingOut ? null : _logout,
                    icon: loggingOut
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout_rounded),
                    label: Text(loggingOut ? 'Keluar…' : 'Logout'),
                  ),
                ),
              ],
            ),
    ),
  );

  Future<void> _syncAccount() => _sync(
    'Data akun sudah disinkronkan. Saldo token dan progres diperbarui.',
  );

  Future<void> _restorePurchases() =>
      _sync('Saldo akun dan pembelian yang tersimpan berhasil dipulihkan.');

  Future<void> _sync(String message) async {
    if (syncing) return;
    setState(() => syncing = true);
    try {
      await FirebaseService.instance.syncRemoteToLocal();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sinkronisasi belum berhasil. Periksa internet.'),
        ),
      );
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff24103c),
        title: const Text('Logout dari akun?'),
        content: const Text(
          'Skor, progres, token, dan pembelian tetap tersimpan di akun.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => loggingOut = true);
    try {
      await FirebaseService.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      setState(() => loggingOut = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logout belum berhasil.')));
    }
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName?.trim();
    final shownName = name == null || name.isEmpty ? 'Pengguna' : name;
    final initial = shownName.characters.first.toUpperCase();
    final provider =
        user?.providerData.any(
              (provider) => provider.providerId == 'google.com',
            ) ==
            true
        ? 'Google'
        : 'Email';
    return _ProfileCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: const Color(0xff9147df),
            child: Text(
              initial,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shownName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ?? 'Email tidak tersedia',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  '$provider · ${user?.emailVerified == true ? 'Terverifikasi' : 'Belum terverifikasi'}',
                  style: const TextStyle(
                    color: Color(0xffd8a5ff),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xff28113f),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: Colors.white12),
    ),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xffd8a5ff),
      fontSize: 11,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
    ),
  );
}
