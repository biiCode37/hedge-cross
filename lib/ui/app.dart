import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../application/notification_service.dart';
import '../application/workspace_controller.dart';
import '../data/export_service.dart';
import '../data/import_service.dart';
import '../domain/models.dart';
import 'configuration.dart';
import 'design_system.dart';
import 'dispatch_components.dart';
import 'telemetry_bar.dart';
import 'alarm_overlay.dart';
import 'alarm_permissions.dart';
import '../domain/alarm_plan.dart';
import '../application/dispatch_focus.dart';
part 'data_actions.dart';
part 'board.dart';

class HedgeApp extends ConsumerWidget {
  const HedgeApp({super.key, this.notifications});
  final NotificationService? notifications;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(workspaceProvider.select((s) => s.workspace.theme));
    return MaterialApp(
      title: 'HEDGE',
      themeAnimationDuration:
          (MediaQuery.maybeOf(context)?.disableAnimations ??
              View.of(
                context,
              ).platformDispatcher.accessibilityFeatures.disableAnimations)
          ? Duration.zero
          : HedgeTokens.motion,
      debugShowCheckedModeBanner: false,
      theme: hedgeTheme(Brightness.light),
      darkTheme: hedgeTheme(Brightness.dark),
      themeMode: theme == 'light'
          ? ThemeMode.light
          : theme == 'system'
          ? ThemeMode.system
          : ThemeMode.dark,
      locale: const Locale('id'),
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => Stack(
        children: [
          child!,
          if (notifications?.isAndroid != true) const ForegroundAlarmOverlay(),
        ],
      ),
      home: HomeScreen(notifications: notifications),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.notifications});
  final NotificationService? notifications;
  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  int destination = 0;
  String fleetQuery = '';
  int? roundFilter;
  int lastMinute = -1;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool syncingNative = false;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_syncNativeAlarms());
  }

  Future<void> _syncNativeAlarms() async {
    final service = widget.notifications;
    if (service == null || syncingNative) return;
    syncingNative = true;
    try {
      final actions = acceptedNativeAlarmActions(
        ref.read(workspaceProvider).workspace,
        await service.readNativeActions(),
      );
      if (actions.isNotEmpty && await controller.applyAlarmActions(actions)) {
        await service.acceptNativeActions(actions);
      }
      await service.refreshStatus();
      await service.reconcile(ref.read(workspaceProvider).workspace);
    } catch (error) {
      service.status.value = 'Tindakan alarm belum tersimpan: $error';
    } finally {
      syncingNative = false;
    }
  }

  WorkspaceController get controller => ref.read(workspaceProvider.notifier);
  void toast(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> operation(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      toast('$error');
    }
  }

  Future<String?> ask(
    String title, {
    String initial = '',
    String hint = '',
  }) async {
    final field = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: field,
          autofocus: true,
          decoration: InputDecoration(labelText: hint.isEmpty ? title : hint),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, field.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    field.dispose();
    return result;
  }

  Future<bool> confirm(String title, String detail) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(detail)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> generate(HedgeRoute route, {bool replan = false}) async {
    if (route.schedule != null &&
        !await confirm(
          replan ? 'Hitung ulang sisa hari?' : 'Buat revisi jadwal baru?',
          replan
              ? 'Rencana yang waktunya sudah lewat dipertahankan. Pengaturan terbaru berlaku setelah menit sekarang. Catatan aktual tetap terpisah.'
              : 'Jadwal baru menggunakan pengaturan dan armada aktif. Revisi sebelumnya disimpan sebagai histori.',
        )) {
      return;
    }
    if (await controller.generate(route, replan: replan)) {
      setState(() => roundFilter = null);
      toast('Revisi jadwal tersimpan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspaceProvider);
    final workspace = state.workspace;
    final route = workspace.activeRoute;

    ref.listen(workspaceProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        toast(next.error!);
      }
      if (!next.saving && next.workspace != previous?.workspace) {
        unawaited(
          widget.notifications?.reconcile(next.workspace) ?? Future.value(),
        );
      }
    });
    ref.listen(clockProvider, (previous, next) {
      final instant = next.value;
      if (instant != null && instant.minute != lastMinute) {
        lastMinute = instant.minute;
        if (widget.notifications != null) {
          unawaited(
            widget.notifications!.reconcile(
              ref.read(workspaceProvider).workspace,
            ),
          );
        }
      }
    });
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final content = route == null
        ? _empty(
            'Belum ada rute',
            'Tambahkan rute untuk menyusun jadwal.',
            FilledButton.icon(
              onPressed: _addRoute,
              icon: const Icon(Icons.add),
              label: const Text('Tambah rute'),
            ),
          )
        : switch (destination) {
            0 => _schedule(workspace, route),
            1 => _fleet(route),
            2 => _order(route),
            _ => _routes(workspace),
          };
    final p = context.hedge;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/hedge-logo.jpg',
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'HEDGE',
                    style: TextStyle(
                      fontFamily: HedgeTokens.cyberFont,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 17,
                      color: p.text,
                    ),
                  ),
                  Text(
                    'Headway Generator',
                    style: TextStyle(
                      fontSize: 10,
                      color: p.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'By Mikrotrans Utara',
                    style: TextStyle(
                      fontSize: 9,
                      color: p.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final now = ref.watch(clockProvider).value ?? DateTime.now();
              final timeStr =
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontFamily: HedgeTokens.cyberFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: p.cyanInk,
                      fontFeatures: HedgeTokens.numberFeatures,
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Papan keberangkatan',
            onPressed: workspace.routes.any((r) => r.schedule != null)
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const BoardScreen(),
                    ),
                  )
                : null,
            icon: const Icon(Icons.tv, size: 20),
          ),
          IconButton(
            tooltip: 'Pengaturan & backup',
            onPressed: () => _settings(workspace),
            icon: const Icon(Icons.tune, size: 20),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (state.saving) const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _date(workspace),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(workspace.date, maxLines: 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.offline_bolt,
                    size: 16,
                    color: context.hedge.cyanInk,
                  ),
                  const SizedBox(width: 4),
                  const Text('Lokal', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            if (workspace.routes.isNotEmpty)
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: workspace.routes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final r = workspace.routes[i];
                    return ChoiceChip(
                      selected: route?.id == r.id,
                      avatar: CircleAvatar(
                        backgroundColor: Color(r.color),
                        radius: 5,
                      ),
                      label: Text('${r.name}${r.dirty ? ' •' : ''}'),
                      onSelected: state.saving
                          ? null
                          : (_) {
                              setState(() => roundFilter = null);
                              controller.selectRoute(r.id);
                            },
                    );
                  },
                ),
              ),
            Expanded(
              child: Row(
                children: [
                  if (wide)
                    NavigationRail(
                      selectedIndex: destination,
                      onDestinationSelected: (i) =>
                          setState(() => destination = i),
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.schedule),
                          label: Text('Jadwal'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.directions_bus),
                          label: Text('Armada'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.reorder),
                          label: Text('Urutan'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.alt_route),
                          label: Text('Rute'),
                        ),
                      ],
                    ),
                  Expanded(child: content),
                ],
              ),
            ),
            Consumer(
              builder: (context, clockRef, _) {
                final now =
                    clockRef.watch(clockProvider).value ?? DateTime.now();
                return _alarm(workspace, now);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: destination,
              onDestinationSelected: (i) => setState(() => destination = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.schedule),
                  label: 'Jadwal',
                ),
                NavigationDestination(
                  icon: Icon(Icons.directions_bus),
                  label: 'Armada',
                ),
                NavigationDestination(
                  icon: Icon(Icons.reorder),
                  label: 'Urutan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.alt_route),
                  label: 'Rute',
                ),
              ],
            ),
    );
  }

  Widget _empty(String title, String detail, Widget action) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.route, size: 48, color: context.hedge.amberInk),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(detail, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          action,
        ],
      ),
    ),
  );
  Widget _schedule(Workspace workspace, HedgeRoute route) {
    final revision = route.schedule;
    final focus = ref.watch(dispatchFocusProvider(route.id));
    final rows =
        revision?.departures
            .where((d) => roundFilter == null || d.round == roundFilter)
            .toList() ??
        <Departure>[];
    final p = context.hedge;
    return CustomScrollView(
      key: PageStorageKey('schedule:${route.id}'),
      slivers: [
        if (revision != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
              child: FleetTelemetryPillBar(
                activeUnits: route.activeUnits.length,
                currentRound: focus?.departure.round ??
                    (revision.departures.isNotEmpty
                        ? revision.departures.first.round
                        : 1),
                totalRounds: route.config.rounds,
                headwayMinutes: focus?.departure.nextGap ??
                    (revision.departures.isNotEmpty
                        ? (revision.departures.first.nextGap ?? 3)
                        : 3),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
            child: focus != null
                ? DepartureFocusPanel(
                    focus: focus,
                    onDispatch: () async {
                      if (await controller.record(
                        focus.revision,
                        focus.departure,
                        'departed',
                      )) {
                        toast(
                          'Keberangkatan unit ${focus.departure.unitNumber} tercatat.',
                        );
                      }
                    },
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: p.surface,
                      border: Border.all(color: p.border),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'JADWAL TERSIMPAN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: p.cyanInk,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          revision == null
                              ? 'Siap menyusun'
                              : 'Layanan selesai',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${route.activeUnits.length} unit · ${route.config.rounds} ritase',
                          style: TextStyle(color: p.muted),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        if (route.dirty ||
            (revision != null && revision.date != workspace.date))
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.warningSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: p.amberInk, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        route.dirty
                            ? 'Pengaturan berubah. Jadwal tersimpan belum diperbarui.'
                            : 'Jadwal bertanggal ${revision!.date}. Tanggal pilihan: ${workspace.date}.',
                        style: TextStyle(fontSize: 12, color: p.amberInk),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: ref.watch(workspaceProvider).saving
                      ? null
                      : () => generate(route),
                  icon: const Icon(Icons.event_available, size: 18),
                  label: const Text('Buat jadwal'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _config(route),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Atur'),
                ),
                if (revision != null)
                  PopupMenuButton<String>(
                    tooltip: 'Opsi jadwal',
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (action) {
                      if (action == 'replan') {
                        generate(route, replan: true);
                      } else {
                        _export(workspace, route);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'replan',
                        child: Text('Hitung ulang sisa hari'),
                      ),
                      PopupMenuItem(
                        value: 'export',
                        child: Text('Ekspor jadwal'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (revision == null)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Atur jam operasional dan armada, lalu buat jadwal.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${revision.departures.length} keberangkatan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: p.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<int?>(
                      isExpanded: true,
                      value: roundFilter,
                      hint: const Text('Semua ritase'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Semua ritase'),
                        ),
                        for (final r
                            in (revision.departures
                                .map((d) => d.round)
                                .toSet()
                                .toList()
                              ..sort()))
                          DropdownMenuItem(value: r, child: Text('Ritase $r')),
                      ],
                      onChanged: (v) => setState(() => roundFilter = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final d = rows[i];
                return ScheduleDepartureTile(
                  key: ValueKey('schedule-row:${d.id}'),
                  departure: d,
                  done: workspace.hasDeparted(d.id),
                  focused: d.id == focus?.departure.id,
                  frozen: d.ordinal <= revision.frozenCount,
                  isFirst: i == 0,
                  isLast: i == rows.length - 1,
                  onRecord: () async {
                    if (await confirm(
                      'Unit ${d.unitNumber} sudah berangkat?',
                      'Catat keberangkatan aktual sekarang untuk rencana ${formatMinute(d.minute)}.',
                    )) {
                      if (await controller.record(revision, d, 'departed')) {
                        toast('Keberangkatan aktual tercatat.');
                      }
                    }
                  },
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Revisi ${revision.id.substring(0, revision.id.length > 12 ? 12 : revision.id.length)} · ${revision.date}',
                style: TextStyle(fontSize: 11, color: p.muted),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _fleet(HedgeRoute route) {
    final units = route.units
        .where((u) => u.number.toLowerCase().contains(fleetQuery.toLowerCase()))
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Cari nomor unit',
                  ),
                  onChanged: (v) => setState(() => fleetQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Tambah unit',
                onPressed: () async {
                  final number = await ask('Tambah unit', hint: 'Nomor unit');
                  if (number != null) await controller.addUnit(route, number);
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${route.activeUnits.length} aktif / ${route.units.length} unit',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: units.length,
            itemBuilder: (_, i) {
              final unit = units[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_bus),
                  title: Text('Unit ${unit.number}'),
                  subtitle: Text(
                    unit.active ? 'Aktif untuk jadwal baru' : 'Tidak aktif',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: unit.active,
                        onChanged: (v) =>
                            controller.setUnitActive(route, unit, v),
                      ),
                      IconButton(
                        tooltip: 'Hapus unit',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          if (await confirm(
                            'Hapus unit ${unit.number}?',
                            'Jadwal tersimpan tetap memuat histori unit ini.',
                          )) {
                            await controller.deleteUnit(route, unit.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _order(HedgeRoute route) {
    final units = route.activeUnits;
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Tarik unit atau gunakan panah. Urutan berlaku setelah jadwal dibuat ulang.',
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.all(12),
            itemCount: units.length,
            onReorder: (old, next) {
              if (next > old) next--;
              _move(route, units, old, next);
            },
            itemBuilder: (_, i) => Card(
              key: ValueKey(units[i].id),
              child: ListTile(
                leading: Text(
                  '${i + 1}',
                  style: TextStyle(fontSize: 22, color: context.hedge.amberInk),
                ),
                title: Text('Unit ${units[i].number}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Naik',
                      onPressed: i == 0
                          ? null
                          : () => _move(route, units, i, i - 1),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      tooltip: 'Turun',
                      onPressed: i == units.length - 1
                          ? null
                          : () => _move(route, units, i, i + 1),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    ReorderableDragStartListener(
                      index: i,
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _move(HedgeRoute route, List<FleetUnit> units, int from, int to) {
    final ids = units.map((u) => u.id).toList();
    ids.insert(to, ids.removeAt(from));
    controller.reorder(route, ids);
  }

  Future<void> _addRoute() async {
    final name = await ask('Tambah rute', hint: 'Nama rute, misalnya JAK.88');
    if (name != null) {
      await controller.addRoute(name);
      setState(() => destination = 3);
    }
  }

  Widget _routes(Workspace workspace) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _addRoute,
                icon: const Icon(Icons.add),
                label: const Text('Tambah rute'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () async {
                final failures = await controller.generateAll();
                toast(
                  failures.isEmpty
                      ? 'Jadwal semua rute aktif tersimpan.'
                      : failures.join('\n'),
                );
              },
              child: const Text('Buat semua'),
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: workspace.routes.length,
          itemBuilder: (_, i) {
            final r = workspace.routes[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: context.hedge.raised,
                  child: Icon(Icons.alt_route, color: context.hedge.cyanInk),
                ),
                title: Text(r.name),
                subtitle: Text(
                  '${r.activeUnits.length} unit · ${r.config.start}–${r.config.end}',
                ),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Opsi rute',
                  onSelected: (action) async {
                    switch (action) {
                      case 'rename':
                        final name = await ask(
                          'Ubah nama rute',
                          initial: r.name,
                        );
                        if (name != null && name.trim().isNotEmpty) {
                          if (workspace.routes.any(
                            (e) =>
                                e.id != r.id &&
                                e.name.toLowerCase() ==
                                    name.trim().toLowerCase(),
                          )) {
                            toast('Nama rute sudah digunakan.');
                          } else {
                            await controller.updateRoute(
                              r.copyWith(name: name.trim()),
                            );
                          }
                        }
                      case 'clone':
                        await controller.cloneRoute(r);
                      case 'hide':
                        await controller.updateRoute(
                          r.copyWith(participates: !r.participates),
                        );
                      case 'delete':
                        if (await confirm(
                          'Arsipkan ${r.name}?',
                          'Histori revisi dan catatan aktual tetap disimpan di database dan backup.',
                        )) {
                          await controller.deleteRoute(r.id);
                        }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Text('Ubah nama'),
                    ),
                    const PopupMenuItem(
                      value: 'clone',
                      child: Text('Duplikat'),
                    ),
                    PopupMenuItem(
                      value: 'hide',
                      child: Text(
                        r.participates
                            ? 'Keluarkan dari papan gabungan'
                            : 'Masukkan ke papan gabungan',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Arsipkan rute'),
                    ),
                  ],
                ),
                onTap: () {
                  controller.selectRoute(r.id);
                  setState(() => destination = 0);
                },
              ),
            );
          },
        ),
      ),
    ],
  );
  Widget _alarm(Workspace workspace, DateTime now) {
    final items =
        <({HedgeRoute route, ScheduleRevision revision, Departure row})>[];
    for (final r in workspace.routes.where(
      (r) =>
          r.participates &&
          r.alarmEnabled &&
          r.alerts.departure &&
          r.alerts.banner &&
          !r.alerts.fullScreen &&
          r.schedule != null,
    )) {
      final revision = r.schedule!;
      for (final row in revision.departures) {
        final elapsed = now
            .toUtc()
            .difference(plannedInstant(revision.date, row.minute))
            .inSeconds;
        if (elapsed >= 0 &&
            elapsed < r.alarmDuration &&
            !workspace.hasAcknowledged(row.id) &&
            !workspace.hasDeparted(row.id)) {
          items.add((route: r, revision: revision, row: row));
        }
      }
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      color: context.hedge.warningSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items
            .take(3)
            .map(
              (item) => Row(
                children: [
                  const Icon(Icons.notifications_active),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.route.name} · Unit ${item.row.unitNumber}\nWaktu berangkat ${formatMinute(item.row.minute)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        controller.record(item.revision, item.row, 'departed'),
                    child: const Text('Sudah Berangkat'),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _config(HedgeRoute route) async {
    final result = await showModalBottomSheet<HedgeRoute>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ConfigurationSheet(route: route),
    );
    if (result != null) await controller.updateRoute(result);
  }

  Future<void> _date(Workspace workspace) async {
    final result = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(workspace.date),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (result != null) {
      await controller.setDate(
        '${result.year}-${result.month.toString().padLeft(2, '0')}-${result.day.toString().padLeft(2, '0')}',
      );
    }
  }
}

String countdown(Duration duration) => formatCountdown(duration);
