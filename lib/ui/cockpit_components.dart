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

/// Tactical Top Avionics Flight Header replacing default Material AppBar.
class AvionicsTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String activeRouteName;
  final String timeString;
  final VoidCallback? onTvBoard;
  final VoidCallback? onSettings;
  final VoidCallback? onDateSelect;
  final String? dateText;
  final bool isSaving;

  const AvionicsTopBar({
    super.key,
    required this.activeRouteName,
    required this.timeString,
    this.onTvBoard,
    this.onSettings,
    this.onDateSelect,
    this.dateText,
    this.isSaving = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(74);

  @override
  Widget build(BuildContext context) {
    final p = context.hedge;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? const Color(0xFF00E5FF) : p.cyanInk;
    final amber = isDark ? const Color(0xFFFF9800) : p.amberInk;
    final bg = isDark ? const Color(0xFF070B12) : p.surface;

    return Container(
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 12,
        right: 12,
        bottom: 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(
            color: cyan.withValues(alpha: isDark ? 0.35 : 0.4),
            width: 1.2,
          ),
        ),
      ),
      child: Row(
        children: [
          // Tactical Reticle Icon & Title Group
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B111A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: cyan.withValues(alpha: isDark ? 0.7 : 0.8),
                width: 1.2,
              ),
            ),
            child: Icon(Icons.gps_fixed, size: 20, color: cyan),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'DISPATCH CONTROL',
                    style: TextStyle(
                      fontFamily: HedgeTokens.cyberFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white : p.text,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    activeRouteName.isNotEmpty
                        ? 'MIKROTRANS UTARA · $activeRouteName'
                        : 'MIKROTRANS UTARA · ALL SECTORS',
                    style: TextStyle(
                      fontFamily: HedgeTokens.cyberFont,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: amber,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right Status Pill & Clock
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF060B12) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: cyan.withValues(alpha: 0.5),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: cyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ONLINE · LOKAL',
                      style: TextStyle(
                        fontFamily: HedgeTokens.cyberFont,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: cyan,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                timeString,
                style: TextStyle(
                  fontFamily: HedgeTokens.cyberFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: cyan,
                  fontFeatures: HedgeTokens.numberFeatures,
                ),
              ),
            ],
          ),

          const SizedBox(width: 4),
          // Shortcut icons
          IconButton(
            tooltip: 'Papan keberangkatan',
            onPressed: onTvBoard,
            icon: const Icon(Icons.tv, size: 19),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            tooltip: 'Pengaturan & backup',
            onPressed: onSettings,
            icon: const Icon(Icons.tune, size: 19),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

/// Tactical Cockpit MFD (Multi-Function Display) Navigation Bar.
class CockpitMfdNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const CockpitMfdNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.hedge;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? const Color(0xFF00E5FF) : p.cyanInk;
    final bg = isDark ? const Color(0xFF070B12) : p.surface;

    final items = const [
      (Icons.gps_fixed, '01 · JADWAL'),
      (Icons.directions_bus, '02 · ARMADA'),
      (Icons.reorder, '03 · URUTAN'),
      (Icons.alt_route, '04 · RUTE'),
    ];

    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        left: 6,
        right: 6,
        top: 6,
        bottom: MediaQuery.of(context).padding.bottom + 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(
            color: cyan.withValues(alpha: isDark ? 0.35 : 0.4),
            width: 1.2,
          ),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _MfdNavButton(
                icon: items[i].$1,
                label: items[i].$2,
                selected: selectedIndex == i,
                onTap: () => onDestinationSelected(i),
                isDark: isDark,
                accentColor: cyan,
              ),
            ),
        ],
      ),
    );
  }
}

class _MfdNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final Color accentColor;

  const _MfdNavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? accentColor
        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? (isDark
                  ? accentColor.withValues(alpha: 0.12)
                  : accentColor.withValues(alpha: 0.08))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? accentColor.withValues(alpha: isDark ? 0.8 : 0.9)
                : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: selected && isDark
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: HedgeTokens.cyberFont,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.5,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

