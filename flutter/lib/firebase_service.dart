import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'player_progress.dart';

class CouponRedemptionResult {
  const CouponRedemptionResult({
    required this.code,
    required this.tokens,
    required this.energy,
    required this.themePack,
    required this.customThemeUnlocked,
    required this.noAds,
    required this.tokenReward,
    required this.energyReward,
    required this.themePackReward,
    required this.customThemeReward,
    required this.noAdsReward,
  });

  final String code;
  final int tokens;
  final int energy;
  final bool themePack;
  final bool customThemeUnlocked;
  final bool noAds;
  final int tokenReward;
  final int energyReward;
  final bool themePackReward;
  final bool customThemeReward;
  final bool noAdsReward;

  String get message {
    final rewards = <String>[
      if (tokenReward > 0) '+$tokenReward token',
      if (energyReward > 0) '+$energyReward energy',
      if (themePackReward) 'tema Neon & Ocean',
      if (customThemeReward) 'tema Custom',
      if (noAdsReward) 'bebas iklan',
    ];
    return 'Kupon berhasil: ${rewards.join(', ')}.';
  }
}

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  bool _ready = false;
  Future<void>? _initializing;
  bool get isReady => _ready;
  User? get user => _ready ? FirebaseAuth.instance.currentUser : null;

  Future<void> initialize() {
    if (_ready) return Future.value();
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Firebase.initializeApp();
      _ready = true;
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _saveUser(currentUser);
        await syncRemoteToLocal();
      }
    } catch (_) {
      _ready = false;
    } finally {
      _initializing = null;
    }
  }

  Future<User> signInAsGuest() async {
    await initialize();
    _requireReady();
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      await _saveUser(current);
      return current;
    }
    final result = await FirebaseAuth.instance.signInAnonymously();
    await _saveUser(result.user!);
    return result.user!;
  }

  Future<UserCredential> signInWithGoogle() async {
    await initialize();
    _requireReady();
    await GoogleSignIn.instance.initialize();
    final account = await GoogleSignIn.instance.authenticate();
    final authentication = account.authentication;
    final result = await FirebaseAuth.instance.signInWithCredential(
      GoogleAuthProvider.credential(idToken: authentication.idToken),
    );
    if (result.user != null) {
      await _saveUser(result.user!);
      await syncRemoteToLocal();
    }
    return result;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await initialize();
    _requireReady();
    final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await result.user?.reload();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || !currentUser.emailVerified) {
      await FirebaseAuth.instance.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Alamat email belum diverifikasi.',
      );
    }
    await _saveUser(currentUser);
    await syncRemoteToLocal();
    return result;
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    await initialize();
    _requireReady();
    final auth = FirebaseAuth.instance;
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    UserCredential result;
    final currentUser = auth.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      result = await currentUser.linkWithCredential(credential);
    } else {
      if (currentUser != null) await auth.signOut();
      result = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    }
    final registeredUser = result.user;
    if (registeredUser == null) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Akun belum berhasil dibuat.',
      );
    }
    try {
      await registeredUser.updateDisplayName(name.trim());
      await registeredUser.sendEmailVerification();
      await registeredUser.reload();
      await _saveUser(FirebaseAuth.instance.currentUser ?? registeredUser);
    } finally {
      await auth.signOut();
    }
  }

  Future<void> signOut() async {
    await initialize();
    _requireReady();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // The user may have signed in with another provider.
    }
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _saveUser(User user) async {
    if (!_ready) return;
    final provider = user.isAnonymous
        ? 'guest'
        : user.providerData.isEmpty
        ? 'unknown'
        : user.providerData.first.providerId;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final existing = await ref.get();
    await ref.set({
      'uid': user.uid,
      'displayName': user.displayName,
      'email': user.email,
      'photoUrl': user.photoURL,
      'provider': provider,
      'isAnonymous': user.isAnonymous,
      'platform': Platform.operatingSystem,
      'lastLoginAt': FieldValue.serverTimestamp(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveProgress({
    required int level,
    required int score,
    int? bestTimeSeconds,
    int? moves,
    int? mistakes,
    int? hintsUsed,
    int? stars,
    bool? challengeMode,
  }) async {
    final currentUser = user;
    if (!_ready || currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final levelKey = playerProgressKey('balok_level', currentUser.uid);
    final scoreKey = playerProgressKey('balok_score', currentUser.uid);
    final savedLevel = prefs.getInt(levelKey) ?? 1;
    final unlockedLevel = level > savedLevel ? level : savedLevel;
    await Future.wait([
      prefs.setInt(levelKey, unlockedLevel),
      prefs.setInt(scoreKey, score),
      prefs.setInt('balok_level', unlockedLevel),
      prefs.setInt('balok_score', score),
    ]);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set({
          'game': {
            'level': unlockedLevel,
            'score': score,
            'bestTimeSeconds': ?bestTimeSeconds,
            'moves': ?moves,
            'mistakes': ?mistakes,
            'hintsUsed': ?hintsUsed,
            'stars': ?stars,
            'challengeMode': ?challengeMode,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
  }

  Future<void> saveSettings({
    bool? gridVisible,
    bool? musicEnabled,
    String? themeName,
    bool? promoNotifications,
    bool? inactivityNotifications,
    bool? energyFullNotifications,
  }) async {
    final currentUser = user;
    if (!_ready || currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set({
          'settings': {
            'gridVisible': ?gridVisible,
            'musicEnabled': ?musicEnabled,
            'themeName': ?themeName,
            'promoNotifications': ?promoNotifications,
            'inactivityNotifications': ?inactivityNotifications,
            'energyFullNotifications': ?energyFullNotifications,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
  }

  Future<void> saveInventory({
    required int tokens,
    required int energy,
    required bool unlimited,
    required bool themePack,
    required bool noAds,
    List<int>? gridUnlockedLevels,
    int? freeHintsUsed,
    List<String>? purchaseHistory,
    bool? customThemeUnlocked,
  }) async {
    final currentUser = user;
    if (!_ready || currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set({
          'inventory': {
            'tokens': tokens,
            'energy': energy,
            'unlimited': unlimited,
            'themePack': themePack,
            'noAds': noAds,
            'gridUnlockedLevels': ?gridUnlockedLevels,
            'freeHintsUsed': ?freeHintsUsed,
            'purchaseHistory': ?purchaseHistory,
            'customThemeUnlocked': ?customThemeUnlocked,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
  }

  Future<void> submitFeedback({
    required String name,
    required String message,
  }) async {
    await initialize();
    _requireReady();
    final currentUser = user;
    if (currentUser == null || currentUser.isAnonymous) {
      throw StateError(
        'Masuk dengan Email atau Google untuk mengirim feedback.',
      );
    }
    final package = await PackageInfo.fromPlatform();
    await FirebaseFirestore.instance.collection('feedback').add({
      'uid': currentUser.uid,
      'email': currentUser.email,
      'displayName': currentUser.displayName,
      'senderName': name,
      'provider': 'account',
      'message': message,
      'platform': Platform.operatingSystem,
      'appVersion': package.version,
      'buildNumber': package.buildNumber,
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<CouponRedemptionResult> redeemCoupon(String rawCode) async {
    await initialize();
    _requireReady();
    final currentUser = user;
    if (currentUser == null || currentUser.isAnonymous) {
      throw StateError(
        'Masuk dengan Email atau Google untuk menggunakan kupon.',
      );
    }

    final code = rawCode.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^[A-Z0-9-]{4,24}$').hasMatch(code)) {
      throw StateError('Format kode kupon tidak valid.');
    }

    final firestore = FirebaseFirestore.instance;
    final couponRef = firestore.collection('coupons').doc(code);
    final redemptionRef = firestore
        .collection('coupon_redemptions')
        .doc('${currentUser.uid}_$code');
    final userRef = firestore.collection('users').doc(currentUser.uid);

    final result = await firestore.runTransaction<CouponRedemptionResult>((
      transaction,
    ) async {
      final couponSnapshot = await transaction.get(couponRef);
      final redemptionSnapshot = await transaction.get(redemptionRef);
      final userSnapshot = await transaction.get(userRef);
      if (!couponSnapshot.exists) {
        throw StateError('Kupon tidak ditemukan.');
      }
      if (redemptionSnapshot.exists) {
        throw StateError('Kupon ini sudah pernah digunakan.');
      }

      final coupon = couponSnapshot.data()!;
      final now = DateTime.now();
      final startsAt = coupon['startsAt'];
      final expiresAt = coupon['expiresAt'];
      final active = coupon['active'] == true;
      final redemptionCount = (coupon['redemptionCount'] as num?)?.toInt() ?? 0;
      final maxRedemptions = (coupon['maxRedemptions'] as num?)?.toInt() ?? 0;
      if (!active) throw StateError('Kupon sedang tidak aktif.');
      if (startsAt is Timestamp && now.isBefore(startsAt.toDate())) {
        throw StateError('Kupon belum mulai berlaku.');
      }
      if (expiresAt is! Timestamp || now.isAfter(expiresAt.toDate())) {
        throw StateError('Kupon sudah berakhir.');
      }
      if (maxRedemptions <= 0 || redemptionCount >= maxRedemptions) {
        throw StateError('Batas pemakaian kupon sudah habis.');
      }

      final rewards = Map<String, dynamic>.from(
        coupon['rewards'] as Map? ?? const {},
      );
      final tokenReward = (rewards['tokens'] as num?)?.toInt() ?? 0;
      final energyReward = (rewards['energy'] as num?)?.toInt() ?? 0;
      final themePackReward = rewards['themePack'] == true;
      final customThemeReward = rewards['customTheme'] == true;
      final noAdsReward = rewards['noAds'] == true;
      if (tokenReward <= 0 &&
          energyReward <= 0 &&
          !themePackReward &&
          !customThemeReward &&
          !noAdsReward) {
        throw StateError('Hadiah kupon belum dikonfigurasi.');
      }

      final userData = userSnapshot.data() ?? const <String, dynamic>{};
      final inventory = Map<String, dynamic>.from(
        userData['inventory'] as Map? ?? const {},
      );
      final tokens =
          ((inventory['tokens'] as num?)?.toInt() ?? 0) + tokenReward;
      final energy = math.min(
        5,
        ((inventory['energy'] as num?)?.toInt() ?? 5) + energyReward,
      );
      final themePack = inventory['themePack'] == true || themePackReward;
      final customTheme =
          inventory['customThemeUnlocked'] == true || customThemeReward;
      final noAds = inventory['noAds'] == true || noAdsReward;
      final purchaseHistory = List<String>.from(
        (inventory['purchaseHistory'] as List? ?? const []).whereType<String>(),
      );
      purchaseHistory.insert(0, 'Kupon $code');
      if (purchaseHistory.length > 50) {
        purchaseHistory.removeRange(50, purchaseHistory.length);
      }

      final nextInventory = <String, dynamic>{
        'tokens': tokens,
        'energy': energy,
        'unlimited': inventory['unlimited'] == true,
        'themePack': themePack,
        'customThemeUnlocked': customTheme,
        'noAds': noAds,
        'gridUnlockedLevels': List<int>.from(
          (inventory['gridUnlockedLevels'] as List? ?? const [])
              .whereType<num>()
              .map((value) => value.toInt()),
        ),
        'freeHintsUsed':
            (inventory['freeHintsUsed'] as num?)?.toInt().clamp(0, 10) ?? 0,
        'purchaseHistory': purchaseHistory,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      transaction.update(couponRef, {
        'redemptionCount': redemptionCount + 1,
        'lastRedeemedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(redemptionRef, {
        'uid': currentUser.uid,
        'code': code,
        'rewards': rewards,
        'redeemedAt': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
      });
      transaction.set(userRef, {
        'inventory': nextInventory,
      }, SetOptions(merge: true));

      return CouponRedemptionResult(
        code: code,
        tokens: tokens,
        energy: energy,
        themePack: themePack,
        customThemeUnlocked: customTheme,
        noAds: noAds,
        tokenReward: tokenReward,
        energyReward: energyReward,
        themePackReward: themePackReward,
        customThemeReward: customThemeReward,
        noAdsReward: noAdsReward,
      );
    });

    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setInt('balok_tokens', result.tokens),
      preferences.setInt('balok_energy', result.energy),
      preferences.setBool('balok_theme_pack', result.themePack),
      preferences.setBool(
        'balok_custom_theme_unlocked',
        result.customThemeUnlocked,
      ),
      preferences.setBool('balok_no_ads', result.noAds),
    ]);
    return result;
  }

  Future<void> submitAccountDeletionRequest() async {
    await initialize();
    _requireReady();
    final currentUser = user;
    if (currentUser == null) {
      throw StateError('Tidak ada akun yang sedang aktif.');
    }
    final package = await PackageInfo.fromPlatform();
    await FirebaseFirestore.instance.collection('feedback').add({
      'uid': currentUser.uid,
      'email': currentUser.email,
      'displayName': currentUser.displayName,
      'provider': currentUser.isAnonymous ? 'guest' : 'account',
      'message': 'Permintaan penghapusan akun dan data terkait.',
      'category': 'account_deletion',
      'platform': Platform.operatingSystem,
      'appVersion': package.version,
      'buildNumber': package.buildNumber,
      'status': 'pending_review',
      'reviewWithinHours': 24,
      'deleteAuthAccount': true,
      'deleteGameRecords': true,
      'deleteInventory': true,
      'deleteSettings': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> syncRemoteToLocal() async {
    final currentUser = user;
    if (!_ready || currentUser == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final data = snapshot.data();
    if (data == null) return;
    final prefs = await SharedPreferences.getInstance();
    final game = Map<String, dynamic>.from(data['game'] as Map? ?? {});
    final settings = Map<String, dynamic>.from(data['settings'] as Map? ?? {});
    final inventory = Map<String, dynamic>.from(
      data['inventory'] as Map? ?? {},
    );
    if (game['level'] is num) {
      final level = (game['level'] as num).toInt();
      await Future.wait([
        prefs.setInt(playerProgressKey('balok_level', currentUser.uid), level),
        prefs.setInt('balok_level', level),
        prefs.setBool(
          playerProgressKey('balok_has_started', currentUser.uid),
          true,
        ),
      ]);
    }
    if (game['score'] is num) {
      final score = (game['score'] as num).toInt();
      await Future.wait([
        prefs.setInt(playerProgressKey('balok_score', currentUser.uid), score),
        prefs.setInt('balok_score', score),
      ]);
    }
    if (settings['gridVisible'] is bool) {
      await prefs.setBool(
        'balok_grid_visible',
        settings['gridVisible'] as bool,
      );
    }
    if (settings['musicEnabled'] is bool) {
      await prefs.setBool(
        'balok_music_enabled',
        settings['musicEnabled'] as bool,
      );
    }
    if (settings['themeName'] is String) {
      await prefs.setString(
        'balok_theme_name',
        settings['themeName'] as String,
      );
    }
    if (settings['promoNotifications'] is bool) {
      await prefs.setBool(
        'balok_notify_promos',
        settings['promoNotifications'] as bool,
      );
    }
    if (settings['inactivityNotifications'] is bool) {
      await prefs.setBool(
        'balok_notify_inactivity',
        settings['inactivityNotifications'] as bool,
      );
    }
    if (settings['energyFullNotifications'] is bool) {
      await prefs.setBool(
        'balok_notify_energy_full',
        settings['energyFullNotifications'] as bool,
      );
    }
    if (inventory['tokens'] is num) {
      await prefs.setInt('balok_tokens', (inventory['tokens'] as num).toInt());
    }
    if (inventory['freeHintsUsed'] is num) {
      await prefs.setInt(
        'balok_free_hints_used',
        (inventory['freeHintsUsed'] as num).toInt(),
      );
    }
    if (inventory['energy'] is num) {
      await prefs.setInt('balok_energy', (inventory['energy'] as num).toInt());
    }
    if (inventory['unlimited'] is bool) {
      await prefs.setBool('balok_unlimited', inventory['unlimited'] as bool);
    }
    if (inventory['themePack'] is bool) {
      await prefs.setBool('balok_theme_pack', inventory['themePack'] as bool);
    }
    if (inventory['customThemeUnlocked'] is bool) {
      await prefs.setBool(
        'balok_custom_theme_unlocked',
        inventory['customThemeUnlocked'] as bool,
      );
    }
    if (inventory['noAds'] is bool) {
      await prefs.setBool('balok_no_ads', inventory['noAds'] as bool);
    }
    if (inventory['gridUnlockedLevels'] is List) {
      await prefs.setStringList(
        'balok_grid_unlocked_levels',
        (inventory['gridUnlockedLevels'] as List)
            .whereType<num>()
            .map((level) => '${level.toInt()}')
            .toList(),
      );
    }
    if (inventory['purchaseHistory'] is List) {
      await prefs.setStringList(
        'balok_purchase_history',
        (inventory['purchaseHistory'] as List).whereType<String>().toList(),
      );
    }
  }

  void _requireReady() {
    if (!_ready) {
      throw StateError(
        'Firebase belum tersambung. Periksa konfigurasi aplikasi dan internet.',
      );
    }
  }
}
