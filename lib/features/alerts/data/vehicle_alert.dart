class VehicleAlert {
  const VehicleAlert({
    required this.id,
    required this.vehicleId,
    required this.reason,
    required this.status,
    required this.readAt,
    required this.createdAt,
  });

  final int id;
  final int vehicleId;
  final String reason;
  final String status;
  final DateTime? readAt;
  final DateTime createdAt;

  static const statusNew = 'new';
  static const statusRead = 'read';

  bool get isUnread => status != statusRead;

  factory VehicleAlert.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final vehicleId = json['vehicle_id'];
    final reason = json['reason'];
    final status = json['status'];
    final readAtRaw = json['read_at'];
    final createdAtRaw = json['created_at'];

    if (id is! int ||
        vehicleId is! int ||
        reason is! String ||
        status is! String ||
        createdAtRaw is! String) {
      throw const FormatException('The API returned an invalid alert.');
    }

    final createdAt = DateTime.tryParse(createdAtRaw);
    if (createdAt == null) {
      throw const FormatException('The API returned an invalid alert.');
    }

    DateTime? readAt;
    if (readAtRaw != null) {
      if (readAtRaw is! String) {
        throw const FormatException('The API returned an invalid alert.');
      }
      readAt = DateTime.tryParse(readAtRaw);
      if (readAt == null) {
        throw const FormatException('The API returned an invalid alert.');
      }
    }

    return VehicleAlert(
      id: id,
      vehicleId: vehicleId,
      reason: reason,
      status: status,
      readAt: readAt,
      createdAt: createdAt,
    );
  }

  factory VehicleAlert.fromResponse(Object? response) {
    if (response is! Map<String, dynamic>) {
      throw const FormatException('The API returned an invalid alert.');
    }
    return VehicleAlert.fromJson(response);
  }
}
