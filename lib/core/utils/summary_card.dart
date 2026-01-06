import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final double? progress;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.subtitle,
    this.progress,
    this.icon,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use provided color or primary, but as a solid background or accent
    // For a "plain" look, we might want a dark surface with colored text/icon,
    // OR a solid colored card.
    // Given the previous design was a gradient card (likely colorful),
    // a solid colored card is the direct "plain" equivalent.
    
    final cardColor = backgroundColor ?? color ?? theme.colorScheme.surface;
    final onCardColor = (cardColor.computeLuminance() > 0.5) ? Colors.black : Colors.white;
    final contentColor = color != null && backgroundColor == null ? onCardColor : (color ?? onCardColor);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
             color: Colors.white.withAlpha(13), // Subtle border for definition
             width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: contentColor.withOpacity(0.7),
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (icon != null)
                Icon(icon, color: contentColor.withOpacity(0.7), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: theme.textTheme.displaySmall?.copyWith(
              color: contentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: contentColor.withOpacity(0.7),
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.black26,
                color: contentColor,
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
