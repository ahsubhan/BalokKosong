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
  static const double _openingVolume = .40;
  static const double _gameplayVolume = .50;

  final AudioPlayer _music = AudioPlayer();
  final AudioPlayer _jingle = AudioPlayer();
  final AudioPlayer _slide = AudioPlayer();
  Future<void> _slideQueue = Future<void>.value();
  int _activeSlideSession = 0;
  late final Future<void> _ready = _configureAudio();

  bool? _enabled;
  bool _gamePaused = false;
  bool _jinglePlaying = false;
  bool _openingStoppedByChoice = false;
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
      _slide.setAudioContext(context),
      _music.setPlayerMode(PlayerMode.mediaPlayer),
      _jingle.setPlayerMode(PlayerMode.mediaPlayer),
      _slide.setPlayerMode(PlayerMode.mediaPlayer),
      _slide.setReleaseMode(ReleaseMode.loop),
      _slide.setVolume(1),
    ]);
  }

  Future<bool> _isEnabled() async {
    if (_enabled case final value?) return value;
    final preferences = await SharedPreferences.getInstance();
    return _enabled = preferences.getBool('balok_music_enabled') ?? true;
  }

  Future<void> playOpening({bool restart = false}) {
    if (_openingStoppedByChoice && !restart) return Future<void>.value();
    _openingStoppedByChoice = false;
    return _selectTrack(_MusicTrack.opening);
  }

  Future<void> stopOpening() async {
    _openingStoppedByChoice = true;
    if (_desiredTrack != _MusicTrack.opening) return;
    try {
      await _ready;
      await _music.stop();
      _activeTrack = null;
    } catch (_) {
      // The opening track may already be stopped while navigation begins.
    }
  }

  Future<void> playGameplay() => _selectTrack(_MusicTrack.gameplay);

  Future<void> _selectTrack(_MusicTrack track) async {
    _desiredTrack = track;
    if (!await _isEnabled()) return;
    if (track == _MusicTrack.gameplay && _gamePaused) return;
    try {
      await _ready;
      _jinglePlaying = false;
      await _jingle.stop();
      final targetVolume = track == _MusicTrack.opening
          ? _openingVolume
          : _gameplayVolume;
      await _music.setVolume(targetVolume);
      if (_activeTrack == track && _music.state == PlayerState.playing) return;
      await _music.stop();
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(targetVolume);
      await _music.play(
        AssetSource(
          track == _MusicTrack.opening
              ? 'audio/opening_theme_long.m4a'
              : 'audio/gameplay_theme.wav',
        ),
      );
      _activeTrack = track;
    } catch (error) {
      debugPrint('BalokKosong gagal memutar musik: $error');
    }
  }

  int beginBlockSlide() {
    final session = ++_activeSlideSession;
    unawaited(_startBlockSlide(session));
    return session;
  }

  Future<void> _startBlockSlide(int session) async {
    if (!await _isEnabled()) return;
    try {
      await _enqueueSlide(() async {
        if (session != _activeSlideSession) return;
        await _ready;
        if (session != _activeSlideSession) return;
        await _slide.stop();
        if (session != _activeSlideSession) return;
        await _slide.play(AssetSource('audio/block_slide.wav'));
      });
    } catch (error) {
      debugPrint('BalokKosong gagal memutar efek balok: $error');
    }
  }

  Future<void> endBlockSlide(int session) async {
    // Give very short pieces enough time to produce an audible effect before
    // their exit animation ends the gesture.
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (session != _activeSlideSession) return;
    final stopSession = ++_activeSlideSession;
    await _stopBlockSlide(stopSession);
  }

  Future<void> stopBlockSlide() async {
    final stopSession = ++_activeSlideSession;
    await _stopBlockSlide(stopSession);
  }

  Future<void> _stopBlockSlide(int stopSession) async {
    try {
      await _enqueueSlide(() async {
        if (stopSession != _activeSlideSession) return;
        await _ready;
        if (stopSession != _activeSlideSession) return;
        await _slide.stop();
      });
    } catch (_) {
      // The player may already be stopped when a gesture is cancelled.
    }
  }

  Future<void> _enqueueSlide(Future<void> Function() operation) {
    final next = _slideQueue.then(
      (_) => operation(),
      onError: (_, _) => operation(),
    );
    _slideQueue = next;
    return next;
  }

  Future<void> playVictory() async {
    if (!await _isEnabled()) return;
    try {
      await _ready;
      await Future.wait([_music.pause(), stopBlockSlide()]);
      await _jingle.stop();
      await _jingle.setReleaseMode(ReleaseMode.stop);
      await _jingle.setVolume(.78);
      await _jingle.play(AssetSource('audio/victory_jingle.wav'));
      _jinglePlaying = true;
    } catch (error) {
      debugPrint('BalokKosong gagal memutar musik kemenangan: $error');
    }
  }

  Future<void> pauseGameplay() async {
    _gamePaused = true;
    try {
      await _ready;
      await Future.wait([_music.pause(), _jingle.pause(), stopBlockSlide()]);
    } catch (_) {
      // A stopped player does not need to be paused.
    }
  }

  Future<void> resumeGameplay() async {
    _gamePaused = false;
    if (!await _isEnabled()) return;
    try {
      await _ready;
      if (_desiredTrack == _MusicTrack.gameplay &&
          _activeTrack == _MusicTrack.gameplay &&
          _music.state == PlayerState.paused) {
        await _music.setVolume(_gameplayVolume);
        await _music.resume();
        return;
      }
      await _selectTrack(_MusicTrack.gameplay);
    } catch (error) {
      debugPrint('BalokKosong gagal melanjutkan musik: $error');
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      if (!value) {
        await Future.wait([_music.stop(), _jingle.stop(), stopBlockSlide()]);
        _activeTrack = null;
        _jinglePlaying = false;
        return;
      }
      if (_desiredTrack == _MusicTrack.opening && _openingStoppedByChoice) {
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
      if (_desiredTrack == _MusicTrack.opening && _openingStoppedByChoice) {
        return;
      }
      if (_jinglePlaying && _jingle.state == PlayerState.paused) {
        unawaited(_jingle.resume());
      } else if (!_gamePaused || _desiredTrack != _MusicTrack.gameplay) {
        unawaited(_selectTrack(_desiredTrack));
      }
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_pauseAll());
    }
  }

  Future<void> _pauseAll() async {
    try {
      await Future.wait([_music.pause(), _jingle.pause(), stopBlockSlide()]);
    } catch (_) {
      // Some platforms report a harmless error when a stopped player is paused.
    }
  }
}
