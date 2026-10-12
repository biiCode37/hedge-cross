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
import 'schedule_timeline.dart';
import 'telemetry_bar.dart';
import 'alarm_overlay.dart';
import 'alarm_permissions.dart';
import 'permission_gate.dart';
import 'cockpit_components.dart';
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
          const ForegroundAlarmOverlay(),
        ],
      ),
      home: PermissionGate(
        notifications: notifications,
        child: HomeScreen(notifications: notifications),
      ),
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
  Future<int?> _promptGenerate(HedgeRoute route) async {
    int startRound = route.config.startRound;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? const Color(0xFF00E5FF) : context.hedge.cyanInk;
    final p = context.hedge;

    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF0C1017) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? cyan.withValues(alpha: 0.5) : cyan.withValues(alpha: 0.7),
                  width: 1.5,
                ),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cyan.withValues(alpha: 0.4)),
                    ),
                    child: Icon(Icons.event_available, color: cyan, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BUAT JADWAL OPERASIONAL',
                          style: TextStyle(
                            fontFamily: HedgeTokens.cyberFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.5,
                            color: isDark ? Colors.white : p.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${route.name} · ${route.activeUnits.length} Unit Aktif',
                          style: TextStyle(
                            fontFamily: HedgeTokens.cyberFont,
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : p.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Jadwal baru dihitung berdasarkan armada aktif dan konfigurasi rute.',
                    style: TextStyle(
                      fontFamily: HedgeTokens.cyberFont,
                      fontSize: 12,
                      color: isDark ? const Color(0xFFCBD5E1) : p.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF070B12) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cyan.withValues(alpha: isDark ? 0.3 : 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.sync_rounded, size: 16, color: cyan),
                            const SizedBox(width: 6),
                            Text(
                              'MULAI DARI RITASE KE-',
                              style: TextStyle(
                                fontFamily: HedgeTokens.cyberFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 0.6,
                                color: cyan,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF141A24) : Colors.white,
                                foregroundColor: isDark ? Colors.white : p.text,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: cyan.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                              onPressed: startRound > 1
                                  ? () => setDialogState(() => startRound--)
                                  : null,
                              icon: const Icon(Icons.remove, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              constraints: const BoxConstraints(minWidth: 70),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF090E17) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: cyan,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'RIT $startRound',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: HedgeTokens.cyberFont,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 1.0,
                                  color: cyan,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF141A24) : Colors.white,
                                foregroundColor: isDark ? Colors.white : p.text,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: cyan.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                              onPressed: startRound < 99
                                  ? () => setDialogState(() => startRound++)
                                  : null,
                              icon: const Icon(Icons.add, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Putaran: R$startRound s.d. R${startRound + route.config.rounds - 1} (${route.config.rounds} rit)',
                            style: TextStyle(
                              fontFamily: HedgeTokens.cyberFont,
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : p.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontFamily: HedgeTokens.cyberFont,
                      color: isDark ? const Color(0xFF94A3B8) : p.muted,
                    ),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: cyan,
                    foregroundColor: const Color(0xFF070B12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx, startRound),
                  icon: const Icon(Icons.bolt, size: 18),
                  label: const Text(
                    'Generate Jadwal',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> generate(HedgeRoute route, {bool replan = false}) async {
    if (replan) {
      if (!await confirm(
        'Hitung ulang sisa hari?',
        'Rencana yang waktunya sudah lewat dipertahankan. Pengaturan terbaru berlaku setelah menit sekarang. Catatan aktual tetap terpisah.',
      )) {
        return;
      }
      if (await controller.generate(route, replan: true)) {
        setState(() => roundFilter = null);
        toast('Revisi jadwal tersimpan.');
      }
      return;
    }

    final chosenStartRound = await _promptGenerate(route);
    if (chosenStartRound == null) return;

    final targetRoute = route.config.startRound == chosenStartRound
        ? route
        : route.copyWith(
            config: route.config.copyWith(startRound: chosenStartRound),
          );

    if (await controller.generate(targetRoute, replan: false)) {
      setState(() => roundFilter = null);
      toast('Revisi jadwal tersimpan (mulai Rit $chosenStartRound).');
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
        unawaited(_syncNativeAlarms());
      }
    });
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final p = context.hedge;
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
    return Scaffold(
      appBar: AvionicsTopBar(
        activeRouteName: route?.name ?? '',
        onTvBoard: workspace.routes.any((r) => r.schedule != null)
            ? () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const BoardScreen(),
                ),
              )
            : null,
        onSettings: () => _settings(workspace),
        isSaving: state.saving,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (state.saving) const LinearProgressIndicator(minHeight: 2),

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
                    final isSelected = route?.id == r.id;
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final activeCyan = isDark ? const Color(0xFF00E5FF) : p.cyanInk;
                    return ChoiceChip(
                      selected: isSelected,
                      avatar: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color(r.color),
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Color(r.color),
                                    blurRadius: 4,
                                    spreadRadius: 0.5,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      label: Text('${r.name}${r.dirty ? ' •' : ''}'),
                      labelStyle: TextStyle(
                        fontFamily: HedgeTokens.cyberFont,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isSelected
                            ? (isDark ? Colors.white : activeCyan)
                            : (isDark ? const Color(0xFF94A3B8) : p.muted),
                      ),
                      backgroundColor: isDark ? const Color(0xFF080C14) : p.surface,
                      selectedColor: isDark
                          ? activeCyan.withValues(alpha: 0.18)
                          : p.focusSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                          color: isSelected
                              ? activeCyan.withValues(alpha: isDark ? 0.85 : 0.9)
                              : (isDark ? const Color(0xFF1E293B) : p.border),
                          width: isSelected ? 1.3 : 1.0,
                        ),
                      ),
                      showCheckmark: false,
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
          : CockpitMfdNavBar(
              selectedIndex: destination,
              onDestinationSelected: (i) => setState(() => destination = i),
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
                currentRound: roundFilter ??
                    (focus?.departure.round ??
                        (revision.departures.isNotEmpty
                            ? revision.departures.first.round
                            : 1)),
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
                      final d = focus.departure;
                      if (await controller.record(
                        focus.revision,
                        d,
                        'departed',
                      )) {
                        if (!mounted) return;
                        showDepartureUndoSnackBar(
                          context,
                          unitNumber: d.unitNumber,
                          onUndo: () => controller.unrecord(d.id),
                        );
                      }
                    },
                  )
                : CockpitFrame(
                    title: 'JADWAL TERSIMPAN',
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          revision == null
                              ? 'Siap menyusun'
                              : 'Layanan selesai',
                          style: TextStyle(
                            fontFamily: HedgeTokens.cyberFont,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : p.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${route.activeUnits.length} unit · ${route.config.rounds} ritase',
                          style: TextStyle(
                            fontFamily: HedgeTokens.cyberFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: p.muted,
                          ),
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
                    if (workspace.hasDeparted(d.id)) {
                      if (await confirm(
                        'Batalkan keberangkatan unit ${d.unitNumber}?',
                        'Status keberangkatan aktual akan dihapus kembali.',
                      )) {
                        if (await controller.unrecord(d.id)) {
                          toast('Status keberangkatan unit ${d.unitNumber} dibatalkan.');
                        }
                      }
                    } else if (await confirm(
                      'Unit ${d.unitNumber} sudah berangkat?',
                      'Catat keberangkatan aktual sekarang untuk rencana ${formatMinute(d.minute)}.',
                    )) {
                      if (await controller.record(revision, d, 'departed')) {
                        if (!mounted) return;
                        showDepartureUndoSnackBar(
                          context,
                          unitNumber: d.unitNumber,
                          onUndo: () => controller.unrecord(d.id),
                        );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? const Color(0xFF00E5FF) : context.hedge.cyanInk;
    final amber = isDark ? const Color(0xFFFF9800) : context.hedge.amberInk;
    final p = context.hedge;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: TextStyle(
                    fontFamily: HedgeTokens.cyberFont,
                    fontSize: 14,
                    color: isDark ? Colors.white : p.text,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: cyan, size: 20),
                    labelText: 'Cari nomor unit',
                    labelStyle: TextStyle(
                      fontFamily: HedgeTokens.cyberFont,
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : p.muted,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0A0F18) : p.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: cyan.withValues(alpha: isDark ? 0.3 : 0.4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: cyan, width: 1.5),
                    ),
                  ),
                  onChanged: (v) => setState(() => fleetQuery = v),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                width: 48,
                child: IconButton.filled(
                  tooltip: 'Tambah unit',
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? cyan.withValues(alpha: 0.2) : p.focusSurface,
                    foregroundColor: cyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: cyan.withValues(alpha: isDark ? 0.7 : 0.9),
                        width: 1.2,
                      ),
                    ),
                  ),
                  onPressed: () async {
                    final number = await ask('Tambah unit', hint: 'Nomor unit');
                    if (number != null) await controller.addUnit(route, number);
                  },
                  icon: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const CockpitStatusBadge(
                label: 'FLEET MANIFEST',
                isAmber: false,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${route.activeUnits.length} aktif / ${route.units.length} unit',
                  style: TextStyle(
                    fontFamily: HedgeTokens.cyberFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                    color: isDark ? const Color(0xFFCBD5E1) : p.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            itemCount: units.length,
            itemBuilder: (_, i) {
              final unit = units[i];
              return CockpitManifestCard(
                key: ValueKey('unit-card-${unit.id}'),
                isAmber: !unit.active,
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF070B12) : p.raised,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: unit.active
                          ? cyan.withValues(alpha: isDark ? 0.6 : 0.8)
                          : amber.withValues(alpha: isDark ? 0.4 : 0.6),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    size: 20,
                    color: unit.active ? cyan : amber,
                  ),
                ),
                title: Text(
                  'Unit ${unit.number}',
                  style: TextStyle(
                    fontFamily: HedgeTokens.cyberFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white : p.text,
                  ),
                ),
                subtitle: Text(
                  unit.active ? 'Aktif untuk jadwal baru' : 'Tidak aktif',
                  style: TextStyle(
                    fontFamily: HedgeTokens.cyberFont,
                    fontSize: 11.5,
                    color: unit.active
                        ? (isDark ? const Color(0xFF94A3B8) : p.muted)
                        : (isDark ? amber.withValues(alpha: 0.8) : p.amberInk),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: unit.active,
                      activeTrackColor: cyan.withValues(alpha: 0.5),
                      activeThumbColor: cyan,
                      onChanged: (v) =>
                          controller.setUnitActive(route, unit, v),
                    ),
                    IconButton(
                      tooltip: 'Hapus unit',
                      icon: Icon(
                        Icons.delete_outline,
                        color: isDark ? const Color(0xFF94A3B8) : p.muted,
                        size: 20,
                      ),
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _order(HedgeRoute route) {
    final units = route.activeUnits;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amber = isDark ? const Color(0xFFFF9800) : context.hedge.amberInk;
    final p = context.hedge;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CockpitStatusBadge(
                label: 'ROTATION ORDER',
                isAmber: true,
              ),
              const SizedBox(height: 4),
              Text(
                'Tarik unit atau gunakan panah. Urutan berlaku setelah jadwal dibuat ulang.',
                style: TextStyle(
                  fontFamily: HedgeTokens.cyberFont,
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFF94A3B8) : p.muted,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            itemCount: units.length,
            onReorder: (old, next) {
              if (next > old) next--;
              _move(route, units, old, next);
            },
            itemBuilder: (_, i) => CockpitManifestCard(
              key: ValueKey(units[i].id),
              isAmber: true,
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141008) : p.warningSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: amber.withValues(alpha: isDark ? 0.6 : 0.8),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontFamily: HedgeTokens.cyberFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: amber,
                  ),
                ),
              ),
              title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Unit ${units[i].number}',
                  style: TextStyle(
                    fontFamily: HedgeTokens.cyberFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white : p.text,
                  ),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Naik',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: i == 0
                        ? null
                        : () => _move(route, units, i, i - 1),
                    icon: Icon(
                      Icons.arrow_upward,
                      size: 20,
                      color: i == 0
                          ? (isDark ? const Color(0xFF334155) : p.border)
                          : (isDark ? Colors.white : p.text),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Turun',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: i == units.length - 1
                        ? null
                        : () => _move(route, units, i, i + 1),
                    icon: Icon(
                      Icons.arrow_downward,
                      size: 20,
                      color: i == units.length - 1
                          ? (isDark ? const Color(0xFF334155) : p.border)
                          : (isDark ? Colors.white : p.text),
                    ),
                  ),
                  ReorderableDragStartListener(
                    index: i,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.drag_handle,
                        color: isDark ? const Color(0xFF94A3B8) : p.muted,
                      ),
                    ),
                  ),
                ],
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

  Widget _routes(Workspace workspace) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? const Color(0xFF00E5FF) : context.hedge.cyanInk;
    final amber = isDark ? const Color(0xFFFF9800) : context.hedge.amberInk;
    final p = context.hedge;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? cyan.withValues(alpha: 0.22) : p.focusSurface,
                    foregroundColor: cyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: cyan.withValues(alpha: isDark ? 0.8 : 0.9),
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  ),
                  onPressed: _addRoute,
                  icon: const Icon(Icons.add, size: 16),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Tambah rute',
                      style: TextStyle(
                        fontFamily: HedgeTokens.cyberFont,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: amber,
                    side: BorderSide(
                      color: amber.withValues(alpha: isDark ? 0.7 : 0.85),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  ),
                  onPressed: () async {
                    final failures = await controller.generateAll();
                    toast(
                      failures.isEmpty
                          ? 'Jadwal semua rute aktif tersimpan.'
                          : failures.join('\n'),
                    );
                  },
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Buat semua',
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const CockpitStatusBadge(
                label: 'ROUTE SECTORS',
                isAmber: false,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${workspace.routes.length} sektor terkonfigurasi',
                  style: TextStyle(
                    fontFamily: HedgeTokens.cyberFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                    color: isDark ? const Color(0xFFCBD5E1) : p.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            itemCount: workspace.routes.length,
            itemBuilder: (_, i) {
              final r = workspace.routes[i];
              return CockpitManifestCard(
                key: ValueKey('route-card-${r.id}'),
                isAmber: !r.participates,
                onTap: () {
                  setState(() => roundFilter = null);
                  controller.selectRoute(r.id);
                  setState(() => destination = 0);
                },
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF070B12) : p.raised,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Color(r.color).withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.alt_route,
                    size: 20,
                    color: Color(r.color),
                  ),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        r.name,
                        style: TextStyle(
                          fontFamily: HedgeTokens.cyberFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.white : p.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!r.participates) ...[
                      const SizedBox(width: 8),
                      const CockpitStatusBadge(
                        label: 'NONAKTIF',
                        isAmber: true,
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  '${r.activeUnits.length} unit · ${r.config.start}–${r.config.end}',
                  style: TextStyle(
                    fontFamily: HedgeTokens.cyberFont,
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : p.muted,
                  ),
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
              );
            },
          ),
        ),
      ],
    );
  }
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
    await _syncNativeAlarms();
    if (!mounted) return;
    final currentRoute = ref
        .read(workspaceProvider)
        .workspace
        .routes
        .firstWhere((r) => r.id == route.id, orElse: () => route);
    final result = await showModalBottomSheet<HedgeRoute>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ConfigurationSheet(route: currentRoute),
    );
    if (result != null) await controller.updateRoute(result);
  }
}

String countdown(Duration duration) => formatCountdown(duration);
