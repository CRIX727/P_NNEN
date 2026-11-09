import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../data/sync/sync_manager.dart';

class SyncStatusIndicator extends ConsumerStatefulWidget {
  const SyncStatusIndicator({super.key});

  @override
  ConsumerState<SyncStatusIndicator> createState() =>
      _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends ConsumerState<SyncStatusIndicator> {
  Timer? _timer;
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final value = await ref.read(localDatabaseProvider).pendingCount();
    if (mounted) setState(() => _pending = value);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ref.read(networkMonitorProvider).status,
      initialData: ref.read(networkMonitorProvider).isOnline,
      builder: (context, networkSnapshot) {
        final online = networkSnapshot.data ?? true;
        return StreamBuilder<SyncStatus>(
          stream: ref.read(syncManagerProvider).statusStream,
          initialData: ref.read(syncManagerProvider).status,
          builder: (context, syncSnapshot) {
            final syncing = syncSnapshot.data == SyncStatus.syncing;
            final label = !online
                ? 'Sin conexión'
                : syncing
                    ? 'Sincronizando...'
                    : _pending > 0
                        ? 'Pendiente ($_pending)'
                        : 'Sincronizado';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child:
                    Text(label, style: Theme.of(context).textTheme.labelSmall),
              ),
            );
          },
        );
      },
    );
  }
}
