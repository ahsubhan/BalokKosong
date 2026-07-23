import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_service.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final couponController = TextEditingController();
  int tokens = 0;
  int energy = 5;
  bool unlimited = false;
  bool themePack = false;
  bool noAds = false;
  bool loading = true;

  @override
  void dispose() {
    couponController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      tokens = prefs.getInt('balok_tokens') ?? 0;
      energy = prefs.getInt('balok_energy') ?? 5;
      unlimited = prefs.getBool('balok_unlimited') ?? false;
      themePack = prefs.getBool('balok_theme_pack') ?? false;
      noAds = prefs.getBool('balok_no_ads') ?? false;
      loading = false;
    });
  }

  Future<void> _save({String? message}) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt('balok_tokens', tokens),
      prefs.setInt('balok_energy', energy),
      prefs.setBool('balok_unlimited', unlimited),
      prefs.setBool('balok_theme_pack', themePack),
      prefs.setBool('balok_no_ads', noAds),
    ]);
    await FirebaseService.instance.saveInventory(
      tokens: tokens,
      energy: energy,
      unlimited: unlimited,
      themePack: themePack,
      noAds: noAds,
      gridUnlockedLevels:
          (prefs.getStringList('balok_grid_unlocked_levels') ?? const [])
              .map(int.tryParse)
              .whereType<int>()
              .toList(),
    );
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff130522),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
              decoration: BoxDecoration(
                color: const Color(0xff210b39),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xff70419b)),
              ),
              child: loading
                  ? const SizedBox(
                      height: 420,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      children: [
                        Text(
                          'TOKO & HADIAH',
                          style: GoogleFonts.fredoka(
                            color: const Color(0xffd8a5ff),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '◆ $tokens token · ⚡ $energy/5',
                          style: GoogleFonts.fredoka(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Mode Santai selalu gratis. Iklan hanya muncul jika Anda memilih hadiah.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _StoreAction(
                          icon: Icons.play_arrow_rounded,
                          title: '+3 Token Petunjuk',
                          subtitle: 'Tonton iklan berhadiah',
                          onTap: () {
                            setState(() => tokens += 3);
                            _save(message: 'Hadiah +3 token diterima');
                          },
                        ),
                        _StoreAction(
                          icon: Icons.bolt_rounded,
                          title: '+2 Energy Tantangan',
                          subtitle: 'Dengan iklan berhadiah',
                          onTap: () {
                            setState(() => energy = (energy + 2).clamp(0, 5));
                            _save(message: 'Energy Tantangan bertambah');
                          },
                        ),
                        _StoreAction(
                          icon: Icons.diamond_rounded,
                          title: '+30 Token',
                          subtitle: 'Pembelian sekali · demo',
                          onTap: () {
                            setState(() => tokens += 30);
                            _save(message: '+30 token ditambahkan');
                          },
                        ),
                        _StoreAction(
                          icon: Icons.all_inclusive_rounded,
                          title: unlimited
                              ? 'Energy tanpa batas aktif'
                              : 'Energy tanpa batas · 30 hari',
                          subtitle: 'Pembelian demo',
                          enabled: !unlimited,
                          onTap: () {
                            setState(() => unlimited = true);
                            _save(message: 'Energy tanpa batas diaktifkan');
                          },
                        ),
                        _StoreAction(
                          icon: Icons.auto_awesome_rounded,
                          title: themePack
                              ? 'Tema eksklusif aktif'
                              : 'Paket Tema Neon & Ocean',
                          subtitle: 'Pembelian sekali · demo',
                          enabled: !themePack,
                          onTap: () {
                            setState(() => themePack = true);
                            _save(message: 'Tema Neon & Ocean terbuka');
                          },
                        ),
                        _StoreAction(
                          icon: Icons.confirmation_number_rounded,
                          title: themePack
                              ? 'Kupon tema sudah aktif'
                              : 'Masukkan Kupon',
                          subtitle: 'Buka Neon & Ocean dengan kode kupon',
                          enabled: !themePack,
                          onTap: _showCouponDialog,
                        ),
                        _StoreAction(
                          icon: Icons.block_rounded,
                          title: noAds ? 'Bebas iklan aktif' : 'Bebas Iklan',
                          subtitle: 'Hilangkan iklan sela · demo',
                          enabled: !noAds,
                          onTap: () {
                            setState(() => noAds = true);
                            _save(message: 'Bebas iklan diaktifkan');
                          },
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'Iklan dan pembayaran masih simulasi development. '
                          'Tombol yang sama akan dihubungkan ke AdMob dan pembelian resmi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xff9147df),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'Tutup',
                              style: TextStyle(fontWeight: FontWeight.w900),
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

  Future<void> _showCouponDialog() async {
    couponController.clear();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff24103c),
        icon: const Icon(
          Icons.confirmation_number_rounded,
          color: Color(0xffffcf5a),
          size: 44,
        ),
        title: const Text(
          'Masukkan Kupon',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: TextField(
          controller: couponController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'KODE KUPON',
            filled: true,
            fillColor: Colors.white.withValues(alpha: .06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onSubmitted: (_) => Navigator.pop(dialogContext, true),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('GUNAKAN'),
          ),
        ],
      ),
    );
    if (submitted != true || !mounted) return;
    final code = couponController.text.trim().toUpperCase();
    if (code != 'BALOKPREMIUM' && code != 'KOSONG2026') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kupon tidak valid atau sudah berakhir')),
      );
      return;
    }
    setState(() => themePack = true);
    await _save(message: 'Kupon berhasil. Tema Neon & Ocean terbuka!');
  }
}

class _StoreAction extends StatelessWidget {
  const _StoreAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Material(
      color: Colors.white.withValues(alpha: enabled ? .055 : .025),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.white12),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: enabled ? const Color(0xff4f2879) : Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
