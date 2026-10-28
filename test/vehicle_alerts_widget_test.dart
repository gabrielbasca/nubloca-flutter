import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nubloca/features/alerts/data/vehicle_alert.dart';
import 'package:nubloca/features/alerts/data/vehicle_alert_repository.dart';
import 'package:nubloca/features/alerts/presentation/vehicle_alerts_controller.dart';
import 'package:nubloca/features/alerts/presentation/vehicle_alerts_screen.dart';

VehicleAlert _alert({
  int id = 1,
  String reason = 'blocking_access',
  String status = VehicleAlert.statusNew,
}) {
  return VehicleAlert(
    id: id,
    vehicleId: 5,
    reason: reason,
    status: status,
    readAt: status == VehicleAlert.statusRead
        ? DateTime.parse('2026-10-28T10:00:00Z')
        : null,
    createdAt: DateTime.parse('2026-10-28T09:30:00Z'),
  );
}

class _FakeAlertRepository implements VehicleAlertRepository {
  _FakeAlertRepository(this.alerts);

  final List<VehicleAlert> alerts;
  final markedRead = <int>[];

  @override
  Future<List<VehicleAlert>> list(int vehicleId) async => alerts;

  @override
  Future<VehicleAlert> markRead(int vehicleId, int alertId) async {
    markedRead.add(alertId);
    final original = alerts.firstWhere((a) => a.id == alertId);
    return VehicleAlert(
      id: original.id,
      vehicleId: original.vehicleId,
      reason: original.reason,
      status: VehicleAlert.statusRead,
      readAt: DateTime.parse('2026-10-28T11:00:00Z'),
      createdAt: original.createdAt,
    );
  }
}

Widget _app(Widget child, _FakeAlertRepository repository) => ProviderScope(
  overrides: [
    vehicleAlertRepositoryProvider.overrideWithValue(repository),
  ],
  child: MaterialApp(home: child),
);

void main() {
  testWidgets('alerts screen shows the empty state', (tester) async {
    await tester.pumpWidget(
      _app(
        const VehicleAlertsScreen(vehicleId: 5, vehicleLicensePlate: 'CJ01ABC'),
        _FakeAlertRepository([]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No alerts yet'), findsOneWidget);
  });

  testWidgets('alerts screen lists reason, vehicle, and read state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const VehicleAlertsScreen(vehicleId: 5, vehicleLicensePlate: 'CJ01ABC'),
        _FakeAlertRepository([
          _alert(id: 1, reason: 'lights_on'),
          _alert(id: 2, reason: 'window_open', status: VehicleAlert.statusRead),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lights left on'), findsOneWidget);
    expect(find.text('Window left open'), findsOneWidget);
    expect(find.textContaining('CJ01ABC'), findsNWidgets(2));
    expect(find.text('Mark read'), findsOneWidget);
  });

  testWidgets('tapping an unread alert marks it read', (tester) async {
    final repository = _FakeAlertRepository([_alert(id: 3)]);
    await tester.pumpWidget(
      _app(
        const VehicleAlertsScreen(vehicleId: 5, vehicleLicensePlate: 'CJ01ABC'),
        repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mark read'), findsOneWidget);
    await tester.tap(find.text('Mark read'));
    await tester.pumpAndSettle();

    expect(repository.markedRead, [3]);
    expect(find.text('Mark read'), findsNothing);
  });
}
