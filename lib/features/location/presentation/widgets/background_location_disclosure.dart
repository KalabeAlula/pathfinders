import 'package:flutter/material.dart';

/// Google Play and the App Store require a clear, in-app explanation before
/// the system prompt for background ("always") location access.
///
/// Returns true only when the member explicitly agrees.
Future<bool> showBackgroundLocationDisclosure(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.location_on_outlined),
      title: const Text('Share location when closed?'),
      content: const Text(
        'Pathfinders collects location data to enable real-time circle '
        'navigation even when the app is closed.\n\n'
        'Your circle sees your live position until you pause sharing. You can '
        'stop at any time from the sharing sheet or the ongoing notification.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
