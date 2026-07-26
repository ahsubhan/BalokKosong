import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_service.dart';
import 'notification_service.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  static const _tokenProductId = 'balokkosong_tokens_30';
  static const _androidRewardedTestId =
      'ca-app-pub-3940256099942544/5224354917';
  static const _iosRewardedTestId = 'ca-app-pub-3940256099942544/1712485313';
  static const _androidRewardedProductionId = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
    defaultValue: 'ca-app-pub-5653870627581625/8185974718',
  );
  static const _iosRewardedProductionId = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
    defaultValue: 'ca-app-pub-5653870627581625/4605968146',
  );

  final couponController = TextEditingController();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? _tokenProduct;
  RewardedAd? _rewardedAd;
  int tokens = 0;
  int energy = 5;
  bool unlimited = false;
  bool themePack = false;
  bool noAds = false;
  bool loading = true;
  bool purchasePending = false;
  bool rewardedAdLoading = false;
  static const int _themePackTokenCost = 20;
  static const int _energyByTokenCost = 2;

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _rewardedAd?.dispose();
    couponController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) =>
          _showMessage('Pembelian belum dapat diproses. Silakan coba kembali.'),
    );
    _load();
    unawaited(_initializePurchases());
    unawaited(_initializeRewardedAds());
  }

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  String? get _rewardedAdUnitId {
    if (!_isMobile) return null;
    if (kDebugMode) {
      return Platform.isAndroid ? _androidRewardedTestId : _iosRewardedTestId;
    }
    final productionId = Platform.isAndroid
        ? _androidRewardedProductionId
        : _iosRewardedProductionId;
    return productionId.isEmpty ? null : productionId;
  }

  Future<void> _initializePurchases() async {
    if (!_isMobile) return;
    final available = await _inAppPurchase.isAvailable();
    if (!available) return;
    final response = await _inAppPurchase.queryProductDetails({
      _tokenProductId,
    });
    if (!mounted) return;
    setState(() {
      _tokenProduct = response.productDetails
          .where((product) => product.id == _tokenProductId)
          .firstOrNull;
    });
  }

  Future<void> _buyTokens() async {
    final product = _tokenProduct;
    if (product == null) {
      _showMessage(
        'Produk token belum tersedia. Pastikan produk $_tokenProductId '
        'sudah aktif di store.',
      );
      return;
    }
    setState(() => purchasePending = true);
    final started = await _inAppPurchase.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
      autoConsume: true,
    );
    if (!started && mounted) {
      setState(() => purchasePending = false);
      _showMessage('Jendela pembayaran belum dapat dibuka.');
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        if (mounted) setState(() => purchasePending = true);
        continue;
      }
      if (purchase.status == PurchaseStatus.error) {
        if (mounted) {
          setState(() => purchasePending = false);
          _showMessage(purchase.error?.message ?? 'Pembelian tidak berhasil.');
        }
      } else if ((purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored) &&
          purchase.productID == _tokenProductId) {
        await _deliverTokenPurchase(purchase);
      } else if (purchase.status == PurchaseStatus.canceled && mounted) {
        setState(() => purchasePending = false);
      }
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  Future<void> _deliverTokenPurchase(PurchaseDetails purchase) async {
    final prefs = await SharedPreferences.getInstance();
    final processed =
        prefs.getStringList('balok_processed_purchases') ?? <String>[];
    final transactionKey =
        purchase.purchaseID ?? purchase.verificationData.serverVerificationData;
    if (processed.contains(transactionKey)) {
      if (mounted) setState(() => purchasePending = false);
      return;
    }
    processed.add(transactionKey);
    if (processed.length > 200) {
      processed.removeRange(0, processed.length - 200);
    }
    await prefs.setStringList('balok_processed_purchases', processed);
    if (!mounted) return;
    setState(() {
      tokens += 30;
      purchasePending = false;
    });
    await _save(
      message: 'Pembelian berhasil. +30 token diterima.',
      purchaseTitle: 'Paket 30 Token',
    );
  }

  Future<void> _initializeRewardedAds() async {
    if (_rewardedAdUnitId == null) return;
    await MobileAds.instance.initialize();
    await _loadRewardedAd();
  }

  Future<void> _loadRewardedAd() async {
    final adUnitId = _rewardedAdUnitId;
    if (adUnitId == null || rewardedAdLoading || _rewardedAd != null) return;
    if (mounted) setState(() => rewardedAdLoading = true);
    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _rewardedAd = ad;
            rewardedAdLoading = false;
          });
        },
        onAdFailedToLoad: (_) {
          if (mounted) setState(() => rewardedAdLoading = false);
        },
      ),
    );
  }

  Future<void> _showRewardedAd({
    required VoidCallback applyReward,
    required String message,
  }) async {
    final adUnitId = _rewardedAdUnitId;
    if (adUnitId == null) {
      _showMessage(
        kReleaseMode
            ? 'Iklan belum aktif. ID AdMob produksi perlu dipasang.'
            : 'Iklan berhadiah hanya tersedia di Android atau iOS.',
      );
      return;
    }
    final ad = _rewardedAd;
    if (ad == null) {
      unawaited(_loadRewardedAd());
      _showMessage('Iklan sedang disiapkan. Silakan coba beberapa saat lagi.');
      return;
    }
    _rewardedAd = null;
    var rewardGranted = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (closedAd) {
        closedAd.dispose();
        unawaited(_loadRewardedAd());
      },
      onAdFailedToShowFullScreenContent: (failedAd, _) {
        failedAd.dispose();
        unawaited(_loadRewardedAd());
        _showMessage('Iklan belum dapat ditampilkan.');
      },
    );
    ad.show(
      onUserEarnedReward: (_, reward) {
        if (rewardGranted || !mounted) return;
        rewardGranted = true;
        setState(applyReward);
        unawaited(_save(message: message));
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _save({String? message, String? purchaseTitle}) async {
    final prefs = await SharedPreferences.getInstance();
    final purchaseHistory =
        prefs.getStringList('balok_purchase_history') ?? <String>[];
    if (purchaseTitle != null) {
      final now = DateTime.now();
      final date =
          '${now.day.toString().padLeft(2, '0')}/'
          '${now.month.toString().padLeft(2, '0')}/${now.year}';
      purchaseHistory.insert(0, '$purchaseTitle · $date');
      if (purchaseHistory.length > 50) {
        purchaseHistory.removeRange(50, purchaseHistory.length);
      }
    }
    await Future.wait([
      prefs.setInt('balok_tokens', tokens),
      prefs.setInt('balok_energy', energy),
      prefs.setBool('balok_unlimited', unlimited),
      prefs.setBool('balok_theme_pack', themePack),
      prefs.setBool('balok_no_ads', noAds),
      prefs.setStringList('balok_purchase_history', purchaseHistory),
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
      purchaseHistory: purchaseHistory,
    );
    await NotificationService.instance.refreshEnergyReminder();
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _spendTokens({
    required int amount,
    required String itemName,
    required String message,
    required VoidCallback apply,
  }) async {
    if (amount <= 0) {
      setState(apply);
      await _save(message: message);
      return;
    }
    if (tokens < amount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Token tidak cukup untuk $itemName (butuh $amount).'),
        ),
      );
      return;
    }
    setState(() {
      tokens -= amount;
      apply();
    });
    await _save(message: message);
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
                        const SizedBox(height: 16),
                        const _TokenMechanismCard(),
                        const SizedBox(height: 20),
                        _StoreAction(
                          icon: Icons.play_arrow_rounded,
                          title: '+3 Token Petunjuk',
                          subtitle: rewardedAdLoading
                              ? 'Menyiapkan iklan…'
                              : 'Tonton iklan berhadiah',
                          onTap: () => _showRewardedAd(
                            applyReward: () => tokens += 3,
                            message: 'Hadiah +3 token diterima',
                          ),
                        ),
                        _StoreAction(
                          icon: Icons.bolt_rounded,
                          title: '+2 Energy Tantangan',
                          subtitle: 'Dengan iklan berhadiah',
                          onTap: () {
                            if (energy >= 5) {
                              _showMessage('Energy sudah penuh.');
                              return;
                            }
                            _showRewardedAd(
                              applyReward: () =>
                                  energy = (energy + 2).clamp(0, 5),
                              message: 'Energy Tantangan bertambah',
                            );
                          },
                        ),
                        _StoreAction(
                          icon: Icons.electric_bolt_rounded,
                          title: '+1 Energy Tantangan',
                          subtitle: '2 token',
                          onTap: () {
                            if (energy >= 5) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Energy sudah penuh.'),
                                ),
                              );
                              return;
                            }
                            _spendTokens(
                              amount: _energyByTokenCost,
                              itemName: 'Energy Tantangan',
                              message:
                                  'Energy Tantangan bertambah 1 dengan token',
                              apply: () => energy = (energy + 1).clamp(0, 5),
                            );
                          },
                        ),
                        _StoreAction(
                          icon: Icons.diamond_rounded,
                          title: purchasePending
                              ? 'MEMPROSES PEMBELIAN…'
                              : 'BELI 30 TOKEN',
                          subtitle: _tokenProduct == null
                              ? 'Pembelian melalui App Store / Google Play'
                              : '${_tokenProduct!.price} · dapat dibeli kembali',
                          enabled: !purchasePending,
                          onTap: _buyTokens,
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
                            _save(
                              message: 'Energy tanpa batas diaktifkan',
                              purchaseTitle: 'Energy tanpa batas · 30 hari',
                            );
                          },
                        ),
                        _StoreAction(
                          icon: Icons.auto_awesome_rounded,
                          title: themePack
                              ? 'Tema eksklusif aktif'
                              : 'Paket Tema Neon & Ocean',
                          subtitle: themePack
                              ? 'Aktif'
                              : '$_themePackTokenCost token',
                          enabled: !themePack,
                          onTap: () => _spendTokens(
                            amount: _themePackTokenCost,
                            itemName: 'Paket Tema Neon & Ocean',
                            message: 'Tema Neon & Ocean terbuka',
                            apply: () => themePack = true,
                          ),
                        ),
                        _StoreAction(
                          icon: Icons.confirmation_number_rounded,
                          title: 'Masukkan Kupon',
                          subtitle: 'Bonus token atau buka tema premium',
                          onTap: _showCouponDialog,
                        ),
                        _StoreAction(
                          icon: Icons.block_rounded,
                          title: noAds ? 'Bebas iklan aktif' : 'Bebas Iklan',
                          subtitle: 'Hilangkan iklan sela · demo',
                          enabled: !noAds,
                          onTap: () {
                            setState(() => noAds = true);
                            _save(
                              message: 'Bebas iklan diaktifkan',
                              purchaseTitle: 'Bebas Iklan',
                            );
                          },
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'Pembayaran diproses oleh App Store atau Google Play. '
                          'Hadiah iklan diberikan hanya setelah iklan selesai.',
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
    final preferences = await SharedPreferences.getInstance();
    final redeemed =
        preferences.getStringList('balok_redeemed_coupons') ?? <String>[];
    if (!mounted) return;
    if (redeemed.contains(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kupon ini sudah pernah digunakan')),
      );
      return;
    }
    if (code == 'TOKEN10') {
      setState(() => tokens += 10);
      redeemed.add(code);
      await preferences.setStringList('balok_redeemed_coupons', redeemed);
      await _save(message: 'Kupon berhasil. Bonus +10 token!');
      return;
    }
    if (code != 'BALOKPREMIUM' && code != 'KOSONG2026') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kupon tidak valid atau sudah berakhir')),
      );
      return;
    }
    setState(() => themePack = true);
    redeemed.add(code);
    await preferences.setStringList('balok_redeemed_coupons', redeemed);
    await _save(message: 'Kupon berhasil. Tema Neon & Ocean terbuka!');
  }
}

class _TokenMechanismCard extends StatelessWidget {
  const _TokenMechanismCard();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xff32144f),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xff70419b)),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.diamond_outlined, color: Color(0xffffcf5a), size: 22),
            SizedBox(width: 8),
            Text(
              'CARA KERJA TOKEN',
              style: TextStyle(
                color: Color(0xffffe5a0),
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          'DIGUNAKAN UNTUK',
          style: TextStyle(
            color: Color(0xffd8a5ff),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 5),
        Text('• 10 petunjuk pertama gratis (total akun).'),
        Text('• Setelah itu, 1 token = 1 petunjuk.'),
        Text('• 1 token = buka grid untuk level 4 ke atas.'),
        Text('• 1 token = buka tema Neon & Ocean.'),
        Text('• 2 token = +1 Energy Tantangan (jika energy belum penuh).'),
        Text('• Grid / tema yang sudah dibuka bersifat permanen.'),
        SizedBox(height: 11),
        Text(
          'CARA MENDAPATKAN',
          style: TextStyle(
            color: Color(0xffd8a5ff),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 5),
        Text('• Tonton iklan berhadiah sampai selesai: +3 token.'),
        Text(
          '• Beli paket token sekali bayar melalui App Store atau Google Play. '
          'Paket dapat dibeli kembali.',
        ),
        Text('• Masukkan kupon bonus yang masih berlaku.'),
        SizedBox(height: 10),
        Text(
          'Token bukan langganan, tidak diperpanjang otomatis, dan tidak '
          'kedaluwarsa. Login diperlukan agar saldo tersinkron ke perangkat lain.',
          style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.35),
        ),
      ],
    ),
  );
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
