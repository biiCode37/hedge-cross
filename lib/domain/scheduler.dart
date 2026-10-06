import 'dart:math' as math;
import 'models.dart';

class SchedulingException implements Exception {
  const SchedulingException(this.message);
  final String message;
  @override
  String toString() => message;
}

class _Segment {
  _Segment(this.start, this.end, {this.interval});
  final int start;
  int end;
  int? interval;
  int gaps = 0;
  int get duration => end - start;
  bool get peak => interval != null;
}

class Scheduler {
  const Scheduler();

  void validateRoute(HedgeRoute route) {
    final start = parseMinute(route.config.start);
    final end = parseMinute(route.config.end);
    if (end <= start) {
      throw const SchedulingException(
        'Jam selesai harus setelah jam mulai. Layanan lintas tengah malam belum diaktifkan.',
      );
    }
    if (route.config.rounds < 1 || route.config.rounds > 30) {
      throw const SchedulingException('Target ritase harus 1–30.');
    }
    if (route.units.map((u) => u.id).toSet().length != route.units.length ||
        route.units.any(
          (u) => u.id.trim().isEmpty || u.number.trim().isEmpty,
        )) {
      throw const SchedulingException('Identitas atau nomor unit tidak valid.');
    }
    if (route.units.map((u) => u.number.trim()).toSet().length !=
        route.units.length) {
      throw const SchedulingException('Nomor unit harus unik dalam satu rute.');
    }
    if (route.order.toSet().length != route.order.length ||
        route.order.any((id) => !route.units.any((u) => u.id == id))) {
      throw const SchedulingException(
        'Urutan memuat unit duplikat atau tidak dikenal.',
      );
    }
    if (route.units
        .where((u) => u.active)
        .any((u) => !route.order.contains(u.id))) {
      throw const SchedulingException(
        'Setiap unit aktif harus masuk urutan keberangkatan.',
      );
    }
    if (route.activeUnits.isEmpty) {
      throw const SchedulingException('Aktifkan minimal satu unit.');
    }
    if (route.activeUnits.length * route.config.rounds > 20000) {
      throw const SchedulingException(
        'Maksimum 20.000 keberangkatan per rute untuk versi ini.',
      );
    }
    if (route.config.peakEnabled) {
      for (final p in route.config.peaks) {
        if (parseMinute(p.end) <= parseMinute(p.start) ||
            p.interval < 1 ||
            p.interval > 60) {
          throw const SchedulingException(
            'Periode peak harus meningkat dengan interval 1–60 menit.',
          );
        }
      }
    }
  }

  ScheduleRevision generate(
    HedgeRoute route, {
    required String date,
    required String revisionId,
    required DateTime createdAt,
  }) {
    validateRoute(route);
    plannedInstant(date, 0);
    final units = route.activeUnits;
    final count = units.length * route.config.rounds;
    final times = _timeline(
      parseMinute(route.config.start),
      parseMinute(route.config.end),
      count,
      route.config,
    );
    final rows = List.generate(
      count,
      (i) => Departure(
        id: '$revisionId:$i',
        unitId: units[i % units.length].id,
        unitNumber: units[i % units.length].number,
        ordinal: i + 1,
        round: i ~/ units.length + 1,
        minute: times[i],
        peak: count > 1 && _peakAt(times[i], route.config),
        nextGap: i + 1 < count ? times[i + 1] - times[i] : null,
      ),
    );
    return ScheduleRevision(
      id: revisionId,
      routeId: route.id,
      date: date,
      createdAt: createdAt.toUtc().toIso8601String(),
      inputFingerprint: route.fingerprint,
      config: route.config,
      departures: rows,
    );
  }

  ScheduleRevision replan(
    HedgeRoute route, {
    required String revisionId,
    required DateTime now,
  }) {
    validateRoute(route);
    final old = route.schedule;
    if (old == null || old.departures.isEmpty) {
      throw const SchedulingException('Buat jadwal terlebih dahulu.');
    }
    final cutoff = now.toUtc();
    final start = plannedInstant(old.date, parseMinute(old.config.start));
    final end = plannedInstant(old.date, parseMinute(route.config.end));
    if (!cutoff.isAfter(start) || !cutoff.isBefore(end)) {
      throw const SchedulingException(
        'Hitung ulang hanya tersedia pada jam operasional tanggal jadwal.',
      );
    }
    final frozen = old.departures
        .where((d) => !plannedInstant(old.date, d.minute).isAfter(cutoff))
        .toList();
    final done = <String, int>{};
    for (final d in frozen) {
      done[d.unitId] = (done[d.unitId] ?? 0) + 1;
    }
    final queue = <({FleetUnit unit, int round})>[];
    final active = route.activeUnits;
    for (var pass = 1; pass <= route.config.rounds; pass++) {
      for (final u in active) {
        final completed = done[u.id] ?? 0;
        if (completed + pass <= route.config.rounds) {
          queue.add((unit: u, round: completed + pass));
        }
      }
    }
    final day = plannedInstant(old.date, 0);
    final firstMinute = cutoff.difference(day).inSeconds ~/ 60 + 1;
    final endMinute = parseMinute(route.config.end);
    if (queue.isNotEmpty && firstMinute > endMinute) {
      throw const SchedulingException(
        'Tidak ada waktu tersisa untuk keberangkatan baru.',
      );
    }
    final times = queue.isEmpty
        ? <int>[]
        : _timeline(firstMinute, endMinute, queue.length, route.config);
    final rows = <Departure>[...frozen];
    for (var i = 0; i < queue.length; i++) {
      rows.add(
        Departure(
          id: '$revisionId:$i',
          unitId: queue[i].unit.id,
          unitNumber: queue[i].unit.number,
          ordinal: frozen.length + i + 1,
          round: queue[i].round,
          minute: times[i],
          peak: _peakAt(times[i], route.config),
        ),
      );
    }
    final projected = List.generate(
      rows.length,
      (i) => rows[i].withGap(
        i + 1 < rows.length ? rows[i + 1].minute - rows[i].minute : null,
      ),
    );
    return ScheduleRevision(
      id: revisionId,
      routeId: route.id,
      date: old.date,
      createdAt: now.toUtc().toIso8601String(),
      inputFingerprint: route.fingerprint,
      config: route.config,
      departures: projected,
      parentId: old.id,
      frozenCount: frozen.length,
      reason: 'replan-planned-prefix',
    );
  }

  List<int> _grouped(int duration, int gaps, bool slowFirst) {
    if (gaps == 0) return [];
    final low = duration ~/ gaps;
    if (low < 1) {
      throw const SchedulingException(
        'Jumlah keberangkatan terlalu banyak: headway minimum satu menit.',
      );
    }
    final highCount = duration - low * gaps;
    final lowCount = gaps - highCount;
    return slowFirst
        ? [...List.filled(highCount, low + 1), ...List.filled(lowCount, low)]
        : [...List.filled(lowCount, low), ...List.filled(highCount, low + 1)];
  }

  List<_Segment> _peaks(int start, int end, PlanConfig config) {
    if (!config.peakEnabled) return [];
    final values =
        config.peaks
            .map(
              (p) => _Segment(
                math.max(start, parseMinute(p.start)),
                math.min(end, parseMinute(p.end)),
                interval: p.interval,
              ),
            )
            .where((p) => p.duration > 0)
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final merged = <_Segment>[];
    for (final p in values) {
      if (merged.isNotEmpty && p.start <= merged.last.end) {
        merged.last.end = math.max(merged.last.end, p.end);
        merged.last.interval = math.min(merged.last.interval!, p.interval!);
      } else {
        merged.add(p);
      }
    }
    return merged;
  }

  bool _peakAt(int minute, PlanConfig config) => _peaks(
    parseMinute(config.start),
    parseMinute(config.end),
    config,
  ).any((p) => minute >= p.start && minute < p.end);

  List<int> _timeline(int start, int end, int count, PlanConfig config) {
    if (count <= 0) return [];
    if (count == 1) return [start];
    final duration = end - start;
    final gapCount = count - 1;
    if (duration < gapCount) {
      throw const SchedulingException(
        'Waktu tidak cukup untuk headway minimum satu menit.',
      );
    }
    final peaks = _peaks(start, end, config);
    if (peaks.isEmpty) {
      final result = [start];
      for (final gap in _grouped(duration, gapCount, config.slowFirst)) {
        result.add(result.last + gap);
      }
      return result;
    }
    final segments = <_Segment>[];
    var cursor = start;
    for (final peak in peaks) {
      if (cursor < peak.start) segments.add(_Segment(cursor, peak.start));
      if (peak.duration % peak.interval! != 0) {
        throw SchedulingException(
          'Durasi peak ${formatMinute(peak.start)}–${formatMinute(peak.end)} harus kelipatan interval ${peak.interval} menit. Sesuaikan periode/interval; jadwal tidak dipaksa.',
        );
      }
      peak.gaps = peak.duration ~/ peak.interval!;
      segments.add(peak);
      cursor = peak.end;
    }
    if (cursor < end) segments.add(_Segment(cursor, end));
    final peakGaps = segments
        .where((s) => s.peak)
        .fold(0, (sum, s) => sum + s.gaps);
    final off = segments.where((s) => !s.peak).toList();
    final remaining = gapCount - peakGaps;
    if (remaining < off.length || (off.isEmpty && remaining != 0)) {
      throw SchedulingException(
        'Konfigurasi peak membutuhkan $peakGaps interval tetap dan ${off.length} interval transisi; tersedia $gapCount. Sesuaikan ritase, unit, atau peak.',
      );
    }
    if (off.isNotEmpty) {
      final total = off.fold(0, (sum, s) => sum + s.duration);
      final raw = off.map((s) => remaining * s.duration / total).toList();
      for (var i = 0; i < off.length; i++) {
        off[i].gaps = raw[i].floor();
      }
      final ranks = List.generate(off.length, (i) => i)
        ..sort((a, b) {
          final compare = (raw[b] - raw[b].floor()).compareTo(
            raw[a] - raw[a].floor(),
          );
          return compare == 0 ? a.compareTo(b) : compare;
        });
      var unassigned = remaining - off.fold(0, (sum, s) => sum + s.gaps);
      for (var i = 0; i < unassigned; i++) {
        off[ranks[i % ranks.length]].gaps++;
      }
      for (final empty in off.where((s) => s.gaps == 0)) {
        final donors = off.where((s) => s.gaps > 1).toList()
          ..sort((a, b) => b.gaps.compareTo(a.gaps));
        if (donors.isEmpty) {
          throw const SchedulingException(
            'Jumlah interval transisi tidak cukup.',
          );
        }
        donors.first.gaps--;
        empty.gaps = 1;
      }
    }
    final result = [start];
    for (final s in segments) {
      final gaps = s.peak
          ? List.filled(s.gaps, s.interval!)
          : _grouped(s.duration, s.gaps, config.slowFirst);
      for (final gap in gaps) {
        result.add(result.last + gap);
      }
      if (result.last != s.end) {
        throw const SchedulingException('Batas periode tidak konsisten.');
      }
    }
    if (result.length != count || result.last != end) {
      throw const SchedulingException(
        'Jumlah atau batas jadwal tidak konsisten.',
      );
    }
    return result;
  }
}
