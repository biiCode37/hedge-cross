import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/domain/models.dart';
import 'package:hedge_flutter/domain/scheduler.dart';

HedgeRoute legacyRoute(Map<String, dynamic> j) => HedgeRoute(
  id: j['id'],
  name: j['name'],
  color: 0xffff9800,
  units: (j['masterUnits'] as List)
      .map((u) => FleetUnit.fromJson(jsonMap(u)))
      .toList(),
  order: List<String>.from(j['departureOrder']),
  config: PlanConfig(
    start: j['jamMulai'],
    end: j['jamSelesai'],
    rounds: j['ritase'],
    slowFirst: j['groupOrder'] == 'slow-first',
    peakEnabled: j['peakEnabled'],
    peaks: [
      for (var i = 1; i <= 2; i++)
        PeakPeriod(
          start: j['peak${i}Start'],
          end: j['peak${i}End'],
          interval: j['peak${i}Interval'],
        ),
    ],
  ),
);
ScheduleRevision generate(HedgeRoute route, {String id = 'test'}) =>
    const Scheduler().generate(
      route,
      date: '2026-10-05',
      revisionId: id,
      createdAt: DateTime.utc(2026, 10, 5),
    );
HedgeRoute small({
  int units = 3,
  int rounds = 2,
  String end = '05:20',
  bool slow = false,
}) {
  final fleet = List.generate(
    units,
    (i) => FleetUnit(id: 'unit:$i', number: '$i'),
  );
  return HedgeRoute(
    id: 'r',
    name: 'R',
    color: 0xffff9800,
    units: fleet,
    order: fleet.map((u) => u.id).toList(),
    config: PlanConfig(
      start: '05:00',
      end: end,
      rounds: rounds,
      slowFirst: slow,
    ),
  );
}

void main() {
  final fixtures = jsonMap(
    jsonDecode(
      File('docs/migration/legacy-scheduler-reference.json').readAsStringSync(),
    ),
  );
  final cases = (fixtures['cases'] as List).map(jsonMap).toList();
  for (final fixture in cases.where(
    (t) =>
        t['input']['kind'] == 'schedule' &&
        t['classification'] == 'baseline' &&
        t['input']['route']['peakEnabled'] == false,
  )) {
    test('${fixture['id']}: characterized non-peak behavior', () {
      final route = legacyRoute(jsonMap(fixture['input']['route']));
      final expected = jsonMap(fixture['expected']);
      if (expected['error'] != null) {
        expect(() => generate(route), throwsA(isA<SchedulingException>()));
        return;
      }
      final actual = generate(route).departures
          .map(
            (d) => {
              'unit': d.unitNumber,
              'jam': formatMinute(d.minute),
              'ritase': d.round,
              'interval': d.nextGap,
            },
          )
          .toList();
      expect(
        actual,
        (expected['rows'] as List)
            .map(
              (d) => {
                'unit': d['unit'],
                'jam': d['jam'],
                'ritase': d['ritase'],
                'interval': d['interval'],
              },
            )
            .toList(),
      );
    });
  }
  for (final name in [
    'malformed-time-throws',
    'negative-ritase-invalid',
    'zero-ritase-falls-back',
    'active-unit-missing-order',
    'duplicate-departure-order',
    'duplicate-unit-number',
    'dense-zero-minute-gaps',
    'peak-rounding-shift',
    'peak-overallocated-truncated',
    'peak-only-negative-headway',
  ]) {
    final fixture = cases.firstWhere((t) => t['id'] == name);
    test(
      'Reject unsafe legacy input: $name',
      () => expect(
        () => generate(legacyRoute(jsonMap(fixture['input']['route']))),
        throwsException,
      ),
    );
  }
  test('Non-peak invariants across fleet, rounds, grouped policy', () {
    for (var n = 1; n <= 25; n++) {
      for (var rounds = 1; rounds <= 8; rounds++) {
        for (final slow in [false, true]) {
          final route = small(
            units: n,
            rounds: rounds,
            end: '22:00',
            slow: slow,
          );
          final plan = generate(route);
          expect(plan.departures.length, n * rounds);
          expect(plan.departures.first.minute, 300);
          expect(plan.departures.last.minute, n * rounds == 1 ? 300 : 1320);
          expect(plan.departures.map((d) => d.id).toSet().length, n * rounds);
          for (var i = 0; i < plan.departures.length; i++) {
            final d = plan.departures[i];
            expect(d.unitId, 'unit:${i % n}');
            expect(d.round, i ~/ n + 1);
            if (i + 1 < plan.departures.length) {
              expect(d.nextGap, greaterThan(0));
              expect(d.minute + d.nextGap!, plan.departures[i + 1].minute);
            }
          }
          expect(plan.toJson(), generate(route).toJson());
        }
      }
    }
  });
  test('Peak boundaries exact and half-open', () {
    final route = small(units: 3, rounds: 3).copyWith(
      config: const PlanConfig(
        start: '05:00',
        end: '05:20',
        rounds: 3,
        peakEnabled: true,
        peaks: [PeakPeriod(start: '05:04', end: '05:08', interval: 2)],
      ),
    );
    final plan = generate(route);
    expect(plan.departures.length, 9);
    expect(plan.departures.first.minute, 300);
    expect(plan.departures.last.minute, 320);
    expect(plan.departures.where((d) => d.peak).map((d) => d.minute), [
      304,
      306,
    ]);
    expect(plan.departures.firstWhere((d) => d.minute == 308).peak, false);
    for (final row in plan.departures) {
      if (row.nextGap != null) expect(row.nextGap, greaterThan(0));
    }
  });
  test('Overlap merges at fastest interval while retaining boundaries', () {
    final route = small(units: 3, rounds: 3).copyWith(
      config: const PlanConfig(
        start: '05:00',
        end: '05:20',
        rounds: 3,
        peakEnabled: true,
        peaks: [
          PeakPeriod(start: '05:04', end: '05:08', interval: 2),
          PeakPeriod(start: '05:06', end: '05:12', interval: 4),
        ],
      ),
    );
    final rows = generate(route).departures;
    expect(rows.where((d) => d.peak).map((d) => d.minute), [
      304,
      306,
      308,
      310,
    ]);
    expect(rows.last.minute, 320);
  });
  test('Replan freezes IDs, uses current draft, recomputes splice', () {
    var route = small();
    final old = generate(route);
    route = route.copyWith(
      schedule: old,
      config: const PlanConfig(start: '05:00', end: '05:30', rounds: 3),
    );
    final now = plannedInstant(old.date, 310).add(const Duration(seconds: 30));
    final replanned = const Scheduler().replan(
      route,
      revisionId: 'replan',
      now: now,
    );
    expect(replanned.parentId, old.id);
    expect(replanned.frozenCount, 3);
    expect(
      replanned.departures.take(3).map((d) => d.id),
      old.departures.take(3).map((d) => d.id),
    );
    expect(replanned.departures[3].minute, 311);
    expect(replanned.departures[2].nextGap, 3);
    expect(old.departures[2].nextGap, 4);
    expect(replanned.departures.last.minute, 330);
    expect(replanned.config.rounds, 3);
    expect(replanned.inputFingerprint, route.fingerprint);
    expect(replanned.departures.length, 9);
  });
  test('Replan never counts __proto__ unit by object property', () {
    final base = small(units: 1, rounds: 3);
    var route = base.copyWith(
      units: [const FleetUnit(id: '__proto__', number: '__proto__')],
      order: ['__proto__'],
    );
    route = route.copyWith(schedule: generate(route));
    final revision = const Scheduler().replan(
      route,
      revisionId: 'next',
      now: plannedInstant('2026-10-05', 310),
    );
    expect(revision.departures.length, 3);
    expect(revision.departures.last.minute, 311);
    expect(revision.frozenCount, 2);
  });
  test(
    'WIB instant independent of host timezone and dates reject normalization',
    () {
      expect(plannedInstant('2026-10-05', 300), DateTime.utc(2026, 10, 4, 22));
      expect(serviceDate(DateTime.utc(2026, 10, 4, 18)), '2026-10-05');
      expect(() => plannedInstant('2026-02-30', 300), throwsFormatException);
      expect(() => parseMinute('5:00'), throwsFormatException);
    },
  );
}
