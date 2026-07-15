// lib/features/multiplayer/presentation/widgets/powerup_wheel.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/shadows.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../domain/powerup_kind.dart';
import 'powerup_wheel_slot.dart';

/// The two sides of the powerup wheel. Grouping follows [isOffensive], NOT
/// the store catalog's `kind` field: the catalog buckets time_boost and
/// double_points as "utility", but they are self-targeted (defense) effects
/// for wheel purposes.
enum PowerupCategory { offense, defense }

/// The four offense item ids, fixed slot order (12, 3, 6, 9 o'clock).
const List<String> kOffensePowerupIds = [
  'freeze_letter',
  'fog',
  'scramble',
  'word_steal',
];

/// The four defense item ids, fixed slot order.
const List<String> kDefensePowerupIds = [
  'shield',
  'time_boost',
  'double_points',
  'combo_lock',
];

List<String> itemIdsForCategory(PowerupCategory category) =>
    category == PowerupCategory.offense
        ? kOffensePowerupIds
        : kDefensePowerupIds;

/// A modal radial overlay, styled like the letter wheel, listing the four
/// powerups of [category]. Tapping a slot always reports [onTapInfo]; an
/// owned slot dragged past the fire threshold and released outside the disc
/// reports [onFire] with the wire kind (see `powerup_kind.dart`); released
/// inside cancels. Tapping the scrim calls [onClose].
class PowerupWheel extends StatelessWidget {
  const PowerupWheel({
    super.key,
    required this.category,
    required this.ownedCounts,
    required this.prices,
    required this.onFire,
    required this.onTapInfo,
    required this.onClose,
    this.firstSlotKey,
  });

  final PowerupCategory category;

  /// Owned quantity per store item id.
  final Map<String, int> ownedCounts;

  /// Petal cost per store item id.
  final Map<String, int> prices;

  /// Fires the WIRE kind (letter_freeze, fog_bank, ...), not the item id.
  final void Function(String kind, Offset releaseGlobal) onFire;
  final void Function(String itemId) onTapInfo;
  final VoidCallback onClose;

  /// Tutorial spotlight anchor for the first slot of the open wheel.
  final GlobalKey? firstSlotKey;

  static const double _discSize = 220;
  static const double _slotSize = 64;

  static const _discDecoration = BoxDecoration(
    shape: BoxShape.circle,
    gradient: AppGradients.wheelPad,
    boxShadow: AppShadows.pad,
  );

  /// Box big enough that a slot's full square sits inside the box's own hit
  /// bounds even at the disc's outer edge (a slot centered exactly on the
  /// disc radius would otherwise straddle the parent box boundary and miss
  /// hit-testing, since RenderBox.hitTest rejects a position outside its own
  /// size before ever asking its children).
  static const double _boxSize = _discSize + _slotSize;

  static List<Offset> _slotCenters(double boxSize, double discRadius, int count) {
    final center = Offset(boxSize / 2, boxSize / 2);
    return [
      for (var i = 0; i < count; i++)
        center +
            Offset.fromDirection(
              -math.pi / 2 + (2 * math.pi * i / count),
              discRadius,
            ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ids = itemIdsForCategory(category);
    final centers = _slotCenters(_boxSize, _discSize / 2, ids.length);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: const ColoredBox(color: AppColors.pondScrim),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: SizedBox(
              width: _boxSize,
              height: _boxSize,
              child: Stack(
                children: [
                  const Positioned(
                    left: _slotSize / 2,
                    top: _slotSize / 2,
                    width: _discSize,
                    height: _discSize,
                    child: DecoratedBox(decoration: _discDecoration),
                  ),
                  for (var i = 0; i < ids.length; i++)
                    Positioned(
                      left: centers[i].dx - _slotSize / 2,
                      top: centers[i].dy - _slotSize / 2,
                      width: _slotSize,
                      height: _slotSize,
                      child: PowerupWheelSlot(
                        key: ValueKey('powerup_slot_${ids[i]}'),
                        anchorKey: i == 0 ? firstSlotKey : null,
                        itemId: ids[i],
                        owned: ownedCounts[ids[i]] ?? 0,
                        price: prices[ids[i]] ?? 0,
                        onFire: (itemId, releaseGlobal) {
                          final kind = powerupWireKind(itemId);
                          if (kind != null) onFire(kind, releaseGlobal);
                        },
                        onTapInfo: onTapInfo,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
