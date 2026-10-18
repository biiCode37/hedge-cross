import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/domain/models.dart';

void main() {
  group('Driver & Domain Extension Tests', () {
    test('Driver model JSON serialization round-trip', () {
      const driver = Driver(
        id: 'driver-1',
        routeId: 'route-1',
        fullName: 'Bambang Hariyanto',
        callName: 'Bambang',
        status: DriverStatus.tetap,
        defaultUnitNumber: '540',
        defaultShift: 1,
        active: true,
      );

      final json = driver.toJson();
      final restored = Driver.fromJson(json);

      expect(restored.id, 'driver-1');
      expect(restored.routeId, 'route-1');
      expect(restored.fullName, 'Bambang Hariyanto');
      expect(restored.callName, 'Bambang');
      expect(restored.status, DriverStatus.tetap);
      expect(restored.defaultUnitNumber, '540');
      expect(restored.defaultShift, 1);
      expect(restored.active, isTrue);
    });

    test('FleetUnit stores driverShift1Id and driverShift2Id', () {
      const unit = FleetUnit(
        id: 'unit-1',
        number: '540',
        driverShift1Id: 'd-1',
        driverShift2Id: 'd-2',
      );

      expect(unit.driverShift1Id, 'd-1');
      expect(unit.driverShift2Id, 'd-2');

      final copied = unit.copyWith(driverShift1Id: 'd-3');
      expect(copied.driverShift1Id, 'd-3');
      expect(copied.driverShift2Id, 'd-2');

      final json = unit.toJson();
      expect(json['driverShift1Id'], 'd-1');
      expect(json['driverShift2Id'], 'd-2');

      final restored = FleetUnit.fromJson(json);
      expect(restored.driverShift1Id, 'd-1');
      expect(restored.driverShift2Id, 'd-2');
    });

    test('PlanConfig supports shiftChangeTime with default 13:00', () {
      const config = PlanConfig();
      expect(config.shiftChangeTime, '13:00');

      final custom = config.copyWith(shiftChangeTime: '13:30');
      expect(custom.shiftChangeTime, '13:30');
      expect(custom.toJson()['shiftChangeTime'], '13:30');

      final fromJson = PlanConfig.fromJson({
        'start': '05:00',
        'end': '22:00',
        'shiftChangeTime': '14:00',
        'rounds': 8,
      });
      expect(fromJson.shiftChangeTime, '14:00');
    });

    test('Departure stores driverName', () {
      const departure = Departure(
        id: 'dep-1',
        unitId: 'u-1',
        unitNumber: '540',
        ordinal: 1,
        round: 1,
        minute: 330,
        peak: false,
        driverName: 'Bambang',
      );

      expect(departure.driverName, 'Bambang');
      final json = departure.toJson();
      expect(json['driverName'], 'Bambang');
      final restored = Departure.fromJson(json);
      expect(restored.driverName, 'Bambang');
    });
  });
}
