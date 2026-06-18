import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:harmonoid/core/configuration/configuration.dart';
import 'package:harmonoid/state/lyrics_notifier.dart';

/// {@template desktop_lyrics_notifier}
///
/// DesktopLyricsNotifier
/// ----------------------
/// Implementation to manage desktop lyrics overlay window state.
///
/// {@endtemplate}
class DesktopLyricsNotifier extends ChangeNotifier {
  /// Singleton instance.
  static late final DesktopLyricsNotifier instance;

  /// Whether the [DesktopLyricsNotifier] is initialized.
  static bool initialized = false;

  /// {@macro desktop_lyrics_notifier}
  DesktopLyricsNotifier._() {
    LyricsNotifier.instance.addListener(_onLyricsChanged);
  }

  /// Initializes the [instance].
  static Future<void> ensureInitialized() async {
    if (initialized) return;
    initialized = true;
    instance = DesktopLyricsNotifier._();
    await instance._loadState();
  }

  /// Loads state from persistent configuration.
  Future<void> _loadState() async {
    _isEnabled = Configuration.instance.desktopLyricsEnabled;
    _isLocked = Configuration.instance.desktopLyricsLocked;
    _position = Offset(
      Configuration.instance.desktopLyricsPositionX,
      Configuration.instance.desktopLyricsPositionY,
    );
    _size = Size(
      Configuration.instance.desktopLyricsWidth,
      Configuration.instance.desktopLyricsHeight,
    );
    _opacity = Configuration.instance.desktopLyricsOpacity;
  }

  /// Whether the desktop lyrics window is enabled.
  bool get isEnabled => _isEnabled;
  bool _isEnabled = false;

  /// Whether the desktop lyrics window is locked (not movable/resizable).
  bool get isLocked => _isLocked;
  bool _isLocked = false;

  /// Position of the desktop lyrics window.
  Offset get position => _position;
  Offset _position = Offset.zero;

  /// Size of the desktop lyrics window.
  Size get size => _size;
  Size _size = const Size(600.0, 200.0);

  /// Opacity of the desktop lyrics window (0.0 - 1.0).
  double get opacity => _opacity;
  double _opacity = 1.0;

  /// Current lyrics text being displayed.
  String get currentLyrics {
    final notifier = LyricsNotifier.instance;
    if (notifier.lyrics.isEmpty) return '';

    if (notifier.highlightedIndices.isNotEmpty) {
      final lines = notifier.highlightedIndices.toList()
        ..sort((a, b) => a.compareTo(b));
      return lines
          .where((i) => i >= 0 && i < notifier.lyrics.length)
          .map((i) => notifier.lyrics[i].text)
          .join('\n');
    }

    if (notifier.index >= 0 && notifier.index < notifier.lyrics.length) {
      return notifier.lyrics[notifier.index].text;
    }

    return '';
  }

  /// All highlighted lyrics indices for simultaneous display.
  Set<int> get highlightedIndices => LyricsNotifier.instance.highlightedIndices;

  /// All lyrics for display.
  List<String> get lyrics =>
      LyricsNotifier.instance.lyrics.map((e) => e.text).toList();

  /// Toggles the desktop lyrics window visibility.
  Future<void> toggleEnabled() async {
    _isEnabled = !_isEnabled;
    await Configuration.instance.set(desktopLyricsEnabled: _isEnabled);
    notifyListeners();
  }

  /// Sets the enabled state.
  Future<void> setEnabled(bool enabled) async {
    if (_isEnabled == enabled) return;
    _isEnabled = enabled;
    await Configuration.instance.set(desktopLyricsEnabled: _isEnabled);
    notifyListeners();
  }

  /// Toggles the locked state.
  Future<void> toggleLocked() async {
    _isLocked = !_isLocked;
    await Configuration.instance.set(desktopLyricsLocked: _isLocked);
    notifyListeners();
  }

  /// Sets the locked state.
  Future<void> setLocked(bool locked) async {
    if (_isLocked == locked) return;
    _isLocked = locked;
    await Configuration.instance.set(desktopLyricsLocked: _isLocked);
    notifyListeners();
  }

  /// Updates the position of the window.
  Future<void> setPosition(Offset newPosition) async {
    if (_position == newPosition) return;
    _position = newPosition;
    await Configuration.instance.set(
      desktopLyricsPositionX: _position.dx,
      desktopLyricsPositionY: _position.dy,
    );
    notifyListeners();
  }

  /// Updates the size of the window.
  Future<void> setSize(Size newSize) async {
    if (_size == newSize) return;
    _size = newSize;
    await Configuration.instance.set(
      desktopLyricsWidth: _size.width,
      desktopLyricsHeight: _size.height,
    );
    notifyListeners();
  }

  /// Updates the opacity of the window.
  Future<void> setOpacity(double newOpacity) async {
    final clipped = newOpacity.clamp(0.0, 1.0);
    if (_opacity == clipped) return;
    _opacity = clipped;
    await Configuration.instance.set(desktopLyricsOpacity: _opacity);
     notifyListeners();
  }

  /// Callback when lyrics change.
  void _onLyricsChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    LyricsNotifier.instance.removeListener(_onLyricsChanged);
    super.dispose();
  }
}
