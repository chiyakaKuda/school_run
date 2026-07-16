import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Decorative backdrop for the auth screens.
///
/// Concentric rings radiating from behind the logo — a GPS "ping", which is
/// what this app is actually about — plus a faint route line and a scatter of
/// dots. Everything is painted, so it costs no assets and scales to any screen.
///
/// Sits behind content at very low alpha; if it ever competes with the
/// foreground, lower [intensity] rather than removing it.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, this.intensity = 1.0});

  /// Multiplies every opacity. 0 hides the backdrop entirely.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _BackdropPainter(intensity: intensity)),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({required this.intensity});

  final double intensity;

  /// Roughly where the logo sits, so the rings appear to emanate from it.
  Offset _origin(Size size) => Offset(size.width * 0.17, size.height * 0.14);

  @override
  void paint(Canvas canvas, Size size) {
    final origin = _origin(size);

    _glow(canvas, size, origin);
    _rings(canvas, size, origin);
    _route(canvas, size);
    _dots(canvas, size);
  }

  /// Soft radial wash behind the logo.
  void _glow(Canvas canvas, Size size, Offset origin) {
    final radius = size.width * 0.62;
    canvas.drawCircle(
      origin,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.16 * intensity),
            AppColors.accent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: origin, radius: radius)),
    );
  }

  /// The ping.
  void _rings(Canvas canvas, Size size, Offset origin) {
    const count = 6;
    for (var i = 1; i <= count; i++) {
      final t = i / count;
      canvas.drawCircle(
        origin,
        size.width * 0.16 * i,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          // Fade as they travel outward.
          ..color = AppColors.accent
              .withValues(alpha: (0.20 * (1 - t) + 0.02) * intensity),
      );
    }
  }

  /// A single route threading the lower third, echoing the tracking map.
  void _route(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(-20, size.height * 0.82)
      ..cubicTo(
        size.width * 0.30, size.height * 0.74,
        size.width * 0.42, size.height * 0.98,
        size.width * 0.72, size.height * 0.88,
      )
      ..cubicTo(
        size.width * 0.88, size.height * 0.83,
        size.width * 0.92, size.height * 0.70,
        size.width + 20, size.height * 0.66,
      );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.05 * intensity),
    );
  }

  /// Sparse dots, denser toward the top-right, to break up flat black.
  void _dots(Canvas canvas, Size size) {
    const positions = <Offset>[
      Offset(0.86, 0.09),
      Offset(0.72, 0.16),
      Offset(0.93, 0.22),
      Offset(0.64, 0.05),
      Offset(0.80, 0.32),
      Offset(0.12, 0.62),
      Offset(0.28, 0.71),
    ];

    for (final p in positions) {
      canvas.drawCircle(
        Offset(size.width * p.dx, size.height * p.dy),
        2,
        Paint()..color = AppColors.accent.withValues(alpha: 0.18 * intensity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}
