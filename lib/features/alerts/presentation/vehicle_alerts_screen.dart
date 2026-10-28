import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nubloca/core/network/api_client.dart';
import 'package:nubloca/features/alerts/data/vehicle_alert.dart';
import 'package:nubloca/features/alerts/presentation/vehicle_alerts_controller.dart';

String alertReasonLabel(String reason) {
  switch (reason) {
    case 'blocking_access':
      return 'Blocking access';
    case 'lights_on':
      return 'Lights left on';
    case 'window_open':
      return 'Window left open';
    case 'accident_damage':
      return 'Accident or damage';
    case 'other':
      return 'Other';
    default:
      return reason;
  }
}

class VehicleAlertsScreen extends ConsumerWidget {
  const VehicleAlertsScreen({
    super.key,
    required this.vehicleId,
    this.vehicleLicensePlate,
  });

  final int vehicleId;
  final String? vehicleLicensePlate;

  Future<void> _markRead(
    BuildContext context,
    WidgetRef ref,
    VehicleAlert alert,
  ) async {
    if (!alert.isUnread) return;

    try {
      await ref
          .read(vehicleAlertsProvider(vehicleId).notifier)
          .markRead(alert);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(vehicleAlertsProvider(vehicleId));

    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle alerts')),
      body: alerts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AlertsError(
          onRetry: () =>
              ref.read(vehicleAlertsProvider(vehicleId).notifier).refresh(),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () =>
              ref.read(vehicleAlertsProvider(vehicleId).notifier).refresh(),
          child: items.isEmpty
              ? ListView(
                  key: const Key('alertsList'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 110),
                    Icon(Icons.notifications_none, size: 64),
                    SizedBox(height: 18),
                    Center(
                      child: Text(
                        'No alerts yet',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Alerts from your QR sticker will appear here.',
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  key: const Key('alertsList'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final alert = items[index];
                    return _AlertTile(
                      alert: alert,
                      vehicleLicensePlate: vehicleLicensePlate,
                      onMarkRead: () => _markRead(context, ref, alert),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.alert,
    required this.vehicleLicensePlate,
    required this.onMarkRead,
  });

  final VehicleAlert alert;
  final String? vehicleLicensePlate;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = alert.isUnread;

    return Card(
      elevation: 0,
      child: ListTile(
        onTap: unread ? onMarkRead : null,
        leading: CircleAvatar(
          backgroundColor: unread
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            unread
                ? Icons.notifications_active_outlined
                : Icons.notifications_none,
            color: unread
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          alertReasonLabel(alert.reason),
          style: TextStyle(
            fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          [
            if (vehicleLicensePlate != null) vehicleLicensePlate!,
            _formatTimestamp(alert.createdAt),
          ].join(' · '),
        ),
        trailing: unread
            ? TextButton(onPressed: onMarkRead, child: const Text('Mark read'))
            : const Icon(Icons.done_all, size: 20),
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    final date =
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}

class _AlertsError extends StatelessWidget {
  const _AlertsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44),
            const SizedBox(height: 16),
            Text(
              'Could not load alerts',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
