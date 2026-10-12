import 'package:flutter/material.dart';
import '../domain/models.dart';
import 'cockpit_components.dart';
import 'design_system.dart';

/// Modern Tactical Time Picker Tile.
/// Replaces manual text keyboard typing and colon ':' input with a dedicated
/// 24-hour visual clock dial dialog in HEDGE Cyber-Transit styling.
class CockpitTimeTile extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final Color accentColor;
  final VoidCallback? onChanged;

  const CockpitTimeTile({
    super.key,
    required this.label,
    required this.controller,
    required this.isDark,
    required this.accentColor,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.hedge;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          int h = 6;
          int m = 0;
          try {
            final parts = controller.text.split(':');
            if (parts.length >= 2) {
              h = int.parse(parts[0]).clamp(0, 23);
              m = int.parse(parts[1]).clamp(0, 59);
            }
          } catch (_) {}

          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(hour: h, minute: m),
            initialEntryMode: TimePickerEntryMode.dial,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
                      primary: accentColor,
                      onPrimary: Colors.black,
                      surface: isDark ? const Color(0xFF0C121D) : Colors.white,
                      onSurface: isDark ? Colors.white : Colors.black87,
                    ),
                    timePickerTheme: TimePickerThemeData(
                      backgroundColor: isDark ? const Color(0xFF0C121D) : Colors.white,
                      dialHandColor: accentColor,
                      dialBackgroundColor: isDark ? const Color(0xFF060910) : const Color(0xFFF1F5F9),
                      dialTextColor: isDark ? Colors.white : Colors.black87,
                      entryModeIconColor: accentColor,
                      hourMinuteTextColor: isDark ? Colors.white : Colors.black87,
                      hourMinuteColor: isDark ? const Color(0xFF141E2E) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: child!,
                ),
              );
            },
          );

          if (picked != null) {
            final formatted =
                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
            controller.text = formatted;
            onChanged?.call();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF080D16) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withValues(alpha: isDark ? 0.6 : 0.7),
              width: 1.2,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.12),
                      blurRadius: 8,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: HedgeTokens.cyberFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: isDark ? const Color(0xFF94A3B8) : p.muted,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.touch_app_rounded,
                    size: 14,
                    color: accentColor.withValues(alpha: 0.8),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, val, _) {
                  final text = val.text.isEmpty ? '--:--' : val.text;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          fontFamily: HedgeTokens.cyberFont,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white : p.text,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'WIB',
                        style: TextStyle(
                          fontFamily: HedgeTokens.cyberFont,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Digital Cockpit Stepper with thumb-first [-] and [+] buttons,
/// embedded text input compatibility, and neon glow display.
class CockpitDigitalStepper extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int min;
  final int max;
  final int step;
  final String unit;
  final bool isDark;
  final Color accentColor;
  final VoidCallback? onChanged;

  const CockpitDigitalStepper({
    super.key,
    required this.label,
    required this.controller,
    this.min = 1,
    this.max = 300,
    this.step = 1,
    required this.unit,
    required this.isDark,
    required this.accentColor,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.hedge;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF080D16) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : p.border,
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: HedgeTokens.cyberFont,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isDark ? const Color(0xFF94A3B8) : p.muted,
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, val, _) {
              final currentVal = int.tryParse(val.text) ?? min;
              final canMinus = currentVal > min;
              final canPlus = currentVal < max;

              return Row(
                children: [
                  // Minus button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: canMinus
                          ? () {
                              final next = (currentVal - step).clamp(min, max);
                              controller.text = '$next';
                              onChanged?.call();
                            }
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 44,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? (canMinus ? const Color(0xFF141E2E) : const Color(0xFF0C1017))
                              : (canMinus ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: canMinus
                                ? accentColor.withValues(alpha: isDark ? 0.6 : 0.7)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 20,
                          color: canMinus ? (isDark ? Colors.white : p.text) : p.muted.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Center display with embedded TextFormField for test & direct input support
                  Expanded(
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF05080E) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentColor.withValues(alpha: isDark ? 0.35 : 0.4),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IntrinsicWidth(
                            child: TextFormField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: HedgeTokens.cyberFont,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: isDark ? Colors.white : p.text,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => onChanged?.call(),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            unit,
                            style: TextStyle(
                              fontFamily: HedgeTokens.cyberFont,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Plus button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: canPlus
                          ? () {
                              final next = (currentVal + step).clamp(min, max);
                              controller.text = '$next';
                              onChanged?.call();
                            }
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 44,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? (canPlus ? const Color(0xFF141E2E) : const Color(0xFF0C1017))
                              : (canPlus ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: canPlus
                                ? accentColor.withValues(alpha: isDark ? 0.6 : 0.7)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 20,
                          color: canPlus ? (isDark ? Colors.white : p.text) : p.muted.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 3-Segment Cockpit MFD Console Switcher.
class CockpitMfdSegmentSelector extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onSelected;
  final bool isDark;
  final Color cyan;
  final Color amber;

  const CockpitMfdSegmentSelector({
    super.key,
    required this.activeIndex,
    required this.onSelected,
    required this.isDark,
    required this.cyan,
    required this.amber,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.hedge;
    final items = [
      (label: 'OPERASIONAL', icon: Icons.schedule_rounded, color: cyan),
      (label: 'PEAK HOURS', icon: Icons.speed_rounded, color: cyan),
      (label: 'DISPATCH ALARM', icon: Icons.notifications_active_rounded, color: amber),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF060910) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : p.border,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(i),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: activeIndex == i
                          ? (isDark
                              ? items[i].color.withValues(alpha: 0.2)
                              : items[i].color.withValues(alpha: 0.12))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      border: activeIndex == i
                          ? Border.all(
                              color: items[i].color.withValues(alpha: isDark ? 0.8 : 0.9),
                              width: 1.2,
                            )
                          : null,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            items[i].icon,
                            size: 14,
                            color: activeIndex == i
                                ? items[i].color
                                : (isDark ? const Color(0xFF64748B) : p.muted),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            items[i].label,
                            style: TextStyle(
                              fontFamily: HedgeTokens.cyberFont,
                              fontSize: 10,
                              fontWeight: activeIndex == i ? FontWeight.w900 : FontWeight.w700,
                              letterSpacing: 0.6,
                              color: activeIndex == i
                                  ? (isDark ? Colors.white : p.text)
                                  : (isDark ? const Color(0xFF64748B) : p.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Flight Configuration Sheet (AVIONICS CONFIG).
/// Provides full tactical control over route operations, peak headway intervals,
/// and dispatch alerts in a streamlined 3-segment Cockpit MFD layout.
class ConfigurationSheet extends StatefulWidget {
  const ConfigurationSheet({super.key, required this.route});
  final HedgeRoute route;
  @override
  State<ConfigurationSheet> createState() => _ConfigurationSheetState();
}

class _ConfigurationSheetState extends State<ConfigurationSheet> {
  final form = GlobalKey<FormState>();
  int activeSegment = 0;

  late final TextEditingController start, end, rounds, prep, duration;
  late final List<TextEditingController> peakFields;
  late bool peak,
      slow,
      alarm,
      banner,
      fullScreen,
      preparation,
      departure,
      sound,
      vibration;

  @override
  void initState() {
    super.initState();
    final r = widget.route;
    start = TextEditingController(text: r.config.start);
    end = TextEditingController(text: r.config.end);
    rounds = TextEditingController(text: '${r.config.rounds}');
    prep = TextEditingController(text: '${r.preparationSeconds}');
    duration = TextEditingController(text: '${r.alarmDuration}');
    peak = r.config.peakEnabled;
    slow = r.config.slowFirst;
    alarm = r.alarmEnabled;
    banner = r.alerts.banner;
    fullScreen = r.alerts.fullScreen;
    preparation = r.alerts.preparation;
    departure = r.alerts.departure;
    sound = r.alerts.sound;
    vibration = r.alerts.vibration;
    final periods = r.config.peaks;
    peakFields = [
      for (var i = 0; i < 2; i++) ...[
        TextEditingController(
          text: i < periods.length ? periods[i].start : '06:00',
        ),
        TextEditingController(
          text: i < periods.length ? periods[i].end : '08:00',
        ),
        TextEditingController(
          text: i < periods.length ? '${periods[i].interval}' : '3',
        ),
      ],
    ];
  }

  @override
  void dispose() {
    for (final field in [start, end, rounds, prep, duration, ...peakFields]) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.hedge;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? const Color(0xFF00E5FF) : p.cyanInk;
    final amber = isDark ? const Color(0xFFFF9800) : p.amberInk;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height:
            (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom -
                MediaQuery.viewPaddingOf(context).top) *
            .88,
        child: Form(
          key: form,
          child: Column(
            children: [
              // Top Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CockpitStatusBadge(
                            label: 'AVIONICS CONFIG',
                            isAmber: false,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Atur ${widget.route.name}',
                            style: TextStyle(
                              fontFamily: HedgeTokens.cyberFont,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: isDark ? Colors.white : p.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Segment Selector MFD
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: CockpitMfdSegmentSelector(
                  activeIndex: activeSegment,
                  onSelected: (idx) => setState(() => activeSegment = idx),
                  isDark: isDark,
                  cyan: cyan,
                  amber: amber,
                ),
              ),

              // Segment Content Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    if (activeSegment == 0) ...[
                      // 1. OPERASIONAL PANEL
                      CockpitFrame(
                        title: 'JAM OPERASIONAL RUTE',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: CockpitTimeTile(
                                    label: 'JAM MULAI',
                                    controller: start,
                                    isDark: isDark,
                                    accentColor: cyan,
                                    onChanged: () => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CockpitTimeTile(
                                    label: 'JAM SELESAI',
                                    controller: end,
                                    isDark: isDark,
                                    accentColor: cyan,
                                    onChanged: () => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            CockpitDigitalStepper(
                              label: 'TARGET RITASE PER UNIT',
                              controller: rounds,
                              min: 1,
                              max: 30,
                              unit: 'RITASE',
                              isDark: isDark,
                              accentColor: cyan,
                              onChanged: () => setState(() {}),
                            ),
                            const SizedBox(height: 10),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Headway lambat lebih dahulu',
                                style: TextStyle(
                                  fontFamily: HedgeTokens.cyberFont,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                'Urutkan headway yang lebih longgar di ritase awal.',
                                style: TextStyle(fontSize: 11, color: p.muted),
                              ),
                              value: slow,
                              onChanged: (v) => setState(() => slow = v),
                            ),
                          ],
                        ),
                      ),
                    ] else if (activeSegment == 1) ...[
                      // 2. PEAK HOURS PANEL
                      CockpitFrame(
                        title: 'PERIODE JAM SIBUK (PEAK)',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Gunakan periode peak',
                                style: TextStyle(
                                  fontFamily: HedgeTokens.cyberFont,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Percepat headway saat jam sibuk pagi dan sore.',
                                style: TextStyle(fontSize: 11, color: p.muted),
                              ),
                              value: peak,
                              onChanged: (v) => setState(() => peak = v),
                            ),
                            if (peak) ...[
                              const SizedBox(height: 10),
                              for (var i = 0; i < 2; i++) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF060910) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: cyan.withValues(alpha: isDark ? 0.3 : 0.4),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CockpitStatusBadge(
                                        label: 'PEAK ${i + 1}',
                                        isAmber: false,
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CockpitTimeTile(
                                              label: 'MULAI',
                                              controller: peakFields[i * 3],
                                              isDark: isDark,
                                              accentColor: cyan,
                                              onChanged: () => setState(() {}),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: CockpitTimeTile(
                                              label: 'SELESAI',
                                              controller: peakFields[i * 3 + 1],
                                              isDark: isDark,
                                              accentColor: cyan,
                                              onChanged: () => setState(() {}),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      CockpitDigitalStepper(
                                        label: 'INTERVAL HEADWAY PEAK',
                                        controller: peakFields[i * 3 + 2],
                                        min: 1,
                                        max: 60,
                                        unit: 'MENIT',
                                        isDark: isDark,
                                        accentColor: cyan,
                                        onChanged: () => setState(() {}),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              Text(
                                'Konfigurasi peak yang tidak bisa menjaga batas waktu dan headway positif akan ditolak saat membuat jadwal.',
                                style: TextStyle(fontSize: 11, color: p.muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      // 3. DISPATCH ALARM PANEL
                      CockpitFrame(
                        title: 'DISPATCH ALARM & TELEMETRY',
                        isAmber: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Alarm rute aktif',
                                style: TextStyle(
                                  fontFamily: HedgeTokens.cyberFont,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: amber,
                                ),
                              ),
                              value: alarm,
                              onChanged: (v) => setState(() => alarm = v),
                            ),
                            if (alarm) ...[
                              const Divider(height: 18),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Banner notifikasi',
                                  style: TextStyle(
                                    fontFamily: HedgeTokens.cyberFont,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                value: banner,
                                onChanged: (v) => setState(() => banner = v),
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Alert layar penuh',
                                  style: TextStyle(
                                    fontFamily: HedgeTokens.cyberFont,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  'Dialog HUD Cyberpunk layar penuh muncul otomatis baik saat aplikasi aktif maupun saat membuka aplikasi lain.',
                                  style: TextStyle(fontSize: 11, color: p.muted),
                                ),
                                value: fullScreen,
                                onChanged: (v) => setState(() => fullScreen = v),
                              ),
                              const Divider(height: 18),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Pengingat sebelum berangkat',
                                  style: TextStyle(
                                    fontFamily: HedgeTokens.cyberFont,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                value: preparation,
                                onChanged: (v) => setState(() => preparation = v),
                              ),
                              if (preparation) ...[
                                const SizedBox(height: 6),
                                CockpitDigitalStepper(
                                  label: 'Persiapan sebelum berangkat (detik)',
                                  controller: prep,
                                  min: 1,
                                  max: 300,
                                  step: 5,
                                  unit: 'DETIK',
                                  isDark: isDark,
                                  accentColor: amber,
                                  onChanged: () => setState(() {}),
                                ),
                              ],
                              const SizedBox(height: 10),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Alarm saat waktunya berangkat',
                                  style: TextStyle(
                                    fontFamily: HedgeTokens.cyberFont,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                value: departure,
                                onChanged: (v) => setState(() => departure = v),
                              ),
                              const SizedBox(height: 10),
                              CockpitDigitalStepper(
                                label: 'Tutup alert otomatis setelah (detik)',
                                controller: duration,
                                min: 1,
                                max: 300,
                                step: 5,
                                unit: 'DETIK',
                                isDark: isDark,
                                accentColor: amber,
                                onChanged: () => setState(() {}),
                              ),
                              const Divider(height: 18),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Suara alarm (TTS Bahasa Indonesia)',
                                  style: TextStyle(
                                    fontFamily: HedgeTokens.cyberFont,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  'Mengikuti volume Media/Speaker Android.',
                                  style: TextStyle(fontSize: 11, color: p.muted),
                                ),
                                value: sound,
                                onChanged: (v) => setState(() => sound = v),
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Getaran perangkat',
                                  style: TextStyle(
                                    fontFamily: HedgeTokens.cyberFont,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                value: vibration,
                                onChanged: (v) => setState(() => vibration = v),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sudah Berangkat mencatat aktual dan membatalkan pengingat unit itu. Timeout hanya menutup alert.',
                                style: TextStyle(fontSize: 11, color: p.muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Pengaturan alarm berlaku segera setelah disimpan. Perubahan jam, ritase dan peak memerlukan jadwal dibuat ulang.',
                      style: TextStyle(fontSize: 11, color: p.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Bottom Save Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? cyan.withValues(alpha: 0.22)
                          : p.focusSurface,
                      foregroundColor: cyan,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: cyan.withValues(alpha: isDark ? 0.8 : 0.9),
                          width: 1.2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    onPressed: () {
                      if (!form.currentState!.validate()) return;
                      if (alarm &&
                          ((!banner && !fullScreen) ||
                              (!preparation && !departure))) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Pilih minimal satu tampilan dan satu waktu alarm, atau matikan Alarm rute.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (parseMinute(end.text) <= parseMinute(start.text)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Jam selesai harus setelah mulai.'),
                          ),
                        );
                        return;
                      }
                      final config = PlanConfig(
                        start: start.text,
                        end: end.text,
                        rounds: int.tryParse(rounds.text) ?? widget.route.config.rounds,
                        slowFirst: slow,
                        peakEnabled: peak,
                        peaks: [
                          for (var i = 0; i < 2; i++)
                            PeakPeriod(
                              start: peakFields[i * 3].text,
                              end: peakFields[i * 3 + 1].text,
                              interval: int.tryParse(peakFields[i * 3 + 2].text) ?? 3,
                            ),
                        ],
                      );
                      Navigator.pop(
                        context,
                        widget.route.copyWith(
                          config: config,
                          alarmEnabled: alarm,
                          preparationSeconds:
                              int.tryParse(prep.text)?.clamp(0, 300) ??
                              widget.route.preparationSeconds,
                          alarmDuration:
                              int.tryParse(duration.text)?.clamp(1, 300) ??
                              widget.route.alarmDuration,
                          alerts: AlarmPreferences(
                            banner: banner,
                            fullScreen: fullScreen,
                            preparation: preparation,
                            departure: departure,
                            sound: sound,
                            vibration: vibration,
                          ),
                        ),
                      );
                    },
                    label: Text(
                      'Simpan pengaturan',
                      style: TextStyle(
                        fontFamily: HedgeTokens.cyberFont,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
