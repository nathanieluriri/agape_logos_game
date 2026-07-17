import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'haptic_service.dart';

/// The app's haptic feedback service. Overridden in `bootstrap()` with the
/// instance whose mute state is restored from settings; overridden with a fake
/// in tests.
final hapticServiceProvider =
    Provider<HapticService>((ref) => FlutterHapticService());
