import 'dart:io';

import 'package:flutter/services.dart';

class GameplaySystemUi {
  GameplaySystemUi._();

  static const MethodChannel _channel = MethodChannel(
    'com.ahmadss.balokkosong/system_ui',
  );

  static Future<void> enter() async {
    if (!Platform.isAndroid) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    try {
      await _channel.invokeMethod<void>('setGameplayGestureExclusion', true);
    } on PlatformException {
      // Immersive mode still improves edge dragging on older Android devices.
    } on MissingPluginException {
      // Widget tests and non-Android hosts do not register the native channel.
    }
  }

  static Future<void> leave() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setGameplayGestureExclusion', false);
    } on PlatformException {
      // Restore the system UI even if gesture exclusion is unavailable.
    } on MissingPluginException {
      // Widget tests and non-Android hosts do not register the native channel.
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  static Future<void> collisionHaptic() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>('playCollisionHaptic');
        return;
      } on PlatformException {
        // Fall through to Flutter's cross-platform haptic implementation.
      } on MissingPluginException {
        // Widget tests and non-Android hosts do not register the native channel.
      }
    }
    await HapticFeedback.heavyImpact();
  }
}
