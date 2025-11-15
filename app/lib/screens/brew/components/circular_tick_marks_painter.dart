part of '../brew_view.dart';

/// Custom painter that draws tick marks around a circular progress indicator.
class _CircularTickMarksPainter extends CustomPainter {
  /// Creates a circular tick marks painter.
  const _CircularTickMarksPainter({
    required this.tickCount,
    required this.tickColor,
  });

  /// Number of tick marks to draw.
  final int tickCount;

  /// Color of the tick marks.
  final Color tickColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    const double tickLength = 12.0;
    const double tickWidth = 3.0;

    final Paint tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = tickWidth
      ..strokeCap = StrokeCap.round;

    // Draw tick marks equally spaced around the circle
    for (int i = 0; i < tickCount; i++) {
      // Calculate angle for this tick (starting from top, going clockwise)
      final double angle = (i / tickCount) * 2 * math.pi - (math.pi / 2);

      // Calculate outer point (on the circle)
      final double outerX = centerX + radius * 0.95 * math.cos(angle);
      final double outerY = centerY + radius * 0.95 * math.sin(angle);

      // Calculate inner point (slightly inside the circle)
      final double innerX = centerX + (radius - tickLength) * 0.95 * math.cos(angle);
      final double innerY = centerY + (radius - tickLength) * 0.95 * math.sin(angle);

      // Draw the tick mark
      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
