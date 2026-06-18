import 'dart:async';

import 'package:flutter/material.dart';

import 'package:harmonoid/core/configuration/configuration.dart';
import 'package:harmonoid/core/media_player/media_player.dart';

/// Sleep timer state & behavior used by now playing UI.
class SleepTimerNotifier extends ChangeNotifier {
  static late final SleepTimerNotifier instance;

  static bool initialized = false;

  SleepTimerNotifier._() {
    _stopAfterTrackEnd = Configuration.instance.sleepTimerStopAfterTrackEnd;
    MediaPlayer.instance.addListener(_onMediaPlayerStateChanged);
  }

  static Future<void> ensureInitialized() async {
    if (initialized) return;
    initialized = true;
    instance = SleepTimerNotifier._();
  }

  bool get active => _endTime != null || _pendingStopAfterTrackEnd;

  bool get countingDown => _endTime != null;

  bool get pendingStopAfterTrackEnd => _pendingStopAfterTrackEnd;

  Duration get remaining {
    final value = _remaining;
    if (value.isNegative) return Duration.zero;
    return value;
  }

  bool get stopAfterTrackEnd => _stopAfterTrackEnd;

  Future<void> setStopAfterTrackEnd(bool value) async {
    if (_stopAfterTrackEnd == value) return;
    _stopAfterTrackEnd = value;
    notifyListeners();
    await Configuration.instance.set(sleepTimerStopAfterTrackEnd: value);
  }

  void start(Duration duration) {
    cancel();

    _endTime = DateTime.now().add(duration);
    _remaining = duration;

    _deadlineTimer = Timer(duration, _onDeadlineReached);
    _tickerTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tick(),
    );
    notifyListeners();
  }

  void cancel() {
    _deadlineTimer?.cancel();
    _tickerTimer?.cancel();
    _deadlineTimer = null;
    _tickerTimer = null;
    _endTime = null;
    _remaining = Duration.zero;
    _pendingStopAfterTrackEnd = false;
    _pendingTrackUri = null;
    notifyListeners();
  }

  Future<void> _onDeadlineReached() async {
    _deadlineTimer?.cancel();
    _tickerTimer?.cancel();
    _deadlineTimer = null;
    _tickerTimer = null;
    _endTime = null;
    _remaining = Duration.zero;

    final mediaPlayer = MediaPlayer.instance;
    if (_stopAfterTrackEnd && mediaPlayer.state.playing) {
      _pendingStopAfterTrackEnd = true;
      _pendingTrackUri = mediaPlayer.current.uri;
      notifyListeners();
      return;
    }

    await mediaPlayer.pause();
    notifyListeners();
  }

  void _tick() {
    final endTime = _endTime;
    if (endTime == null) return;
    _remaining = endTime.difference(DateTime.now());
    if (_remaining <= Duration.zero) {
      _remaining = Duration.zero;
      return;
    }
    notifyListeners();
  }

  Future<void> _onMediaPlayerStateChanged() async {
    if (!_pendingStopAfterTrackEnd) return;
    final currentUri = MediaPlayer.instance.current.uri;
    if (_pendingTrackUri != currentUri || MediaPlayer.instance.state.completed) {
      _pendingStopAfterTrackEnd = false;
      _pendingTrackUri = null;
      await MediaPlayer.instance.pause();
      notifyListeners();
    }
  }

  Timer? _deadlineTimer;
  Timer? _tickerTimer;
  DateTime? _endTime;
  Duration _remaining = Duration.zero;
  bool _stopAfterTrackEnd = false;
  bool _pendingStopAfterTrackEnd = false;
  String? _pendingTrackUri;
}
