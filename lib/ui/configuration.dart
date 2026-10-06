import 'package:flutter/material.dart';
import '../domain/models.dart';

class ConfigurationSheet extends StatefulWidget {
  const ConfigurationSheet({super.key, required this.route});
  final HedgeRoute route;
  @override
  State<ConfigurationSheet> createState() => _ConfigurationSheetState();
}

class _ConfigurationSheetState extends State<ConfigurationSheet> {
  final form = GlobalKey<FormState>();
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

  Widget time(String label, TextEditingController field) => Expanded(
    child: TextFormField(
      controller: field,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.datetime,
      validator: (value) {
        try {
          parseMinute(value ?? '');
          return null;
        } catch (_) {
          return 'HH:mm';
        }
      },
    ),
  );
  Widget number(String label, TextEditingController field, int min, int max) =>
      TextFormField(
        controller: field,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final n = int.tryParse(value ?? '');
          return n == null || n < min || n > max ? '$min–$max' : null;
        },
      );
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SizedBox(
      height:
          (MediaQuery.sizeOf(context).height -
              MediaQuery.viewInsetsOf(context).bottom -
              MediaQuery.viewPaddingOf(context).top) *
          .86,
      child: Form(
        key: form,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Atur ${widget.route.name}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Row(
                    children: [
                      time('Jam mulai', start),
                      const SizedBox(width: 12),
                      time('Jam selesai', end),
                    ],
                  ),
                  const SizedBox(height: 16),
                  number('Target ritase per unit', rounds, 1, 30),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Headway lambat lebih dahulu'),
                    value: slow,
                    onChanged: (v) => setState(() => slow = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gunakan periode peak'),
                    value: peak,
                    onChanged: (v) => setState(() => peak = v),
                  ),
                  if (peak)
                    for (var i = 0; i < 2; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Peak ${i + 1}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                time('Mulai', peakFields[i * 3]),
                                const SizedBox(width: 12),
                                time('Selesai', peakFields[i * 3 + 1]),
                              ],
                            ),
                            const SizedBox(height: 12),
                            number(
                              'Interval menit',
                              peakFields[i * 3 + 2],
                              1,
                              60,
                            ),
                          ],
                        ),
                      ),
                  const Text(
                    'Konfigurasi peak yang tidak bisa menjaga batas waktu dan headway positif akan ditolak saat membuat jadwal.',
                  ),
                  const Divider(height: 32),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Alarm rute'),
                    value: alarm,
                    onChanged: (v) => setState(() => alarm = v),
                  ),
                  if (alarm) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Banner notifikasi'),
                      value: banner,
                      onChanged: (v) => setState(() => banner = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Alert layar penuh'),
                      value: fullScreen,
                      subtitle: const Text(
                        'Dapat tampil di layar terkunci dengan izin Android. Saat memakai app lain, Android dapat menampilkan banner.',
                      ),
                      onChanged: (v) => setState(() => fullScreen = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pengingat sebelum berangkat'),
                      value: preparation,
                      onChanged: (v) => setState(() => preparation = v),
                    ),
                    if (preparation)
                      number(
                        'Persiapan sebelum berangkat (detik)',
                        prep,
                        1,
                        300,
                      ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Alarm saat waktunya berangkat'),
                      value: departure,
                      onChanged: (v) => setState(() => departure = v),
                    ),
                    const SizedBox(height: 12),
                    number(
                      'Tutup alert otomatis setelah (detik)',
                      duration,
                      1,
                      300,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Suara alarm'),
                      value: sound,
                      onChanged: (v) => setState(() => sound = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Getaran'),
                      value: vibration,
                      onChanged: (v) => setState(() => vibration = v),
                    ),
                    const Text(
                      'Sudah Berangkat mencatat aktual dan membatalkan pengingat unit itu. Timeout hanya menutup alert. Mode layar penuh memerlukan notifikasi sistem sebagai pembawanya.',
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Pengaturan alarm berlaku segera setelah disimpan. Perubahan jam, ritase dan peak memerlukan jadwal dibuat ulang.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
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
                      rounds: int.parse(rounds.text),
                      slowFirst: slow,
                      peakEnabled: peak,
                      peaks: [
                        for (var i = 0; i < 2; i++)
                          PeakPeriod(
                            start: peakFields[i * 3].text,
                            end: peakFields[i * 3 + 1].text,
                            interval: int.parse(peakFields[i * 3 + 2].text),
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
                  child: const Text('Simpan pengaturan'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
