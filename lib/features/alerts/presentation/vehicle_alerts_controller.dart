import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nubloca/core/providers.dart';
import 'package:nubloca/features/alerts/data/vehicle_alert.dart';
import 'package:nubloca/features/alerts/data/vehicle_alert_repository.dart';

final vehicleAlertRepositoryProvider = Provider<VehicleAlertRepository>(
  (ref) => ApiVehicleAlertRepository(ref.watch(apiClientProvider)),
);

final vehicleAlertsProvider = AsyncNotifierProvider.family<
  VehicleAlertsController,
  List<VehicleAlert>,
  int
>(VehicleAlertsController.new);

class VehicleAlertsController extends AsyncNotifier<List<VehicleAlert>> {
  VehicleAlertRepository get _repository =>
      ref.read(vehicleAlertRepositoryProvider);

  @override
  Future<List<VehicleAlert>> build(int arg) => _repository.list(arg);

  Future<void> markRead(VehicleAlert alert) async {
    if (!alert.isUnread) return;

    final updated = await _repository.markRead(alert.vehicleId, alert.id);
    state = AsyncData([
      for (final existing in state.asData?.value ?? const <VehicleAlert>[])
        if (existing.id == updated.id) updated else existing,
    ]);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.list(arg));
  }
}
