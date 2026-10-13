import 'package:flutter/material.dart';
import '../application/sync_controller.dart';

class SyncStatusPill extends StatelessWidget {
  const SyncStatusPill({
    super.key,
    required this.state,
    this.onTap,
  });

  final SyncState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    switch (state.status) {
      case SyncStatus.synced:
        color = const Color(0xFF10B981);
        label = 'Sinkron';
        icon = Icons.cloud_done;
        break;
      case SyncStatus.syncing:
        color = const Color(0xFF00E5FF);
        label = 'Menyelaraskan...';
        icon = Icons.sync;
        break;
      case SyncStatus.offline:
        color = const Color(0xFFFF9800);
        label = state.pendingOutboxCount > 0 ? 'Offline (${state.pendingOutboxCount})' : 'Offline';
        icon = Icons.cloud_off;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
