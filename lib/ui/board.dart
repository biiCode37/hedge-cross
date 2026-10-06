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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Consumer(
                  builder: (context, clockRef, _) {
                    final instant =
                        clockRef.watch(clockProvider).value ?? DateTime.now();
                    final jakarta = instant.toUtc().add(
                      const Duration(hours: 7),
                    );
                    return Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: p.muted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${serviceDate(instant)} · ${formatMinute(jakarta.hour * 60 + jakarta.minute)} WIB',
                            style: TextStyle(fontSize: 12, color: p.muted),
                          ),
                        ),
                        Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: p.cyanInk,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Layar aktif',
                          style: TextStyle(fontSize: 12, color: p.muted),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: rows.length > 30 ? 30 : rows.length,
                itemBuilder: (_, i) {
                  final item = rows[i];
                  return RepaintBoundary(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: item.row.id == focus?.departure.id
                              ? p.cyanInk
                              : p.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.row.unitNumber,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: p.text,
                                    fontFeatures: HedgeTokens.numberFeatures,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.route.name} · ${formatMinute(item.row.minute)} · R${item.row.round}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: p.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Consumer(
                            builder: (context, clockRef, _) {
                              final instant =
                                  clockRef.watch(clockProvider).value ??
                                  DateTime.now();
                              return Text(
                                formatCountdown(
                                  item.at.difference(instant.toUtc()),
                                ),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: p.cyanInk,
                                  fontFeatures: HedgeTokens.numberFeatures,
                                ),
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
