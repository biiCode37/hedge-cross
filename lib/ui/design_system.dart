import 'package:flutter/material.dart';

abstract final class HedgeTokens {
  static const amber = Color(0xffff9800);
  static const cyan = Color(0xff38bdf8);
  static const electricCyan = Color(0xff00e5ff);
  static const obsidian = Color(0xff070b12);
  static const obsidianSurface = Color(0xff0c1017);
  static const obsidianRaised = Color(0xff141a24);
  static const silver = Color(0xfff8fafc);
  static const touchTarget = 48.0;
  static const primaryButtonHeight = 54.0;
  static const radius = 12.0;
  static const panelRadius = 20.0;
  static const hudRadius = 16.0;
  static const cyberFont = 'Orbitron';
  static const space = 8.0;
  static const motion = Duration(milliseconds: 180);
  static const slideMotion = Duration(milliseconds: 200);
  static const numberFeatures = [FontFeature.tabularFigures()];

  static List<BoxShadow> neonGlow(Color color, {double intensity = 1.0}) => [
    BoxShadow(
      color: color.withValues(alpha: (0.45 * intensity).clamp(0.0, 1.0)),
      blurRadius: 16 * intensity,
      spreadRadius: 1 * intensity,
    ),
    BoxShadow(
      color: color.withValues(alpha: (0.2 * intensity).clamp(0.0, 1.0)),
      blurRadius: 28 * intensity,
      spreadRadius: 2 * intensity,
    ),
  ];
}

@immutable
class HedgePalette extends ThemeExtension<HedgePalette> {
  const HedgePalette({
    required this.background,
    required this.surface,
    required this.raised,
    required this.text,
    required this.muted,
    required this.border,
    required this.amberInk,
    required this.cyanInk,
    required this.focusSurface,
    required this.warningSurface,
    required this.success,
    required this.successSurface,
    required this.danger,
  });
  final Color background,
      surface,
      raised,
      text,
      muted,
      border,
      amberInk,
      cyanInk;
  final Color focusSurface, warningSurface, success, successSurface, danger;
  static const dark = HedgePalette(
    background: HedgeTokens.obsidian,
    surface: Color(0xff0c1017),
    raised: Color(0xff141a24),
    text: HedgeTokens.silver,
    muted: Color(0xff94a3b8),
    border: Color(0xff2b394b),
    amberInk: HedgeTokens.amber,
    cyanInk: HedgeTokens.electricCyan,
    focusSurface: Color(0xff11212d),
    warningSurface: Color(0xff2c2011),
    success: Color(0xff34d399),
    successSurface: Color(0xff102a22),
    danger: Color(0xfffb7185),
  );
  static const light = HedgePalette(
    background: Color(0xfff8fafc),
    surface: Colors.white,
    raised: Color(0xfff1f5f9),
    text: Color(0xff0f172a),
    muted: Color(0xff475569),
    border: Color(0xffcbd5e1),
    amberInk: Color(0xff9a4700),
    cyanInk: Color(0xff006b8b),
    focusSurface: Color(0xffeaf5fc),
    warningSurface: Color(0xfffff2df),
    success: Color(0xff087a4b),
    successSurface: Color(0xffe9f7f0),
    danger: Color(0xffb42336),
  );
  @override
  HedgePalette copyWith({
    Color? background,
    Color? surface,
    Color? raised,
    Color? text,
    Color? muted,
    Color? border,
    Color? amberInk,
    Color? cyanInk,
    Color? focusSurface,
    Color? warningSurface,
    Color? success,
    Color? successSurface,
    Color? danger,
  }) => HedgePalette(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    raised: raised ?? this.raised,
    text: text ?? this.text,
    muted: muted ?? this.muted,
    border: border ?? this.border,
    amberInk: amberInk ?? this.amberInk,
    cyanInk: cyanInk ?? this.cyanInk,
    focusSurface: focusSurface ?? this.focusSurface,
    warningSurface: warningSurface ?? this.warningSurface,
    success: success ?? this.success,
    successSurface: successSurface ?? this.successSurface,
    danger: danger ?? this.danger,
  );
  @override
  HedgePalette lerp(covariant HedgePalette? other, double t) {
    if (other == null) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;
    return HedgePalette(
      background: blend(background, other.background),
      surface: blend(surface, other.surface),
      raised: blend(raised, other.raised),
      text: blend(text, other.text),
      muted: blend(muted, other.muted),
      border: blend(border, other.border),
      amberInk: blend(amberInk, other.amberInk),
      cyanInk: blend(cyanInk, other.cyanInk),
      focusSurface: blend(focusSurface, other.focusSurface),
      warningSurface: blend(warningSurface, other.warningSurface),
      success: blend(success, other.success),
      successSurface: blend(successSurface, other.successSurface),
      danger: blend(danger, other.danger),
    );
  }
}

extension HedgeThemeContext on BuildContext {
  HedgePalette get hedge => Theme.of(this).extension<HedgePalette>()!;
}

ThemeData hedgeTheme(Brightness brightness) {
  final p = brightness == Brightness.dark
      ? HedgePalette.dark
      : HedgePalette.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: HedgeTokens.amber,
    onPrimary: HedgeTokens.obsidian,
    primaryContainer: p.warningSurface,
    onPrimaryContainer: p.amberInk,
    secondary: p.cyanInk,
    onSecondary: p.surface,
    secondaryContainer: p.focusSurface,
    onSecondaryContainer: p.cyanInk,
    error: p.danger,
    onError: p.surface,
    surface: p.surface,
    onSurface: p.text,
    onSurfaceVariant: p.muted,
    outline: p.muted,
    outlineVariant: p.border,
    surfaceContainerLowest: p.background,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.raised,
    surfaceContainerHigh: p.raised,
    surfaceContainerHighest: p.raised,
    surfaceTint: Colors.transparent,
    inverseSurface: p.text,
    onInverseSurface: p.surface,
    inversePrimary: p.amberInk,
  );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(HedgeTokens.radius),
  );
  final text =
      Typography.material2021(
        platform: TargetPlatform.android,
        colorScheme: scheme,
      ).black.apply(
        fontFamily: 'HedgeRoboto',
        bodyColor: p.text,
        displayColor: p.text,
      );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [p],
    fontFamily: 'HedgeRoboto',
    scaffoldBackgroundColor: p.background,
    textTheme: text
        .copyWith(
          headlineLarge: TextStyle(
            fontSize: 44,
            height: 1.06,
            fontWeight: FontWeight.w700,
            color: p.text,
            fontFeatures: HedgeTokens.numberFeatures,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: p.text,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: p.text,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: p.text,
          ),
          bodyMedium: TextStyle(fontSize: 14, height: 1.35, color: p.text),
          bodySmall: TextStyle(fontSize: 12, height: 1.35, color: p.muted),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: p.text,
          ),
        )
        .apply(fontFamily: 'HedgeRoboto'),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HedgeTokens.radius),
        side: BorderSide(color: p.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.raised,
      contentPadding: const EdgeInsets.all(16),
      labelStyle: TextStyle(color: p.muted),
      floatingLabelStyle: TextStyle(color: p.cyanInk),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HedgeTokens.radius),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HedgeTokens.radius),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HedgeTokens.radius),
        borderSide: BorderSide(color: p.cyanInk, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: HedgeTokens.amber,
        foregroundColor: HedgeTokens.obsidian,
        disabledBackgroundColor: p.raised,
        disabledForegroundColor: p.muted,
        minimumSize: const Size(48, 48),
        shape: shape,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.text,
        minimumSize: const Size(48, 48),
        shape: shape,
        side: BorderSide(color: p.border),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.amberInk,
        minimumSize: const Size(48, 48),
        shape: shape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: p.text,
        minimumSize: const Size(48, 48),
        shape: shape,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: p.warningSurface,
      side: BorderSide(color: p.border),
      shape: shape,
      labelStyle: TextStyle(
        fontFamily: 'HedgeRoboto',
        color: p.text,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 76,
      indicatorColor: p.warningSurface,
      indicatorShape: shape,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected) ? p.amberInk : p.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w400,
          color: states.contains(WidgetState.selected) ? p.text : p.muted,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.warningSurface,
      selectedIconTheme: IconThemeData(color: p.amberInk),
      unselectedIconTheme: IconThemeData(color: p.muted),
      selectedLabelTextStyle: TextStyle(
        fontFamily: 'HedgeRoboto',
        color: p.text,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(
        fontFamily: 'HedgeRoboto',
        color: p.muted,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      showDragHandle: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.raised,
      surfaceTintColor: Colors.transparent,
      shape: shape,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: p.raised,
      headerForegroundColor: p.text,
      todayForegroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? HedgeTokens.obsidian
            : p.amberInk,
      ),
      todayBorder: BorderSide(color: p.amberInk),
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? HedgeTokens.obsidian
            : states.contains(WidgetState.disabled)
            ? p.muted
            : p.text,
      ),
      dayBackgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? HedgeTokens.amber : null,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.cyanInk,
      selectionColor: p.cyanInk.withValues(alpha: .24),
      selectionHandleColor: p.cyanInk,
    ),
    dividerTheme: DividerThemeData(color: p.border, thickness: 1),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? p.cyanInk : p.raised,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? p.surface : p.muted,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.cyanInk,
      linearTrackColor: p.raised,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: p.muted,
      minVerticalPadding: 12,
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}
