import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

/// Reachability stream; UI watches this. autoDispose so the underlying
/// reachability polling stops when no widget is listening.
final isOnlineProvider = StreamProvider.autoDispose<bool>(
  (ref) => ref.watch(connectivityServiceProvider).onStatusChange,
);
