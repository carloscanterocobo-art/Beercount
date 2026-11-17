import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BeerCounterCard extends StatelessWidget {
  final String name;
  final String description;
  final String emoji;
  final int count;

  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const BeerCounterCard({
    super.key,
    required this.name,
    required this.description,
    required this.emoji,
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 30)),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleLarge),

                      const SizedBox(height: 4),

                      Text(
                        description,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  '$count',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botón para restar
                IconButton(
                  onPressed: count > 0 ? onDecrement : null,
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    backgroundColor: AppTheme.surfaceHighlight,
                    disabledForegroundColor: AppTheme.textSecondary.withValues(
                      alpha: 0.35,
                    ),
                    fixedSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Botón para sumar
                IconButton(
                  onPressed: onIncrement,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    foregroundColor: AppTheme.background,
                    backgroundColor: AppTheme.primary,
                    fixedSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
