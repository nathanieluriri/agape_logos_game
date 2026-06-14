import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

/// Reachability stream; UI and the sync engine watch this.
final isOnlineProvider = StreamProvider<bool>(
  (ref) => ref.watch(connectivityServiceProvider).onStatusChange,
);
