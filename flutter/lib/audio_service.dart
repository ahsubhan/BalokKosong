import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _MusicTrack { opening, gameplay }

class GameAudio with WidgetsBindingObserver {
  GameAudio._() {
    WidgetsBinding.instance.addObserver(this);
  }

  static final GameAudio instance = GameAudio._();

  final AudioPlayer _music = AudioPlayer();
  final AudioPlayer _jingle = AudioPlayer();
  late final Future<void> _ready = _configureAudio();

  bool? _enabled;
  _MusicTrack _desiredTrack = _MusicTrack.opening;
  _MusicTrack? _activeTrack;

  Future<void> initialize() => _ready;

  Future<void> _configureAudio() async {
    final context = AudioContextConfig(
      focus: AudioContextConfigFocus.gain,
      respectSilence: false,
    ).build();
    await AudioPlayer.global.setAudioContext(context);
    await Future.wait([
      _music.setAudioContext(context),
      _jingle.setAudioContext(context),
    ]);
  }

  Future<bool> _isEnabled() async {
    if (_enabled case final value?) return value;
    final preferences = await SharedPreferences.getInstance();
    return _enabled = preferences.getBool('balok_music_enabled') ?? true;
  }

  Future<void> playOpening() => _selectTrack(_MusicTrack.opening);

  Future<void> playGameplay() => _selectTrack(_MusicTrack.gameplay);

  Future<void> _selectTrack(_MusicTrack track) async {
    _desiredTrack = track;
    if (!await _isEnabled()) return;
    try {
      await _ready;
      if (_activeTrack == track && _music.state == PlayerState.playing) return;
      await _jingle.stop();
      await _music.stop();
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(track == _MusicTrack.opening ? .55 : .42);
      await _music.play(
        AssetSource(
          track == _MusicTrack.opening
              ? 'audio/opening_theme.wav'
              : 'audio/gameplay_theme.wav',
        ),
      );
      _activeTrack = track;
    } catch (error) {
      debugPrint('BalokKosong gagal memutar musik: $error');
    }
  }

  Future<void> playVictory() async {
    if (!await _isEnabled()) return;
    try {
      await _ready;
      await _music.pause();
      await _jingle.stop();
      await _jingle.setReleaseMode(ReleaseMode.stop);
      await _jingle.setVolume(.72);
      await _jingle.play(AssetSource('audio/victory_jingle.wav'));
    } catch (error) {
      debugPrint('BalokKosong gagal memutar musik kemenangan: $error');
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      if (!value) {
        await Future.wait([_music.stop(), _jingle.stop()]);
        _activeTrack = null;
        return;
      }
      await _selectTrack(_desiredTrack);
    } catch (_) {
      // The persisted setting remains authoritative on the next app launch.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_selectTrack(_desiredTrack));
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_pauseAll());
    }
  }

  Future<void> _pauseAll() async {
    try {
      await Future.wait([_music.pause(), _jingle.pause()]);
    } catch (_) {
      // Some platforms report a harmless error when a stopped player is paused.
    }
  }
}
