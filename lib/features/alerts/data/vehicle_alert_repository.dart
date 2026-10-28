import 'package:dio/dio.dart';
import 'package:nubloca/core/network/api_client.dart';
import 'package:nubloca/features/alerts/data/vehicle_alert.dart';

abstract interface class VehicleAlertRepository {
  Future<List<VehicleAlert>> list(int vehicleId);

  Future<VehicleAlert> markRead(int vehicleId, int alertId);
}

class ApiVehicleAlertRepository implements VehicleAlertRepository {
  ApiVehicleAlertRepository(this._apiClient);

  final ApiClient _apiClient;
  Dio get _dio => _apiClient.dio;

  @override
  Future<List<VehicleAlert>> list(int vehicleId) async {
    final response = await _dio.get<Object?>('vehicles/$vehicleId/alerts');
    final data = response.data;
    if (data is! List) {
      throw const FormatException('The API returned an invalid alert list.');
    }

    return data
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('The API returned an invalid alert.');
          }
          return VehicleAlert.fromJson(item);
        })
        .toList(growable: false);
  }

  @override
  Future<VehicleAlert> markRead(int vehicleId, int alertId) async {
    final response = await _dio.post<Object?>(
      'vehicles/$vehicleId/alerts/$alertId/read',
    );
    return VehicleAlert.fromResponse(response.data);
  }
}
