import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService with WidgetsBindingObserver {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const promoPreference = 'balok_notify_promos';
  static const inactivityPreference = 'balok_notify_inactivity';
  static const energyFullPreference = 'balok_notify_energy_full';

  static const _inactivityId = 7001;
  static const _energyFullId = 7002;
  static const _promoTopic = 'balokkosong_promos';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (_initialized || !_isMobile) return;
    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _local.initialize(settings: settings);
    WidgetsBinding.instance.addObserver(this);
    _initialized = true;
    await resetInactivityReminder();
    await refreshEnergyReminder();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      resetInactivityReminder();
      refreshEnergyReminder();
    }
  }

  Future<bool> setPromos(bool enabled) async {
    if (enabled && !await _requestPermission()) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(promoPreference, enabled);
    await syncPromoSubscription();
    return enabled;
  }

  Future<bool> setInactivityReminder(bool enabled) async {
    if (enabled && !await _requestPermission()) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(inactivityPreference, enabled);
    if (enabled) {
      await resetInactivityReminder();
    } else if (_initialized) {
      await _local.cancel(id: _inactivityId);
    }
    return enabled;
  }

  Future<bool> setEnergyFullReminder(bool enabled) async {
    if (enabled && !await _requestPermission()) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(energyFullPreference, enabled);
    await refreshEnergyReminder();
    return enabled;
  }

  Future<void> syncPromoSubscription() async {
    if (!_isMobile) return;
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(promoPreference) ?? false;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
      if (enabled) {
        await FirebaseMessaging.instance.subscribeToTopic(_promoTopic);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(_promoTopic);
      }
    } catch (_) {
      // Sinkronisasi dicoba lagi saat aplikasi dibuka berikutnya.
    }
  }

  Future<void> resetInactivityReminder() async {
    if (!_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(inactivityPreference) ?? false;
    await _local.cancel(id: _inactivityId);
    if (!enabled) return;
    await _schedule(
      id: _inactivityId,
      delay: const Duration(days: 7),
      title: 'BalokKosong menunggu Anda',
      body: 'Ada papan yang belum kosong. Lanjutkan permainan Anda.',
      payload: 'inactivity',
    );
  }

  Future<void> refreshEnergyReminder() async {
    if (!_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(energyFullPreference) ?? false;
    final unlimited = prefs.getBool('balok_unlimited') ?? false;
    final energy = (prefs.getInt('balok_energy') ?? 5).clamp(0, 5);
    await _local.cancel(id: _energyFullId);
    if (!enabled || unlimited || energy >= 5) return;
    await _schedule(
      id: _energyFullId,
      delay: Duration(minutes: (5 - energy) * 25),
      title: 'Energy sudah penuh',
      body: 'Energy Tantangan Anda sudah 5/5. Saatnya bermain lagi.',
      payload: 'energy_full',
    );
  }

  Future<void> _schedule({
    required int id,
    required Duration delay,
    required String title,
    required String body,
    required String payload,
  }) async {
    await _local.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.now(tz.UTC).add(delay),
      title: title,
      body: body,
      payload: payload,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'balokkosong_reminders',
          'Pengingat permainan',
          channelDescription: 'Pengingat yang dipilih pemain BalokKosong',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<bool> _requestPermission() async {
    if (!_isMobile) return true;
    if (!_initialized) await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _local
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          true;
    }
    return await _local
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }
}
