import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:system_fonts/system_fonts.dart';

import 'package:harmonoid/core/configuration/configuration.dart';
import 'package:harmonoid/core/media_player/media_player.dart';
import 'package:harmonoid/extensions/string.dart';
import 'package:harmonoid/localization/localization.dart';
import 'package:harmonoid/state/desktop_lyrics_notifier.dart';
import 'package:harmonoid/state/lyrics_notifier.dart';

class DesktopLyricsWindow extends StatefulWidget {
  const DesktopLyricsWindow({super.key});

  @override
  State<DesktopLyricsWindow> createState() => _DesktopLyricsWindowState();
}

class _DesktopLyricsWindowState extends State<DesktopLyricsWindow> {
  late Offset _dragStart;
  late Offset _positionStart;
  String? _fontFamily;
  bool _showUnlockButton = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final fontFamily = Configuration.instance.lyricsViewFontFamily;
        _fontFamily = fontFamily.isEmpty ? '' : await SystemFonts().loadFont(fontFamily);
      } catch (exception, stacktrace) {
        debugPrint(exception.toString());
        debugPrint(stacktrace.toString());
        _fontFamily = '';
      }
      setState(() {});
    });
  }

  void _onPanStart(DragStartDetails details) {
    _dragStart = details.globalPosition;
    _positionStart = DesktopLyricsNotifier.instance.position;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (DesktopLyricsNotifier.instance.isLocked) return;

    final delta = details.globalPosition - _dragStart;
    DesktopLyricsNotifier.instance.setPosition(_positionStart + delta);
  }

  void _onMouseMove(PointerMoveEvent event) {
    if (!DesktopLyricsNotifier.instance.isLocked) return;

    // Show unlock button only in top-right corner area (small region)
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final localPosition = event.localPosition;

    // Check if in top-right corner (e.g., 40x40 px region)
    final isInUnlockZone = localPosition.dx > size.width - 40 && localPosition.dy < 40;

    if (_showUnlockButton != isInUnlockZone) {
      setState(() {
        _showUnlockButton = isInUnlockZone;
      });
    }
  }

  void _onMouseExit(PointerExitEvent event) {
    if (_showUnlockButton) {
      setState(() {
        _showUnlockButton = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopPlatform = switch (defaultTargetPlatform) {
      TargetPlatform.windows || TargetPlatform.linux || TargetPlatform.macOS => true,
      _ => false,
    };
    if (!isDesktopPlatform) {
      return const SizedBox.shrink();
    }

    if (_fontFamily == null) {
      return const SizedBox.shrink();
    }

    return Consumer2<DesktopLyricsNotifier, LyricsNotifier>(
      builder: (context, desktopLyricsNotifier, lyricsNotifier, _) {
        if (!desktopLyricsNotifier.isEnabled) {
          return const SizedBox.shrink();
        }

        return Positioned(
          left: desktopLyricsNotifier.position.dx,
          top: desktopLyricsNotifier.position.dy,
          child: MouseRegion(
            onMove: _onMouseMove,
            onExit: _onMouseExit,
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              child: SizedBox(
                width: desktopLyricsNotifier.size.width,
                height: desktopLyricsNotifier.size.height,
                child: Stack(
                  children: [
                    // Background with transparency
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3 * desktopLyricsNotifier.opacity),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2 * desktopLyricsNotifier.opacity),
                                width: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Lyrics display
                    Center(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildLyricsDisplay(desktopLyricsNotifier, lyricsNotifier),
                        ),
                      ),
                    ),

                    // Top button bar (semi-transparent)
                    if (!desktopLyricsNotifier.isLocked)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12.0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildIconButton(
                                icon: Icons.lock_outline,
                                tooltip: Localization.instance.DESKTOP_LYRICS_LOCK,
                                onPressed: () {
                                  DesktopLyricsNotifier.instance.toggleLocked();
                                },
                              ),
                              _buildIconButton(
                                icon: Icons.close,
                                 tooltip: Localization.instance.HIDE,
                                onPressed: () {
                                  DesktopLyricsNotifier.instance.setEnabled(false);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Unlock button (only visible in locked state + near corner)
                    if (desktopLyricsNotifier.isLocked && _showUnlockButton)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: _buildIconButton(
                            icon: Icons.lock_open,
                            tooltip: Localization.instance.DESKTOP_LYRICS_UNLOCK,
                            size: 24.0,
                            onPressed: () {
                              DesktopLyricsNotifier.instance.toggleLocked();
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLyricsDisplay(
    DesktopLyricsNotifier desktopLyricsNotifier,
    LyricsNotifier lyricsNotifier,
  ) {
    final text = desktopLyricsNotifier.currentLyrics;

    if (text.isEmpty) {
      return Text(
        Localization.instance.LYRICS_NOT_FOUND,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white.withValues(alpha: 0.5),
          fontFamily: _fontFamily?.nullIfBlank(),
        ),
      );
    }

    final progress = _calculateProgress(lyricsNotifier);
    final textStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Colors.white,
          fontFamily: _fontFamily?.nullIfBlank(),
          fontSize: 32.0,
          height: 1.4,
        );

    // Progress mask: base text + clipped highlighted text based on current lyric progress.
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthFactor = progress.clamp(0.0, 1.0);
        return Stack(
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: textStyle?.copyWith(
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: widthFactor,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: textStyle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _calculateProgress(LyricsNotifier lyricsNotifier) {
    if (lyricsNotifier.index < 0 || lyricsNotifier.index >= lyricsNotifier.lyrics.length) {
      return 0.0;
    }

    final nowMs = MediaPlayer.instance.state.position.inMilliseconds;
    final currentTimestamp = lyricsNotifier.lyrics[lyricsNotifier.index].timestamp;

    int? nextTimestamp;
    for (int i = lyricsNotifier.index + 1; i < lyricsNotifier.lyrics.length; i++) {
      final t = lyricsNotifier.lyrics[i].timestamp;
      if (t > currentTimestamp) {
        nextTimestamp = t;
        break;
      }
    }

    // Fallback duration for last line.
    nextTimestamp ??= currentTimestamp + 4000;

    final duration = (nextTimestamp - currentTimestamp).clamp(1, 60 * 1000);
    final elapsed = (nowMs - currentTimestamp).clamp(0, duration);
    return elapsed / duration;
  }
  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    double size = 32.0,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              icon,
              size: size,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}
