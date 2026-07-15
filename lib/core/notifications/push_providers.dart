import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_providers.dart';
import 'push_service.dart';

/// The platform-appropriate [PushService] (Android via native FCM, web via the
/// VAPID-gated impl). Registers device tokens with the backend registry.
final pushServiceProvider = Provider<PushService>(
  (ref) => createPushService(ref.watch(apiClientProvider)),
);
