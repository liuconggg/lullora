import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Dialog to confirm awakening from sleep session
class AwakenConfirmationDialog extends StatelessWidget {
  const AwakenConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.wb_sunny,
            color: AppTheme.primaryPurple,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Are you awake?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        'This will end your sleep tracking session and take you to the morning questionnaire.',
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 15,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withOpacity(0.7),
          ),
          child: const Text('Not Yet'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Yes, I\'m Awake'),
        ),
      ],
    );
  }
}
