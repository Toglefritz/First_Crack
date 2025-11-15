part of '../brew_view.dart';

/// A card widget displaying a single piece of brew information.
class _BrewInfoCard extends StatelessWidget {
  /// Creates a brew info card.
  const _BrewInfoCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  /// The label describing what information is displayed.
  final String label;

  /// The value to display.
  final String value;

  /// The icon representing this information.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.small,
        vertical: Insets.xSmall,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colorScheme.inversePrimary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: context.colorScheme.inversePrimary,
          ),
          const SizedBox(height: Insets.xxSmall),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.colorScheme.inverseSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.colorScheme.inverseSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
