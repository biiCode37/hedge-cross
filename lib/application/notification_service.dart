import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as zones;
import 'package:timezone/timezone.dart' as tz;
import '../domain/models.dart';
import '../domain/alarm_plan.dart';

class AlarmDeviceStatus {
  const AlarmDeviceStatus({
    this.notifications = false,
    this.exact = false,
    this.fullScreen = false,
    this.pending = 0,
  });
  final bool notifications, exact, fullScreen;
  final int pending;
}

class NotificationService {
  NotificationService({bool? android, DateTime Function()? now})
    : isAndroid = android ?? Platform.isAndroid,
      now = now ?? DateTime.now;
  static const channel = MethodChannel('id.mikrotrans.hedge/alarms');
  final bool isAndroid;
  final DateTime Function() now;
  final plugin = FlutterLocalNotificationsPlugin();
  final status = ValueNotifier<String>('Alarm perangkat belum diaktifkan.');
  final device = ValueNotifier<AlarmDeviceStatus>(const AlarmDeviceStatus());
  bool ready = false;
  bool permission = false;
  Future<void> _queue = Future.value();

  Future<void> initialize() async {
    try {
      zones.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_hedge'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          windows: WindowsInitializationSettings(
            appName: 'HEDGE',
            appUserModelId: 'Mikrotrans.HEDGE.Dispatcher',
            guid: 'D1596E16-B7E2-4DD3-99AE-B36D92368761',
          ),
        ),
      );
      ready = true;
      if (isAndroid) {
        // Clear only legacy scheduled IDs; do not cancel native tagged active alerts.
        for (final old in await plugin.pendingNotificationRequests()) {
          await plugin.cancel(id: old.id);
        }
        await refreshStatus();
      } else if (Platform.isIOS) {
        permission =
            (await plugin
                    .resolvePlatformSpecificImplementation<
                      IOSFlutterLocalNotificationsPlugin
                    >()
                    ?.checkPermissions())
                ?.isEnabled ??
            false;
        status.value = permission
            ? 'Notifikasi iOS tersedia. Alert layar penuh hanya saat app aktif.'
            : 'Aktifkan izin notifikasi iOS.';
      } else {
        permission = true;
        status.value = 'Alert layar penuh tersedia saat aplikasi aktif.';
      }
    } catch (error) {
      status.value = 'Alarm perangkat belum tersedia: $error';
    }
  }

  Future<void> refreshStatus() async {
    if (!isAndroid) return;
    final map = await channel.invokeMapMethod<String, dynamic>('status') ?? {};
    _updateStatus(map);
  }

  void _updateStatus(Map<String, dynamic> map) {
    permission = map['notifications'] == true;
    device.value = AlarmDeviceStatus(
      notifications: permission,
      exact: map['exact'] == true,
      fullScreen: map['fullScreen'] == true,
      pending: map['pending'] as int? ?? 0,
    );
    final d = device.value;
    final missing = <String>[
      if (!d.notifications) 'izin notifikasi',
      if (!d.exact) 'izin alarm tepat',
      if (!d.fullScreen) 'izin alert layar penuh',
      if ((map['restrictedChannels'] as int? ?? 0) > 0)
        'pemeriksaan kanal notifikasi yang dibatasi Android',
    ];
    status.value =
        '${d.pending} pengingat native tersimpan. ${missing.isEmpty ? 'Izin perangkat tersedia.' : 'Perlu ${missing.join(', ')}.'}';
  }

  Future<void> requestPermission() async {
    if (!ready) await initialize();
    if (!ready) return;
    try {
      if (isAndroid) {
        await plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        await refreshStatus();
      } else if (Platform.isIOS) {
        permission =
            await plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
        status.value = permission
            ? 'Notifikasi iOS diaktifkan.'
            : 'Izin iOS belum diberikan.';
      }
    } catch (error) {
      status.value = 'Permintaan izin gagal: $error';
    }
  }

  Future<void> openPermission(String kind) async {
    try {
      if (isAndroid) await channel.invokeMethod<void>('openPermission', kind);
    } catch (error) {
      status.value = 'Pengaturan Android tidak bisa dibuka: $error';
    }
  }

  Future<List<NativeAlarmAction>> readNativeActions() async {
    if (!isAndroid) return [];
    final raw = await channel.invokeMethod<String>('readActions') ?? '[]';
    return (jsonDecode(raw) as List)
        .map((j) => NativeAlarmAction.fromJson(jsonMap(j)))
        .toList();
  }

  Future<void> acceptNativeActions(List<NativeAlarmAction> actions) async {
    if (isAndroid && actions.isNotEmpty) {
      await channel.invokeMethod<void>(
        'acceptActions',
        actions.map((a) => a.id).toList(),
      );
    }
  }

  Future<void> reconcile(Workspace workspace) {
    _queue = _queue.catchError((Object _) {}).then((_) async {
      if (!ready) return;
      try {
        final events = buildAlarmPlan(workspace, now());
        if (isAndroid) {
          // OFF must also reach Android when POST_NOTIFICATIONS was revoked.
          final payload = jsonEncode({
            'theme': workspace.theme,
            'actual': workspace.events
                .where((e) => e.kind == 'departed')
                .map((e) => e.departureId)
                .toList(),
            'events': events.map((e) => e.toJson()).toList(),
            'routes': workspace.routes
                .map(
                  (r) => {
                    'id': r.id,
                    'enabled':
                        r.participates &&
                        r.alarmEnabled &&
                        (r.alerts.banner || r.alerts.fullScreen),
                    ...r.alerts.toJson(),
                    'durationSeconds': r.alarmDuration.clamp(1, 300),
                    'departures':
                        r.schedule?.departures
                            .where(
                              (d) =>
                                  !workspace.hasDeparted(d.id) &&
                                  !workspace.hasAcknowledged(d.id),
                            )
                            .map((d) => d.id)
                            .toList() ??
                        <String>[],
                  },
                )
                .toList(),
          });
          final map =
              await channel.invokeMapMethod<String, dynamic>(
                'replace',
                payload,
              ) ??
              {};
          _updateStatus(map);
          return;
        }
        if (!permission) return;
        await plugin.cancelAll();
        for (final item in events.take(48)) {
          final bytes = sha256.convert(utf8.encode(item.key)).bytes;
          final id =
              ((bytes[0] << 24) |
                  (bytes[1] << 16) |
                  (bytes[2] << 8) |
                  bytes[3]) &
              0x7fffffff;
          final j = item.departureAt.add(const Duration(hours: 7));
          await plugin.zonedSchedule(
            id: id,
            scheduledDate: tz.TZDateTime.from(item.at, tz.local),
            title: '${item.routeName} · Unit ${item.unitNumber}',
            body:
                '${item.stage == 'prep' ? 'Bersiap' : 'Waktu berangkat'} ${formatMinute(j.hour * 60 + j.minute)} WIB · R${item.round}',
            payload: item.key,
            notificationDetails: NotificationDetails(
              iOS: DarwinNotificationDetails(
                presentSound: item.preferences.sound,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
        status.value =
            '${events.take(48).length} pengingat terjadwal. Alert penuh di luar app hanya didukung Android.';
      } catch (error) {
        status.value = 'Alarm belum tersinkron: $error';
      }
    });
    return _queue;
  }
}
