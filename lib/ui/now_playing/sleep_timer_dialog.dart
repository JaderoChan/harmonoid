import 'package:flutter/material.dart';

import 'package:harmonoid/state/sleep_timer_notifier.dart';

class SleepTimerDialog extends StatefulWidget {
  const SleepTimerDialog({super.key});

  static const List<int> presets = [15, 30, 45, 60, 90, 120];

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const SleepTimerDialog(),
    );
  }

  @override
  State<SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<SleepTimerDialog> {
  late int _selectedMinutes;

  @override
  void initState() {
    super.initState();
    _selectedMinutes = SleepTimerDialog.presets.first;
  }

  String _formatRemaining(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: SleepTimerNotifier.instance,
      builder: (context, _) {
        final notifier = SleepTimerNotifier.instance;
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 12.0),
          titlePadding: EdgeInsets.zero,
          title: const SizedBox.shrink(),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36.0,
                      height: 36.0,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        'Sleep Timer',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Stop playback after',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8.0),
                DropdownButtonFormField<int>(
                  value: _selectedMinutes,
                  borderRadius: BorderRadius.circular(14.0),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: SleepTimerDialog.presets
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value min'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedMinutes = value);
                  },
                ),
                const SizedBox(height: 8.0),
                CheckboxListTile(
                  value: notifier.stopAfterTrackEnd,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Stop after current track finishes'),
                  subtitle: const Text('If time is up while music is playing, wait for this track to end.'),
                  onChanged: (value) {
                    if (value == null) return;
                    notifier.setStopAfterTrackEnd(value);
                  },
                ),
                if (notifier.active)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      notifier.pendingStopAfterTrackEnd ? 'Timer reached. Playback will stop after this track.' : 'Remaining: ${_formatRemaining(notifier.remaining)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
          actions: [
            if (notifier.active)
              TextButton(
                onPressed: () => notifier.cancel(),
                child: const Text('Cancel Timer'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                notifier.start(Duration(minutes: _selectedMinutes));
                Navigator.of(context).pop();
              },
              child: const Text('Start'),
            ),
          ],
        );
      },
    );
  }
}
