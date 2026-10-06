import 'package:flutter/material.dart';
import '../application/notification_service.dart';
import '../domain/models.dart';
import 'design_system.dart';

class AlarmPermissionPanel extends StatelessWidget {
  const AlarmPermissionPanel({
    super.key,
    required this.service,
    required this.workspace,
  });
  final NotificationService service;
  final Workspace Function() workspace;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Izin alarm perangkat',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      ValueListenableBuilder(
        valueListenable: service.status,
        builder: (_, text, _) => Text(text),
      ),
      if (service.isAndroid)
        ValueListenableBuilder<AlarmDeviceStatus>(
          valueListenable: service.device,
          builder: (context, d, _) => Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('TTS: ${d.speechStatus}'),
              ),
              if (d.alarmVolumeMax > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Volume Alarm Android: ${d.alarmVolume}/${d.alarmVolumeMax}. HEDGE mengikuti volume ini.',
                  ),
                ),
              if (d.audioIssue.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(d.audioIssue),
                ),
              for (final item in [
                ('Notifikasi', d.notifications),
                ('Alarm tepat', d.exact),
                ('Layar penuh', d.fullScreen),
                ('Di atas aplikasi lain', d.overlay),
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    item.$2 ? Icons.check_circle_outline : Icons.info_outline,
                    color: item.$2
                        ? context.hedge.success
                        : context.hedge.amberInk,
                  ),
                  title: Text(item.$1),
                  trailing: Text(item.$2 ? 'Diizinkan' : 'Belum diizinkan'),
                ),
            ],
          ),
        ),
      OutlinedButton.icon(
        onPressed: () async {
          await service.requestPermission();
          await service.reconcile(workspace());
        },
        icon: const Icon(Icons.notifications),
        label: const Text('Izinkan notifikasi'),
      ),
      if (service.isAndroid) ...[
        OutlinedButton.icon(
          onPressed: () => service.openPermission('overlay'),
          icon: const Icon(Icons.layers_outlined),
          label: const Text('Izinkan tampil di atas aplikasi lain'),
        ),
        OutlinedButton.icon(
          onPressed: service.testSpeech,
          icon: const Icon(Icons.record_voice_over_outlined),
          label: const Text('Uji suara TTS'),
        ),
        TextButton(
          onPressed: service.stopSpeechTest,
          child: const Text('Hentikan uji suara'),
        ),
        OutlinedButton.icon(
          onPressed: () => service.openPermission('tts'),
          icon: const Icon(Icons.settings_voice_outlined),
          label: const Text('Pengaturan suara Bahasa Indonesia'),
        ),
        OutlinedButton.icon(
          onPressed: () => service.openPermission('sound'),
          icon: const Icon(Icons.volume_up_outlined),
          label: const Text('Pengaturan volume Android'),
        ),
        OutlinedButton.icon(
          onPressed: () => service.openPermission('exact'),
          icon: const Icon(Icons.alarm),
          label: const Text('Izin alarm tepat'),
        ),
        OutlinedButton.icon(
          onPressed: () => service.openPermission('fullScreen'),
          icon: const Icon(Icons.fullscreen),
          label: const Text('Izin alert layar penuh'),
        ),
        OutlinedButton.icon(
          onPressed: () => service.openPermission('notifications'),
          icon: const Icon(Icons.settings),
          label: const Text('Pengaturan notifikasi Android'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Aktifkan izin di atas aplikasi lain untuk alert ketika memakai app lain. Layar terkunci memakai izin alert layar penuh. TTS memakai suara Bahasa Indonesia offline yang tersedia di perangkat. Atur durasi di Jadwal → Atur. Force Stop membatalkan alarm sampai HEDGE dibuka kembali.',
          style: TextStyle(fontSize: 12),
        ),
      ],
      const SizedBox(height: 16),
    ],
  );
}
