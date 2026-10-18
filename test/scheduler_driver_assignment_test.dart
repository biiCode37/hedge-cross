import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/domain/models.dart';
import 'package:hedge_flutter/domain/scheduler.dart';
import 'package:hedge_flutter/domain/alarm_plan.dart';

void main() {
  group('Scheduler Driver Assignment Tests', () {
    const dPagi = Driver(
      id: 'd-pagi',
      routeId: 'r-1',
      fullName: 'Bambang Hariyanto',
      callName: 'Bambang',
      status: DriverStatus.tetap,
    );
    const dSiang = Driver(
      id: 'd-siang',
      routeId: 'r-1',
      fullName: 'Rudi Suherman',
      callName: 'Rudi',
      status: DriverStatus.tetap,
    );

    const unit = FleetUnit(
      id: 'u-1',
      number: '540',
      active: true,
      driverShift1Id: 'd-pagi',
      driverShift2Id: 'd-siang',
    );

    final route = HedgeRoute(
      id: 'r-1',
      name: 'JAK.115',
      color: 0xFF00E5FF,
      units: [unit],
      order: ['u-1'],
      drivers: [dPagi, dSiang],
      config: const PlanConfig(
        start: '06:00',
        end: '20:00',
        shiftChangeTime: '13:00',
        rounds: 4,
      ),
    );

    test('Scheduler.generate assigns morning driver before 13:00 and afternoon driver at or after 13:00', () {
      const scheduler = Scheduler();
      final schedule = scheduler.generate(
        route,
        date: '2026-10-18',
        revisionId: 'rev-1',
        createdAt: DateTime.utc(2026, 10, 18, 5, 0),
      );

      final morningRows = schedule.departures.where((d) => d.minute < 13 * 60).toList();
      final afternoonRows = schedule.departures.where((d) => d.minute >= 13 * 60).toList();

      expect(morningRows.isNotEmpty, isTrue);
      expect(afternoonRows.isNotEmpty, isTrue);

      for (final row in morningRows) {
        expect(row.driverName, 'Bambang');
      }
      for (final row in afternoonRows) {
        expect(row.driverName, 'Rudi');
      }
    });

    test('buildAlarmPlan propagates driverName to AlarmEvent', () {
      const scheduler = Scheduler();
      final schedule = scheduler.generate(
        route,
        date: '2026-10-18',
        revisionId: 'rev-1',
        createdAt: DateTime.utc(2026, 10, 18, 5, 0),
      );

      final workspace = Workspace(
        routes: [route.copyWith(schedule: schedule)],
        activeRouteId: 'r-1',
        date: '2026-10-18',
      );

      final events = buildAlarmPlan(workspace, DateTime.utc(2026, 10, 18, 0, 0));
      expect(events.any((e) => e.driverName == 'Bambang'), isTrue);
      expect(events.any((e) => e.driverName == 'Rudi'), isTrue);
    });
  });
}
