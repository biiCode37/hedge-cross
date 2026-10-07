part of 'app.dart';

class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key});
  @override
  ConsumerState<BoardScreen> createState() => _BoardState();
}

class _BoardState extends ConsumerState<BoardScreen> {
  bool combined = true;
  @override
  void initState() {
    super.initState();
    unawaited(WakelockPlus.enable().catchError((Object _) {}));
  }

  @override
  void dispose() {
    unawaited(WakelockPlus.disable().catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceProvider).workspace;
    final focus = ref.watch(
      dispatchFocusProvider(combined ? null : workspace.activeRoute?.id),
    );
    final p = context.hedge;
    final routes = combined
        ? workspace.routes.where((r) => r.participates)
        : [if (workspace.activeRoute != null) workspace.activeRoute!];
    final rows =
        <
          ({
            HedgeRoute route,
            ScheduleRevision revision,
            Departure row,
            DateTime at,
          })
        >[];
    final now = ref.read(clockProvider).value ?? DateTime.now();
    for (final route in routes) {
      final revision = route.schedule;
      if (revision == null) continue;
      for (final row in revision.departures) {
        final at = plannedInstant(revision.date, row.minute);
        if (!workspace.hasDeparted(row.id) &&
            (!at.isBefore(now.toUtc()) || row.id == focus?.departure.id)) {
          rows.add((route: route, revision: revision, row: row, at: at));
        }
      }
    }
    rows.sort((a, b) {
      final compare = a.at.compareTo(b.at);
      return compare != 0
          ? compare
          : '${a.route.id}:${a.row.id}'.compareTo('${b.route.id}:${b.row.id}');
    });
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Papan HEDGE',
                style: TextStyle(
                  fontFamily: HedgeTokens.cyberFont,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: p.cyanInk.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: p.cyanInk.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'FIDS',
                  style: TextStyle(
                    fontFamily: HedgeTokens.cyberFont,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: p.cyanInk,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: p.cyanInk,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => setState(() => combined = !combined),
              icon: Icon(
                combined ? Icons.alt_route_rounded : Icons.route_rounded,
                size: 16,
                color: p.cyanInk,
              ),
              label: Text(
                combined ? 'Semua rute' : 'Rute aktif',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: focus == null
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF0C1017)
                              : p.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: p.border.withValues(alpha: 0.6)),
                        ),
                        child: Center(
                          child: Text(
                            'Tidak ada keberangkatan mendatang',
                            style: TextStyle(
                              fontFamily: HedgeTokens.cyberFont,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: p.muted,
                            ),
                          ),
                        ),
                      )
                    : DepartureFocusPanel(
                        focus: focus,
                        large: MediaQuery.sizeOf(context).width >= 600,
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Consumer(
                  builder: (context, clockRef, _) {
                    final instant =
                        clockRef.watch(clockProvider).value ?? DateTime.now();
                    final jakarta = instant.toUtc().add(
                      const Duration(hours: 7),
                    );
                    final secStr = jakarta.second.toString().padLeft(2, '0');
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0C1017) : p.raised,
                        borderRadius: BorderRadius.circular(HedgeTokens.radius),
                        border: Border.all(
                          color: p.cyanInk.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: isDark
                            ? [
                                BoxShadow(
                                  color: p.cyanInk.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: p.cyanInk),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${serviceDate(instant)} · ${formatMinute(jakarta.hour * 60 + jakarta.minute)}:$secStr WIB',
                                style: TextStyle(
                                  fontFamily: HedgeTokens.cyberFont,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: p.text,
                                  fontFeatures: HedgeTokens.numberFeatures,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: p.cyanInk.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: p.cyanInk.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.tv_rounded, size: 13, color: p.cyanInk),
                                const SizedBox(width: 4),
                                Text(
                                  'FIDS KIOSK',
                                  style: TextStyle(
                                    fontFamily: HedgeTokens.cyberFont,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .8,
                                    color: p.cyanInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 58,
                      child: Text(
                        'WAKTU',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: HedgeTokens.cyberFont,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: p.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                    Expanded(
                      child: Text(
                        'ARMADA · STATUS',
                        style: TextStyle(
                          fontFamily: HedgeTokens.cyberFont,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: p.muted,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 68,
                      child: Text(
                        'HITUNG MUNDUR',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: HedgeTokens.cyberFont,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: p.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: rows.length > 30 ? 30 : rows.length,
                itemBuilder: (_, i) {
                  final item = rows[i];
                  final isFocused = item.row.id == focus?.departure.id;
                  return CyberBoardTimelineTile(
                    key: ValueKey('board-timeline:${item.route.id}:${item.row.id}'),
                    route: item.route,
                    departure: item.row,
                    at: item.at,
                    isFocused: isFocused,
                    isFirst: i == 0,
                    isLast: i == (rows.length > 30 ? 29 : rows.length - 1),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}

/// Cyber-Transit Timeline Tile khusus untuk Papan HEDGE (FIDS Kiosk).
/// Menampilkan rel linimasa transit futuristik terbuka dengan pendaran neon,
/// badge status boarding/bersiap/standby, dan countdown timer presisi.
class CyberBoardTimelineTile extends StatelessWidget {
  const CyberBoardTimelineTile({
    super.key,
    required this.route,
    required this.departure,
    required this.at,
    required this.isFocused,
    required this.isFirst,
    required this.isLast,
  });

  final HedgeRoute route;
  final Departure departure;
  final DateTime at;
  final bool isFocused;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final p = context.hedge;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer(
      builder: (context, clockRef, _) {
        final instant = clockRef.watch(clockProvider).value ?? DateTime.now();
        final remaining = at.difference(instant.toUtc());
        final due = remaining <= Duration.zero;
        final imminent = remaining <= const Duration(seconds: 60);
        final activeColor = isFocused
            ? p.cyanInk
            : (due ? p.amberInk : (imminent ? p.amberInk : p.cyanInk));
        final statusColor = due
            ? p.amberInk
            : (imminent ? p.amberInk : (isFocused ? p.cyanInk : p.muted));
        final statusText = due
            ? 'BOARDING'
            : (imminent ? 'BERSIAP' : (isFocused ? 'AKTIF' : 'STANDBY'));

        return RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Kolom Waktu Rencana & Rute (Kiri Rel)
                  SizedBox(
                    width: 58,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            formatMinute(departure.minute),
                            style: TextStyle(
                              fontFamily: HedgeTokens.cyberFont,
                              fontSize: 13,
                              fontWeight: isFocused ? FontWeight.w900 : FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isFocused
                                  ? p.cyanInk
                                  : (isDark ? const Color(0xFFCBD5E1) : p.text),
                              fontFeatures: HedgeTokens.numberFeatures,
                            ),
                          ),
                        ),
                        const SizedBox(height: 1),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            route.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: p.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Rel Transit Vertikal & Node Konsentris Bercahaya (Tengah)
                  SizedBox(
                    width: 28,
                    child: CustomPaint(
                      painter: TransitRailPainter(
                        isFirst: isFirst,
                        isLast: isLast,
                        done: due || (!isFocused && imminent),
                        focused: isFocused,
                        activeColor: activeColor,
                        mutedColor: p.muted,
                        railColor: isDark ? const Color(0xFF1E293B) : p.border,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Konten Unit & Telemetri Kiosk (Kanan Rel - Open Canvas Tanpa Card Kotak)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Baris Atas: Badge Status Kapsul & Metadata Ritase
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Badge Status Kapsul Bercahaya
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: (isFocused || due || imminent)
                                      ? (isDark
                                          ? (due || imminent
                                              ? const Color(0xFF261500)
                                              : const Color(0xFF001F29))
                                          : (due || imminent
                                              ? p.warningSurface
                                              : p.focusSurface))
                                      : (isDark
                                          ? const Color(0xFF0F172A)
                                          : p.raised),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: (isFocused || due || imminent)
                                        ? statusColor
                                        : p.border.withValues(alpha: 0.6),
                                    width: (isFocused || due || imminent) ? 1.2 : 0.8,
                                  ),
                                  boxShadow: (isDark && (isFocused || due || imminent))
                                      ? [
                                          BoxShadow(
                                            color: statusColor.withValues(alpha: 0.35),
                                            blurRadius: 6,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isFocused || due || imminent) ...[
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: statusColor,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        statusText,
                                        style: TextStyle(
                                          fontFamily: HedgeTokens.cyberFont,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Ritase
                              Text(
                                'R${departure.round}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: p.muted,
                                ),
                              ),
                              if (departure.peak)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: p.cyanInk.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: p.cyanInk.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    'PEAK',
                                    style: TextStyle(
                                      fontFamily: HedgeTokens.cyberFont,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                      color: p.cyanInk,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),

                          // Nomor Unit Raksasa
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              departure.unitNumber,
                              style: TextStyle(
                                fontFamily: HedgeTokens.cyberFont,
                                fontSize: 26,
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: isDark ? Colors.white : p.text,
                                fontFeatures: HedgeTokens.numberFeatures,
                                shadows: (isFocused && isDark)
                                    ? [
                                        Shadow(
                                          color: p.cyanInk.withValues(alpha: 0.5),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Kolom Kanan: Countdown Timer Kiosk
                  SizedBox(
                    width: 68,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            formatCountdown(remaining),
                            style: TextStyle(
                              fontFamily: HedgeTokens.cyberFont,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: statusColor,
                              fontFeatures: HedgeTokens.numberFeatures,
                              shadows: ((due || imminent || isFocused) && isDark)
                                  ? [
                                      Shadow(
                                        color: statusColor.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 1),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            due ? 'WAKTU TIBA' : 'HITUNG MUNDUR',
                            style: TextStyle(
                              fontFamily: HedgeTokens.cyberFont,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: p.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
