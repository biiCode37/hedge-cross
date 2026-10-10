import 'package:flutter/material.dart';
import 'design_system.dart';

/// Painter that draws a military F-35 / sci-fi tactical cockpit frame
/// with 45° chamfered corners, dual-tone neon gradient borders (Cyan on top-left,
/// Amber on bottom-right), and corner tick brackets.
class CockpitFramePainter extends CustomPainter {
  final Color cyanColor;
  final Color amberColor;
  final Color surfaceColor;
  final bool isDark;
  final double chamfer;

  CockpitFramePainter({
    required this.cyanColor,
    required this.amberColor,
    required this.surfaceColor,
    required this.isDark,
    this.chamfer = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = chamfer;

    final path = Path()
      ..moveTo(c, 0)
      ..lineTo(w - c, 0)
      ..lineTo(w, c)
      ..lineTo(w, h - c)
      ..lineTo(w - c, h)
      ..lineTo(c, h)
      ..lineTo(0, h - c)
      ..lineTo(0, c)
      ..close();

    // Fill surface
    final fillPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Border with dual-tone gradient
    final rect = Rect.fromLTWH(0, 0, w, h);
    final borderPaint = Paint()
      ..shader = LinearGradient(
        colors: [cyanColor, amberColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);

    // Corner tick brackets (Tactical avionics accents)
    final tickCyanPaint = Paint()
      ..color = cyanColor.withValues(alpha: isDark ? 0.8 : 0.6)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Top-left bracket
    canvas.drawLine(Offset(0, c + 8), Offset(0, c), tickCyanPaint);
    canvas.drawLine(Offset(0, c), Offset(c, 0), tickCyanPaint);
    canvas.drawLine(Offset(c, 0), Offset(c + 8, 0), tickCyanPaint);

    // Bottom-right bracket
    final tickAmberPaint = Paint()
      ..color = amberColor.withValues(alpha: isDark ? 0.8 : 0.6)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w, h - c - 8), Offset(w, h - c), tickAmberPaint);
    canvas.drawLine(Offset(w, h - c), Offset(w - c, h), tickAmberPaint);
    canvas.drawLine(Offset(w - c, h), Offset(w - c - 8, h), tickAmberPaint);
  }

  @override
  bool shouldRepaint(covariant CockpitFramePainter oldDelegate) =>
      oldDelegate.cyanColor != cyanColor ||
      oldDelegate.amberColor != amberColor ||
      oldDelegate.surfaceColor != surfaceColor ||
      oldDelegate.isDark != isDark ||
      oldDelegate.chamfer != chamfer;
}

/// Tactical F-35 Glass Cockpit Container Panel with chamfered geometry
/// and optional recessed header title badge.
class CockpitFrame extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;
  final double chamfer;

  const CockpitFrame({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(14),
    this.chamfer = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.hedge;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? const Color(0xFF00E5FF) : p.cyanInk;
    final amber = isDark ? const Color(0xFFFF9800) : p.amberInk;
    final surface = isDark ? const Color(0xFF0C121D) : Colors.white;

    return CustomPaint(
      painter: CockpitFramePainter(
        cyanColor: cyan,
        amberColor: amber,
        surfaceColor: surface,
        isDark: isDark,
        chamfer: chamfer,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF060B12) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: cyan.withValues(alpha: isDark ? 0.6 : 0.5),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  title!,
                  style: TextStyle(
                    fontFamily: HedgeTokens.cyberFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: cyan,
                  ),
                ),
              ),
            ),
          ],
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Tactical capsule status badge with neon LED dot indicator.
class CockpitStatusBadge extends StatelessWidget {
  final String label;
  final bool isAmber;

  const CockpitStatusBadge({
    super.key,
    required this.label,
    this.isAmber = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.hedge;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isAmber
        ? (isDark ? const Color(0xFFFF9800) : p.amberInk)
        : (isDark ? const Color(0xFF00E5FF) : p.cyanInk);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF060A10) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.7 : 0.8),
          width: 1.1,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color,
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: HedgeTokens.cyberFont,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
