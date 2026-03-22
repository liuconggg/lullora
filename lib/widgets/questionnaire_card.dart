import 'package:flutter/material.dart';
import '../config/theme.dart';

class QuestionnaireCard extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsets? padding;

  const QuestionnaireCard({
    super.key,
    required this.title,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTheme.heading3,
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
