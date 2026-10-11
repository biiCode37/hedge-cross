import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/notification_service.dart';
import 'design_system.dart';

/// Gatekeeper component that enforces mandatory Android permissions before granting
/// access to [HomeScreen]. Displays a loading state during checks and blocks access
/// if any of the 4 vital permissions (notifications, exact alarm, full-screen intent, overlay)
/// are missing.
class PermissionGate extends ConsumerStatefulWidget {
  const PermissionGate({
    super.key,
    required this.child,
    this.notifications,
  });

  final Widget child;
  final NotificationService? notifications;

  @override
  ConsumerState<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends ConsumerState<PermissionGate>
    with WidgetsBindingObserver {
  bool _checking = true;
  bool _requestedNotificationsOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_checkPermissions());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkPermissions(silent: true));
    }
  }

  Future<void> _checkPermissions({bool silent = false}) async {
    final service = widget.notifications;
    if (service == null || !service.isAndroid) {
      if (mounted) setState(() => _checking = false);
      return;
    }
    if (!silent && mounted) {
      setState(() => _checking = true);
    }
    try {
      await service.refreshStatus();
      final current = service.device.value;
      if (!current.notifications && !_requestedNotificationsOnce) {
        _requestedNotificationsOnce = true;
        await service.requestPermission();
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _checking = false);
    }
  }

  bool _isAllGranted(AlarmDeviceStatus d) {
    return d.notifications && d.exact && d.fullScreen && d.overlay;
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.notifications;
    if (service == null || !service.isAndroid) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = context.hedge;

    if (_checking) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF070B12) : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: p.cyanInk.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: p.cyanInk.withValues(alpha: 0.4), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: p.cyanInk.withValues(alpha: isDark ? 0.25 : 0.1),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(Icons.shield_rounded, size: 38, color: p.cyanInk),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'HEDGE',
                    style: TextStyle(
                      fontFamily: HedgeTokens.cyberFont,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: isDark ? Colors.white : p.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HEADWAY GENERATOR BY MIKROTRANS UTARA',
                    style: TextStyle(
                      fontFamily: HedgeTokens.cyberFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: p.amberInk,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: AlwaysStoppedAnimation<Color>(p.cyanInk),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Memeriksa Perizinan Sistem...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Memverifikasi izin notifikasi, alarm tepat, layar penuh, dan overlay...',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ValueListenableBuilder<AlarmDeviceStatus>(
      valueListenable: service.device,
      builder: (context, d, _) {
        if (_isAllGranted(d)) {
          return widget.child;
        }

        final permissions = [
          (
            id: 'notifications',
            title: 'Izin Notifikasi',
            desc: 'Menampilkan pengingat alarm keberangkatan dan status layanan.',
            icon: Icons.notifications_active_rounded,
            granted: d.notifications,
            onFix: () async {
              await service.requestPermission();
              await service.openPermission('notifications');
            },
          ),
          (
            id: 'exact',
            title: 'Izin Alarm Tepat (Exact Alarm)',
            desc: 'Menjamin alarm berdering tepat detik jadwal tanpa delay Doze Mode.',
            icon: Icons.alarm_on_rounded,
            granted: d.exact,
            onFix: () => service.openPermission('exact'),
          ),
          (
            id: 'fullScreen',
            title: 'Izin Alert Layar Penuh',
            desc: 'Memunculkan pop-up saat layar smartphone terkunci atau mati di saku.',
            icon: Icons.fullscreen_rounded,
            granted: d.fullScreen,
            onFix: () => service.openPermission('fullScreen'),
          ),
          (
            id: 'overlay',
            title: 'Tampil di Atas Aplikasi Lain',
            desc: 'Memunculkan dialog alert saat dispatcher membuka aplikasi lain.',
            icon: Icons.layers_rounded,
            granted: d.overlay,
            onFix: () => service.openPermission('overlay'),
          ),
        ];

        final missingCount = permissions.where((p) => !p.granted).length;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF070B12) : const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Warning Header Banner
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF141A24)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: p.amberInk.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: p.amberInk.withValues(alpha: isDark ? 0.15 : 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: p.amberInk.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.lock_clock_rounded,
                                      color: p.amberInk,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: p.amberInk.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'AKSES DIBLOKIR — $missingCount IZIN BELUM AKTIF',
                                            style: TextStyle(
                                              fontFamily: HedgeTokens.cyberFont,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.6,
                                              color: p.amberInk,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Perizinan Operasional Wajib',
                                          style: TextStyle(
                                            fontFamily: HedgeTokens.cyberFont,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: isDark ? Colors.white : p.text,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Aplikasi HEDGE mewajibkan 4 perizinan sistem Android berikut aktif untuk menjamin alarm jadwal headway dan keberangkatan armada tidak tertinggal di lapangan.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'DAFTAR PERIZINAN SISTEM',
                          style: TextStyle(
                            fontFamily: HedgeTokens.cyberFont,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: isDark ? p.cyanInk : const Color(0xFF0284C7),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // List of Permission Cards
                        for (final item in permissions)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0C1017)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: item.granted
                                    ? p.success.withValues(alpha: 0.4)
                                    : p.amberInk.withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: item.granted
                                        ? p.success.withValues(alpha: 0.12)
                                        : p.amberInk.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 24,
                                    color: item.granted ? p.success : p.amberInk,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : p.text,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: item.granted
                                                  ? p.success.withValues(alpha: 0.15)
                                                  : p.amberInk.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.granted ? 'DIIZINKAN' : 'BELUM AKTIF',
                                              style: TextStyle(
                                                fontFamily: HedgeTokens.cyberFont,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.5,
                                                color: item.granted ? p.success : p.amberInk,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.desc,
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.35,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                      if (!item.granted) ...[
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: p.amberInk,
                                              foregroundColor: Colors.black,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: item.onFix,
                                            icon: const Icon(Icons.settings_outlined, size: 16),
                                            label: const Text(
                                              'Beri Izin Sekarang',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0C1017) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? const Color(0xFF1E293B) : p.border,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.cyanInk,
                        foregroundColor: Colors.black,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _checkPermissions(),
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: const Text(
                        'PERIKSA ULANG SEMUA IZIN',
                        style: TextStyle(
                          fontFamily: HedgeTokens.cyberFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
