# HapticService Usage Guide

The `HapticService` provides centralized haptic feedback control across the app, similar to `AudioService`.

## Basic Setup

Haptics are automatically integrated in `bootstrap.dart`:
- Service instantiated and mute state restored from settings
- Provided to all widgets via `hapticServiceProvider`

## Using Haptics in Widgets

### 1. Read the service in a ConsumerWidget

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/haptics/haptic_providers.dart';

class MyButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final haptics = ref.read(hapticServiceProvider);
    
    return GestureDetector(
      onTap: () async {
        await haptics.lightImpact();
        // handle button tap
      },
      child: Text('Tap me'),
    );
  }
}
```

### 2. Or read in a StatefulWidget using ref.watch

```dart
class MyButtonState extends State<MyButton> {
  late final HapticService _haptics;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _haptics = ref.read(hapticServiceProvider);
  }
  
  void _handleTap() async {
    await _haptics.mediumImpact();
    // handle tap
  }
}
```

## Feedback Types

```dart
// Light feedback for subtle interactions
await haptics.lightImpact();

// Medium feedback for primary actions
await haptics.mediumImpact();

// Heavy feedback for significant events (wins, combos)
await haptics.heavyImpact();

// Selection feedback (best for scrolling/selection)
await haptics.selectionClick();
```

## Integration Points

Add haptics to these interactions:

1. **Game Interactions**
   - Letter selection on wheel -> `selectionClick()`
   - Word submission -> `mediumImpact()`
   - Shuffle/hint actions -> `lightImpact()`
   - Combo milestones -> `heavyImpact()`
   - Level win -> `heavyImpact()`

2. **UI Actions**
   - Button presses -> `lightImpact()`
   - Settings toggles -> `lightImpact()`
   - Navigation -> `lightImpact()`

3. **Ambient/Game Components**
   - Pad shadows on tap -> `lightImpact()`
   - Ripple effects -> `selectionClick()`

## Settings Integration

The user can toggle haptics in Settings:
- UI calls `SettingsController.setHaptics(bool)`
- Controller persists to DB AND calls `haptics.setMuted(!value)`
- All subsequent haptic calls are silently skipped if muted

## Testing

Mock the service in tests:

```dart
final mockHaptics = MockHapticService();
when(mockHaptics.lightImpact()).thenAnswer((_) async {});

ref.read(hapticServiceProvider).overrideWithValue(mockHaptics);
```
