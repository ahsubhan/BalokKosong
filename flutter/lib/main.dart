import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_service.dart';
import 'developer_access.dart';
import 'email_auth_screen.dart';
import 'firebase_service.dart';
import 'how_to_play.dart';
import 'legal_screen.dart';
import 'mode_selection.dart';
import 'native_game.dart';
import 'notification_service.dart';
import 'player_progress.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await GameAudio.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint('Audio startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  try {
    await NotificationService.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint('Notification startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  runApp(const BalokKosongApp());
  unawaited(
    _initializeOnlineServices().catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      debugPrint('Online service startup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }),
  );
}

Future<void> _initializeOnlineServices() async {
  await FirebaseService.instance.initialize();
  await NotificationService.instance.activateAll();
  await FirebaseService.instance.saveSettings(
    promoNotifications: true,
    inactivityNotifications: true,
    energyFullNotifications: true,
  );
}

class BalokKosongApp extends StatelessWidget {
  const BalokKosongApp({
    super.key,
    this.showSplash = true,
    this.startupInitializer,
  });

  final bool showSplash;
  final Future<void> Function()? startupInitializer;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'BALOK KOSONG',
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.fredoka().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xffa855f7),
        brightness: Brightness.dark,
      ),
    ),
    builder: (context, child) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(
          textScaler: _AdditiveTextScaler(media.textScaler, 1),
        ),
        child: child!,
      );
    },
    home: showSplash
        ? OpeningSplashScreen(initializeServices: startupInitializer)
        : const HomeScreen(),
  );
}

class OpeningSplashScreen extends StatefulWidget {
  const OpeningSplashScreen({super.key, this.initializeServices});

  final Future<void> Function()? initializeServices;

  @override
  State<OpeningSplashScreen> createState() => _OpeningSplashScreenState();
}

class _OpeningSplashScreenState extends State<OpeningSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _navigationTimer;
  bool _navigationStarted = false;

  @override
  void initState() {
    super.initState();
    unawaited(GameAudio.instance.playOpening(restart: true));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _navigationTimer = Timer(
      const Duration(milliseconds: 2600),
      () => unawaited(_openNext()),
    );
  }

  Future<void> _openNext() async {
    if (_navigationStarted) return;
    _navigationStarted = true;
    await (widget.initializeServices ?? FirebaseService.instance.initialize)();
    if (!mounted) return;
    final user = FirebaseService.instance.user;
    final returningAccount = user != null && !user.isAnonymous;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 480),
        pageBuilder: (routeContext, _, _) => returningAccount
            ? ReturningPlayerWelcomeScreen(
                playerName: returningPlayerName(
                  displayName: user.displayName,
                  email: user.email,
                ),
              )
            : HowToPlayScreen(
                finalLabel: 'Lanjut',
                onFinished: () => Navigator.of(routeContext).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                ),
              ),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff130421),
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.1),
          radius: .85,
          colors: [Color(0xff4e167d), Color(0xff1d0733), Color(0xff10021c)],
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            final entrance = CurvedAnimation(
              parent: _controller,
              curve: const Interval(0, .62, curve: Curves.elasticOut),
            ).value;
            final glow = .45 + .35 * math.sin(_controller.value * math.pi * 3);
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 245 + glow * 30,
                  height: 245 + glow * 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xffa855f7,
                        ).withValues(alpha: glow * .55),
                        blurRadius: 70,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: entrance,
                  child: Opacity(opacity: entrance.clamp(0, 1), child: child),
                ),
                for (final sparkle in const [
                  (Alignment(-1.25, -.9), 22.0, .12),
                  (Alignment(1.2, -.55), 16.0, .3),
                  (Alignment(-1.05, .85), 14.0, .48),
                  (Alignment(1.05, .95), 20.0, .62),
                ])
                  Align(
                    alignment: sparkle.$1,
                    widthFactor: 5.2,
                    heightFactor: 5.2,
                    child: Opacity(
                      opacity: ((_controller.value - sparkle.$3) * 3).clamp(
                        0,
                        1,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: sparkle.$2,
                      ),
                    ),
                  ),
              ],
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: Image.asset(
              'assets/icon/app_icon.webp',
              width: 220,
              height: 220,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    ),
  );
}

String returningPlayerName({String? displayName, String? email}) {
  final name = displayName?.trim();
  if (name != null && name.isNotEmpty) return name;
  final address = email?.trim();
  if (address != null && address.contains('@')) {
    return address.substring(0, address.indexOf('@'));
  }
  return 'Pemain';
}

class ReturningPlayerWelcomeScreen extends StatefulWidget {
  const ReturningPlayerWelcomeScreen({
    super.key,
    required this.playerName,
    this.onFinished,
  });

  final String playerName;
  final VoidCallback? onFinished;

  @override
  State<ReturningPlayerWelcomeScreen> createState() =>
      _ReturningPlayerWelcomeScreenState();
}

class _ReturningPlayerWelcomeScreenState
    extends State<ReturningPlayerWelcomeScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_continueToGame());
  }

  Future<void> _continueToGame() async {
    await Future.wait([
      Future<void>.delayed(const Duration(seconds: 4)),
      FirebaseService.instance.waitForSessionRestore(),
    ]);
    if (!mounted) return;
    unawaited(GameAudio.instance.stopOpening());
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      onFinished();
      return;
    }
    await HomeScreen._enterGame(
      context,
      replaceCurrent: true,
      forceProgressChoices: true,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff130421),
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.12),
          radius: .9,
          colors: [Color(0xff512080), Color(0xff22083a), Color(0xff10021c)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Logo(),
              const SizedBox(height: 30),
              Text(
                'Welcome, ${widget.playerName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Menyiapkan progres permainan Anda…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xffd9b8ff),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xffb35cff),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AdditiveTextScaler extends TextScaler {
  const _AdditiveTextScaler(this.base, this.points);

  final TextScaler base;
  final double points;

  @override
  double scale(double fontSize) => base.scale(fontSize) + points;

  @override
  double get textScaleFactor => scale(16) / 16;

  @override
  bool operator ==(Object other) =>
      other is _AdditiveTextScaler &&
      other.base == base &&
      other.points == points;

  @override
  int get hashCode => Object.hash(base, points);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.showBackButton = false,
    this.accountSignedIn,
  });

  final bool showBackButton;
  final bool? accountSignedIn;

  @override
  Widget build(BuildContext context) {
    unawaited(GameAudio.instance.playOpening());
    final signedIn =
        accountSignedIn ?? FirebaseService.instance.user?.isAnonymous == false;
    final canReturnToPrevious =
        showBackButton || Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: const Color(0xff170627),
      extendBodyBehindAppBar: true,
      appBar: canReturnToPrevious
          ? AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 68,
              leadingWidth: 76,
              leading: Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Center(
                  child: IconButton.filled(
                    tooltip: 'Kembali',
                    onPressed: () {
                      unawaited(GameAudio.instance.playGameplay());
                      Navigator.pop(context);
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xff6f35a8),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(46, 46),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 25),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButton: FloatingActionButton.small(
        key: const Key('homeHowToPlayButton'),
        tooltip: 'Cara bermain',
        onPressed: () => _openHowToPlay(context),
        backgroundColor: const Color(0xff7436ad),
        foregroundColor: Colors.white,
        shape: const CircleBorder(
          side: BorderSide(color: Color(0xffc67cff), width: 1.5),
        ),
        child: const Text(
          '?',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 24, 30, 26),
              child: Column(
                children: [
                  const Spacer(),
                  const _Logo(),
                  const SizedBox(height: 13),
                  const Text(
                    'HABISKAN SEMUA BALOK',
                    style: TextStyle(
                      color: Color(0xffd9b8ff),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.35,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(flex: 2),
                  _AuthButton(
                    key: const Key('emailSignInButton'),
                    label: 'MASUK DENGAN EMAIL',
                    symbol: Icons.email_outlined,
                    tone: const Color(0xff7340be),
                    onTap: signedIn
                        ? null
                        : () => unawaited(_openEmailLogin(context)),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Belum mendaftar? ',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      if (signedIn)
                        const Text(
                          'Mendaftar',
                          style: TextStyle(
                            color: Colors.white30,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      else
                        _PolicyLink(
                          label: 'Mendaftar',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EmailRegistrationScreen(),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  _AuthButton(
                    label: 'MASUK DENGAN GOOGLE',
                    symbol: Icons.g_mobiledata_rounded,
                    tone: const Color(0xfff8f3ff),
                    darkLabel: true,
                    onTap: signedIn
                        ? null
                        : () {
                            unawaited(GameAudio.instance.stopOpening());
                            unawaited(_signIn(context, 'Google'));
                          },
                  ),
                  const SizedBox(height: 11),
                  _AuthButton(
                    label: 'MAIN SEBAGAI TAMU',
                    symbol: Icons.person_outline_rounded,
                    tone: const Color(0xffa855f7),
                    onTap: signedIn
                        ? null
                        : () => unawaited(_confirmGuestPlay(context)),
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Masuk untuk menyinkronkan skor, progres level, dan bonus Anda di semua perangkat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Dengan mengetuk Email, Google, atau Tamu,',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const Text(
                        'Anda menyetujui ',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      _PolicyLink(
                        label: 'Ketentuan Penggunaan',
                        onTap: () => _policy(context, 'Ketentuan Penggunaan'),
                      ),
                      const Text(
                        ' dan ',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      _PolicyLink(
                        label: 'Kebijakan Privasi',
                        onTap: () => _policy(context, 'Kebijakan Privasi'),
                      ),
                      const Text(
                        '.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _openHowToPlay(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (guideContext) => HowToPlayScreen(
          finalLabel: 'Kembali',
          onFinished: () => Navigator.pop(guideContext),
        ),
      ),
    );
  }

  static Future<void> _enterGame(
    BuildContext context, {
    bool replaceCurrent = false,
    bool forceProgressChoices = false,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    if (!context.mounted) return;
    final userId = FirebaseService.instance.user?.uid ?? 'perangkat';
    final tutorialKey = 'balok_kosong_tutorial_seen_$userId';
    final tutorialSeen = preferences.getBool(tutorialKey) ?? false;
    final progressKey = 'balok_has_started_$userId';
    final hasStarted = preferences.getBool(progressKey) ?? false;
    final user = FirebaseService.instance.user;
    final developer = isDeveloperGoogleAccount(
      email: user?.email,
      providerIds:
          user?.providerData.map((provider) => provider.providerId) ??
          const <String>[],
    );
    final hasProgress =
        forceProgressChoices ||
        shouldOfferSavedProgress(
          authenticatedAccount: user != null && !user.isAnonymous,
          developer: developer,
          hasStarted: hasStarted,
          playerLevel:
              preferences.getInt(playerProgressKey('balok_level', userId)) ??
              (hasStarted ? preferences.getInt('balok_level') : null),
          playerScore:
              preferences.getInt(playerProgressKey('balok_score', userId)) ??
              (hasStarted ? preferences.getInt('balok_score') : null),
        );
    final route = MaterialPageRoute(
      builder: (modeContext) => _modeSelection(
        modeContext,
        hasProgress: hasProgress,
        tutorialSeen: tutorialSeen,
        tutorialKey: tutorialKey,
        preferences: preferences,
      ),
    );
    if (replaceCurrent) {
      await Navigator.of(context).pushReplacement(route);
    } else {
      await Navigator.of(context).push(route);
    }
  }

  static Widget _modeSelection(
    BuildContext modeContext, {
    required bool hasProgress,
    required bool tutorialSeen,
    required String tutorialKey,
    required SharedPreferences preferences,
  }) => ModeSelectionScreen(
    hasProgress: hasProgress,
    onRelaxed: () => unawaited(
      _startSelectedGame(
        modeContext,
        tutorialSeen: tutorialSeen,
        tutorialKey: tutorialKey,
        preferences: preferences,
        gameBuilder: (_) => const NativeGameScreen(
          homeBuilder: _settingsHome,
          startFromLevelOne: true,
        ),
      ),
    ),
    onChallenge: () => unawaited(
      _startSelectedGame(
        modeContext,
        tutorialSeen: tutorialSeen,
        tutorialKey: tutorialKey,
        preferences: preferences,
        gameBuilder: (_) => const NativeGameScreen(
          challengeMode: true,
          homeBuilder: _settingsHome,
          startFromLevelOne: true,
        ),
      ),
    ),
    onRelaxedSelected: (startFromLevelOne) => unawaited(
      _startSelectedGame(
        modeContext,
        tutorialSeen: tutorialSeen,
        tutorialKey: tutorialKey,
        preferences: preferences,
        gameBuilder: (_) => NativeGameScreen(
          homeBuilder: _settingsHome,
          startFromLevelOne: startFromLevelOne,
        ),
      ),
    ),
    onChallengeSelected: (startFromLevelOne) => unawaited(
      _startSelectedGame(
        modeContext,
        tutorialSeen: tutorialSeen,
        tutorialKey: tutorialKey,
        preferences: preferences,
        gameBuilder: (_) => NativeGameScreen(
          challengeMode: true,
          homeBuilder: _settingsHome,
          startFromLevelOne: startFromLevelOne,
        ),
      ),
    ),
    onCancel: () {
      if (Navigator.of(modeContext).canPop()) {
        Navigator.pop(modeContext);
      } else {
        Navigator.of(modeContext).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    },
  );

  static Future<void> _startSelectedGame(
    BuildContext modeContext, {
    required bool tutorialSeen,
    required String tutorialKey,
    required SharedPreferences preferences,
    required WidgetBuilder gameBuilder,
  }) async {
    if (!modeContext.mounted) return;
    if (tutorialSeen) {
      await Navigator.of(
        modeContext,
      ).pushReplacement(MaterialPageRoute(builder: gameBuilder));
      return;
    }
    await Navigator.of(modeContext).pushReplacement(
      MaterialPageRoute(
        builder: (guideContext) => HowToPlayScreen(
          onFinished: () async {
            await preferences.setBool(tutorialKey, true);
            if (!guideContext.mounted) return;
            await Navigator.of(
              guideContext,
            ).pushReplacement(MaterialPageRoute(builder: gameBuilder));
          },
        ),
      ),
    );
  }

  static Widget _settingsHome(BuildContext _) => const HomeScreen();

  static Future<void> _confirmGuestPlay(BuildContext context) async {
    var busy = false;
    final messenger = ScaffoldMessenger.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, updateDialog) => AlertDialog(
          backgroundColor: const Color(0xff24103c),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xff8247bd)),
          ),
          icon: Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xff7032ad),
              shape: BoxShape.circle,
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(17),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
          ),
          title: Text(
            busy ? 'MENYIAPKAN PERMAINAN…' : 'MAIN SEBAGAI TAMU?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Data permainan tamu tidak disinkronkan. Saat keluar dari '
                'permainan, progres dan level akan hilang dan permainan '
                'berikutnya dimulai lagi dari Level 1.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 12),
              const Text(
                'Paket gratis Tamu: +$guestStarterTokenBonus token awal, '
                '10 petunjuk gratis, 5 energy, grid Level 1–3, dan tema dasar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xffffe5a0),
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff7b38d1), Color(0xffb44df5)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xffdba8ff)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.diamond_rounded,
                      color: Color(0xffffe08a),
                      size: 27,
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'LOGIN & DAPATKAN +$welcomeTokenBonus TOKEN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bonus Selamat Datang diberikan satu kali dan tersimpan '
                'di semua perangkat.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xffd9b8ff), fontSize: 12),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            OutlinedButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('KEMBALI'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      updateDialog(() => busy = true);
                      await GameAudio.instance.stopOpening();
                      try {
                        await FirebaseService.instance.signInAsGuest();
                        if (!dialogContext.mounted) return;
                        await _enterGame(dialogContext, replaceCurrent: true);
                      } catch (error) {
                        if (!dialogContext.mounted) return;
                        updateDialog(() => busy = false);
                        unawaited(
                          GameAudio.instance.playOpening(restart: true),
                        );
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Masuk sebagai Tamu belum berhasil. '
                              '${_friendlyError(error)}',
                            ),
                          ),
                        );
                      }
                    },
              child: const Text('LANJUT'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _signIn(BuildContext context, String provider) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (provider == 'Google') {
        await FirebaseService.instance.signInWithGoogle();
      } else {
        await FirebaseService.instance.signInAsGuest();
      }
      if (!context.mounted) return;
      await _enterGame(context);
    } catch (error) {
      if (!context.mounted) return;
      unawaited(GameAudio.instance.playOpening(restart: true));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Masuk dengan $provider belum berhasil. ${_friendlyError(error)}',
          ),
        ),
      );
    }
  }

  static Future<void> _openEmailLogin(BuildContext context) async {
    // Start navigation before touching the audio player. On slower Android
    // devices, the native audio stop must never delay or swallow the tap.
    final loginResult = Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const EmailLoginScreen()));
    unawaited(GameAudio.instance.stopOpening());
    final signedIn = await loginResult;
    if (signedIn == true && context.mounted) {
      await _enterGame(context);
    } else {
      unawaited(GameAudio.instance.playOpening(restart: true));
    }
  }

  static String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('canceled') || message.contains('cancelled')) {
      return 'Proses dibatalkan.';
    }
    if (message.contains('network')) {
      return 'Periksa koneksi internet lalu coba lagi.';
    }
    if (message.contains('Firebase belum tersambung')) {
      return 'Firebase belum tersambung pada perangkat ini.';
    }
    return 'Silakan coba kembali.';
  }

  static void _policy(BuildContext context, String title) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LegalScreen(
            document: title == 'Ketentuan Penggunaan'
                ? LegalDocument.terms
                : LegalDocument.privacy,
          ),
        ),
      );
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    super.key,
    required this.label,
    required this.symbol,
    required this.tone,
    required this.onTap,
    this.darkLabel = false,
  });
  final String label;
  final IconData symbol;
  final Color tone;
  final VoidCallback? onTap;
  final bool darkLabel;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(symbol, size: 25),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: .35,
        ),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: darkLabel ? const Color(0xff35145b) : Colors.white,
        backgroundColor: tone,
        disabledBackgroundColor: const Color(0xff4a4652),
        disabledForegroundColor: Colors.white38,
        elevation: 0,
        side: BorderSide(
          color: darkLabel ? Colors.white : const Color(0xffe0c4ff),
          width: 1.4,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
  );
}

class _PolicyLink extends StatelessWidget {
  const _PolicyLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xffe0c4ff),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        decoration: TextDecoration.underline,
      ),
    ),
  );
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _level = 1;
  int _score = 0;
  bool _paused = false;
  late List<Block> _blocks;

  @override
  void initState() {
    super.initState();
    _resetLevel();
  }

  void _resetLevel() => _blocks = demoBlocks(_level);

  void _restart() => setState(_resetLevel);

  void _nextLevel() => setState(() {
    _level++;
    _resetLevel();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff11031d),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TopCircle(
                  icon: _paused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  onTap: () => setState(() => _paused = !_paused),
                ),
                Column(
                  children: [
                    const Text('SCORE', style: _topLabel),
                    Text(
                      '$_score',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'LEVEL $_level',
                      style: const TextStyle(
                        color: Color(0xffd8a5ff),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const _TimerPill(),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: _paused
                  ? _PausePanel(
                      onContinue: () => setState(() => _paused = false),
                      onRestart: _restart,
                    )
                  : PuzzleBoard(
                      blocks: _blocks,
                      onExit: (block) => setState(() {
                        _blocks.remove(block);
                        _score += 100;
                        if (_blocks.isEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _showWin(),
                          );
                        }
                      }),
                    ),
            ),
          ),
        ],
      ),
    ),
  );

  void _showWin() => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xff2c1045),
      title: const Text('Papan kosong!'),
      content: const Text('Semua balok sudah keluar.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _restart();
          },
          child: const Text('ULANGI'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            _nextLevel();
          },
          child: const Text('LEVEL BERIKUTNYA'),
        ),
      ],
    ),
  );
}

const _topLabel = TextStyle(
  color: Colors.white54,
  fontSize: 11,
  fontWeight: FontWeight.w900,
  letterSpacing: 1.6,
);

class PuzzleBoard extends StatefulWidget {
  const PuzzleBoard({super.key, required this.blocks, required this.onExit});
  final List<Block> blocks;
  final ValueChanged<Block> onExit;
  @override
  State<PuzzleBoard> createState() => _PuzzleBoardState();
}

class _PuzzleBoardState extends State<PuzzleBoard> {
  Block? _active;
  double _origin = 0;
  double _dragDistance = 0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final side = math.min(c.maxWidth, c.maxHeight);
      final cell = side / boardSize;
      return Center(
        child: SizedBox(
          width: side,
          height: side,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xff25103a),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xff7f3fb0), width: 2),
            ),
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.square(side),
                  painter: GridPainter(cell),
                ),
                for (final block in widget.blocks)
                  _MovableBlock(
                    block: block,
                    cell: cell,
                    onStart: () {
                      _active = block;
                      _origin = block.axis == Axis.horizontal
                          ? block.x
                          : block.y;
                      _dragDistance = 0;
                    },
                    onUpdate: (delta) {
                      if (_active != block) return;
                      setState(() {
                        _dragDistance += delta;
                        final next = _origin + _dragDistance / cell;
                        if (block.axis == Axis.horizontal) {
                          block.x = next.clamp(
                            -block.length + .18,
                            boardSize - .18,
                          );
                        } else {
                          block.y = next.clamp(
                            -block.length + .18,
                            boardSize - .18,
                          );
                        }
                      });
                    },
                    onEnd: () {
                      if ((block.axis == Axis.horizontal &&
                              (block.x < -.7 || block.x > boardSize - .3)) ||
                          (block.axis == Axis.vertical &&
                              (block.y < -.7 || block.y > boardSize - .3))) {
                        widget.onExit(block);
                      }
                      _active = null;
                    },
                  ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Text(
                    'Geser balok sampai keluar',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .38),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _MovableBlock extends StatelessWidget {
  const _MovableBlock({
    required this.block,
    required this.cell,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });
  final Block block;
  final double cell;
  final VoidCallback onStart;
  final ValueChanged<double> onUpdate;
  final VoidCallback onEnd;
  @override
  Widget build(BuildContext context) {
    final horizontal = block.axis == Axis.horizontal;
    return Positioned(
      left: block.x * cell + 4,
      top: block.y * cell + 4,
      width: (horizontal ? block.length : 1) * cell - 8,
      height: (horizontal ? 1 : block.length) * cell - 8,
      child: GestureDetector(
        onPanStart: (_) => onStart(),
        onPanUpdate: (d) => onUpdate(horizontal ? d.delta.dx : d.delta.dy),
        onPanEnd: (_) => onEnd(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cell * .24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(block.color, Colors.white, .32)!,
                block.color,
                Color.lerp(block.color, Colors.black, .22)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: block.color.withValues(alpha: .5),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: .32)),
          ),
          child: Center(
            child: Container(
              width: horizontal ? 28 : 4,
              height: horizontal ? 4 : 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .38),
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Block {
  Block(this.x, this.y, this.length, this.axis, this.color);
  double x;
  double y;
  final int length;
  final Axis axis;
  final Color color;
}

const boardSize = 7;
List<Block> demoBlocks(int level) {
  const colors = [
    Color(0xffa855f7),
    Color(0xffff6ba6),
    Color(0xff39d9c0),
    Color(0xffffc857),
    Color(0xff5597ff),
    Color(0xfff47752),
  ];
  final base = [
    Block(.8, .7, 3, Axis.horizontal, colors[0]),
    Block(4.7, .5, 4, Axis.vertical, colors[1]),
    Block(.2, 2.1, 4, Axis.horizontal, colors[2]),
    Block(2.1, 3.2, 3, Axis.vertical, colors[3]),
    Block(3.4, 5.3, 3, Axis.horizontal, colors[4]),
    Block(5.8, 3.5, 3, Axis.vertical, colors[5]),
  ];
  if (level > 1) {
    base.addAll([
      Block(.4, 5.5, 3, Axis.horizontal, colors[1]),
      Block(1.1, .1, 3, Axis.vertical, colors[2]),
    ]);
  }
  return base;
}

class GridPainter extends CustomPainter {
  GridPainter(this.cell);
  final double cell;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: .065)
      ..strokeWidth = 1;
    for (var i = 1; i < boardSize; i++) {
      canvas.drawLine(Offset(i * cell, 0), Offset(i * cell, size.height), p);
      canvas.drawLine(Offset(0, i * cell), Offset(size.width, i * cell), p);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) => old.cell != cell;
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        'BALOK',
        style: GoogleFonts.fredoka(
          fontSize: 47,
          fontWeight: FontWeight.w700,
          color: Color(0xfffff0cf),
          height: .78,
          letterSpacing: -2.7,
          shadows: const [
            Shadow(color: Color(0xff210834), offset: Offset(0, 3)),
          ],
        ),
      ),
      Text(
        'KOSONG',
        style: GoogleFonts.fredoka(
          fontSize: 47,
          fontWeight: FontWeight.w700,
          color: Color(0xffbd6cff),
          height: .82,
          letterSpacing: -3.1,
          shadows: const [
            Shadow(color: Color(0xff210834), offset: Offset(0, 3)),
          ],
        ),
      ),
    ],
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 60,
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xffa855f7),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    ),
  );
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 54,
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xffa855f7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    ),
  );
}

class _TopCircle extends StatelessWidget {
  const _TopCircle({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton.filled(
    onPressed: onTap,
    icon: Icon(icon),
    style: IconButton.styleFrom(
      backgroundColor: const Color(0xff31134c),
      foregroundColor: Colors.white,
    ),
  );
}

class _TimerPill extends StatelessWidget {
  const _TimerPill();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      color: Color(0xff31134c),
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, color: Color(0xffffd166), size: 18),
          SizedBox(width: 6),
          Text('00:00', style: TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    ),
  );
}

class _PausePanel extends StatelessWidget {
  const _PausePanel({required this.onContinue, required this.onRestart});
  final VoidCallback onContinue, onRestart;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Logo(),
        const SizedBox(height: 32),
        const Text(
          'DIJEDA',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(
          label: 'LANJUTKAN',
          icon: Icons.play_arrow_rounded,
          onPressed: onContinue,
        ),
        const SizedBox(height: 10),
        _SecondaryButton(
          label: 'ULANGI LEVEL',
          icon: Icons.refresh_rounded,
          onPressed: onRestart,
        ),
      ],
    ),
  );
}
