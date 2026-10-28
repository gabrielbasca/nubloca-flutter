import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nubloca/core/network/api_client.dart';
import 'package:nubloca/core/storage/token_storage.dart';
import 'package:nubloca/features/alerts/data/vehicle_alert.dart';
import 'package:nubloca/features/alerts/data/vehicle_alert_repository.dart';

Map<String, Object?> _alertJson({
  int id = 1,
  int vehicleId = 5,
  String reason = 'blocking_access',
  String status = 'new',
  String? readAt,
  String createdAt = '2026-10-28T09:30:00.000000Z',
}) {
  return {
    'id': id,
    'vehicle_id': vehicleId,
    'reason': reason,
    'status': status,
    'read_at': readAt,
    'created_at': createdAt,
    'updated_at': createdAt,
  };
}

class _MemoryTokenStorage implements TokenStorage {
  @override
  Future<String?> readToken() async => 'stored-token';

  @override
  Future<void> writeToken(String token) async {}

  @override
  Future<void> deleteToken() async {}
}

class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Object body, int statusCode) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  test('list fetches owner alerts and parses them', () async {
    final adapter = _MockAdapter(
      (_) => _jsonResponse([
        _alertJson(id: 2, reason: 'lights_on', status: 'read',
            readAt: '2026-10-28T10:00:00.000000Z'),
        _alertJson(id: 1),
      ], 200),
    );
    final repository = ApiVehicleAlertRepository(
      ApiClient(
        tokenStorage: _MemoryTokenStorage(),
        dio: Dio(BaseOptions(baseUrl: apiBaseUrl))
          ..httpClientAdapter = adapter,
      ),
    );

    final alerts = await repository.list(5);

    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.uri.path, '/api/vehicles/5/alerts');
    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer stored-token',
    );
    expect(alerts, hasLength(2));
    expect(alerts[0].reason, 'lights_on');
    expect(alerts[0].isUnread, isFalse);
    expect(alerts[0].readAt, isNotNull);
    expect(alerts[1].isUnread, isTrue);
    expect(alerts[1].readAt, isNull);
  });

  test('markRead posts to the read endpoint and parses the alert', () async {
    final adapter = _MockAdapter(
      (_) => _jsonResponse(
        _alertJson(
          id: 7,
          status: 'read',
          readAt: '2026-10-28T11:00:00.000000Z',
        ),
        200,
      ),
    );
    final repository = ApiVehicleAlertRepository(
      ApiClient(
        tokenStorage: _MemoryTokenStorage(),
        dio: Dio(BaseOptions(baseUrl: apiBaseUrl))
          ..httpClientAdapter = adapter,
      ),
    );

    final alert = await repository.markRead(5, 7);

    expect(adapter.requests.single.method, 'POST');
    expect(
      adapter.requests.single.uri.path,
      '/api/vehicles/5/alerts/7/read',
    );
    expect(alert.status, VehicleAlert.statusRead);
    expect(alert.isUnread, isFalse);
    expect(alert.readAt, isNotNull);
  });

  test('parsing rejects malformed alerts', () {
    expect(
      () => VehicleAlert.fromJson({..._alertJson(), 'id': 'x'}),
      throwsFormatException,
    );
    expect(
      () => VehicleAlert.fromJson({..._alertJson(), 'created_at': 'nope'}),
      throwsFormatException,
    );
    expect(
      () => VehicleAlert.fromJson({..._alertJson(), 'read_at': 42}),
      throwsFormatException,
    );
  });
}
