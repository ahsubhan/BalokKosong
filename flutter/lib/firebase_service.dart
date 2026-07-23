import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<UserCredential> signInWithApple() async {
    await initialize();
    _requireReady();
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    final result = await FirebaseAuth.instance.signInWithProvider(provider);
    if (result.user != null) {
      await _saveUser(result.user!);
      await syncRemoteToLocal();
    }
    return result;
  }

  Future<UserCredential> signInWithFacebook() async {
    await initialize();
    _requireReady();
    final login = await FacebookAuth.instance.login();
    if (login.status != LoginStatus.success || login.accessToken == null) {
      throw FirebaseAuthException(
        code: 'facebook-cancelled',
        message: login.message ?? 'Masuk dengan Facebook dibatalkan.',
      );
    }
    final result = await FirebaseAuth.instance.signInWithCredential(
      FacebookAuthProvider.credential(login.accessToken!.tokenString),
    );
    if (result.user != null) {
      await _saveUser(result.user!);
      await syncRemoteToLocal();
    }
    return result;
  }

  Future<void> signOut() async {
    await initialize();
    _requireReady();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // The user may have signed in with another provider.
    }
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {
      // The Facebook SDK may not be initialized for this session.
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
    await Future.wait([
      prefs.setInt('balok_level', level),
      prefs.setInt('balok_score', score),
    ]);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set({
          'game': {
            'level': level,
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
            'updatedAt': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
  }

  Future<void> submitFeedback(String message) async {
    await initialize();
    _requireReady();
    var currentUser = user;
    currentUser ??= await signInAsGuest();
    final package = await PackageInfo.fromPlatform();
    await FirebaseFirestore.instance.collection('feedback').add({
      'uid': currentUser.uid,
      'email': currentUser.email,
      'displayName': currentUser.displayName,
      'provider': currentUser.isAnonymous ? 'guest' : 'account',
      'message': message,
      'platform': Platform.operatingSystem,
      'appVersion': package.version,
      'buildNumber': package.buildNumber,
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
    });
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
      await prefs.setInt('balok_level', (game['level'] as num).toInt());
    }
    if (game['score'] is num) {
      await prefs.setInt('balok_score', (game['score'] as num).toInt());
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
    if (inventory['tokens'] is num) {
      await prefs.setInt('balok_tokens', (inventory['tokens'] as num).toInt());
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
  }

  void _requireReady() {
    if (!_ready) {
      throw StateError(
        'Firebase belum tersambung. Periksa konfigurasi aplikasi dan internet.',
      );
    }
  }
}
