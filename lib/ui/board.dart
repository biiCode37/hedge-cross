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
        title: const Text('Papan HEDGE'),
        actions: [
          TextButton(
            onPressed: () => setState(() => combined = !combined),
            child: Text(combined ? 'Semua rute' : 'Rute aktif'),
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
                          color: p.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: p.border),
                        ),
                        child: Text(
                          'Tidak ada keberangkatan mendatang',
                          style: Theme.of(context).textTheme.titleLarge,
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Consumer(
                  builder: (context, clockRef, _) {
                    final instant =
                        clockRef.watch(clockProvider).value ?? DateTime.now();
                    final jakarta = instant.toUtc().add(
                      const Duration(hours: 7),
                    );
                    final secStr = jakarta.second.toString().padLeft(2, '0');
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: p.raised,
                        borderRadius: BorderRadius.circular(HedgeTokens.radius),
                        border: Border.all(color: p.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: p.cyanInk),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${serviceDate(instant)} · ${formatMinute(jakarta.hour * 60 + jakarta.minute)}:$secStr WIB',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: p.text,
                                fontFeatures: HedgeTokens.numberFeatures,
                              ),
                            ),
                          ),
                          Icon(Icons.tv_rounded, size: 16, color: p.cyanInk),
                          const SizedBox(width: 6),
                          Text(
                            'FIDS KIOSK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .8,
                              color: p.cyanInk,
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        'WAKTU',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: p.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ARMADA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: p.muted,
                        ),
                      ),
                    ),
                    Text(
                      'STATUS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: p.muted,
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
                  return RepaintBoundary(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isFocused ? p.focusSurface : p.surface,
                        borderRadius: BorderRadius.circular(HedgeTokens.radius),
                        border: Border.all(
                          color: isFocused
                              ? p.cyanInk.withValues(alpha: .6)
                              : p.border,
                          width: isFocused ? 1.5 : 1.0,
                        ),
                        boxShadow: isFocused
                            ? [
                                BoxShadow(
                                  color: p.cyanInk.withValues(alpha: .12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 72,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  formatMinute(item.row.minute),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: p.text,
                                    fontFeatures: HedgeTokens.numberFeatures,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.route.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: p.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.row.unitNumber,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    color: p.text,
                                    letterSpacing: -.3,
                                    fontFeatures: HedgeTokens.numberFeatures,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      'Ritase ${item.row.round}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: p.muted,
                                      ),
                                    ),
                                    if (item.row.peak) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        'PEAK',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: p.cyanInk,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Consumer(
                            builder: (context, clockRef, _) {
                              final instant =
                                  clockRef.watch(clockProvider).value ??
                                  DateTime.now();
                              final remaining =
                                  item.at.difference(instant.toUtc());
                              final due = remaining <= Duration.zero;
                              final imminent =
                                  remaining <= const Duration(seconds: 60);
                              final color = due
                                  ? p.amberInk
                                  : (imminent ? p.cyanInk : p.text);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    due
                                        ? 'BOARDING'
                                        : (imminent ? 'BERSIAP' : 'STANDBY'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: .8,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatCountdown(remaining),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                      fontFeatures: HedgeTokens.numberFeatures,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
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
