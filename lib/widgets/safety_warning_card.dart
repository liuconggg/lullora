import 'package:flutter/material.dart';
import '../config/theme.dart';

/// A reusable safety warning card that displays the driving/machinery warning
/// before audio playback. Can be used on any pre-session screen.
class SafetyWarningCard extends StatelessWidget {
  const SafetyWarningCard({super.key});

  static const String warningText = 
      'Do not listen to this recording whilst driving or whilst operating machinery. '
      'Only listen when you can safely relax and bring your full awareness to your own complete comfort.';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              warningText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
