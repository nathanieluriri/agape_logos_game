// lib/features/multiplayer/presentation/widgets/powerup_wheel_slot.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/petal_icon.dart';

/// One [PowerupWheel] slot: owned shows the art with an "xN" badge, unowned
/// shows a dimmed art with a petal price chip. A drag past [_fireThreshold]
/// drags the chip with the finger (a lightweight ghost stand-in: the chip
/// itself translates rather than a separate overlay copy); releasing past the
/// threshold fires, releasing short of it (or a plain tap) does not.
class PowerupWheelSlot extends StatefulWidget {
  const PowerupWheelSlot({
    super.key,
    this.anchorKey,
    required this.itemId,
    required this.owned,
    required this.price,
    required this.onFire,
    required this.onTapInfo,
  });

  final GlobalKey? anchorKey;
  final String itemId;
  final int owned;
  final int price;
  final void Function(String itemId, Offset releaseGlobal) onFire;
  final void Function(String itemId) onTapInfo;

  static const double fireThreshold = 64;

  @override
  State<PowerupWheelSlot> createState() => _PowerupWheelSlotState();
}

class _PowerupWheelSlotState extends State<PowerupWheelSlot> {
  Offset _dragTotal = Offset.zero;
  Offset _lastGlobal = Offset.zero;
  bool _dragging = false;

  bool get _owned => widget.owned > 0;

  void _start(DragStartDetails d) {
    _dragTotal = Offset.zero;
    _lastGlobal = d.globalPosition;
    setState(() => _dragging = true);
  }

  void _update(DragUpdateDetails d) {
    _lastGlobal = d.globalPosition;
    setState(() => _dragTotal += d.delta);
  }

  void _end(DragEndDetails d) {
    final fired = _dragTotal.distance > PowerupWheelSlot.fireThreshold;
    setState(() => _dragging = false);
    if (fired) widget.onFire(widget.itemId, _lastGlobal);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _owned ? '${widget.itemId}, ${widget.owned} owned' : widget.itemId,
      child: GestureDetector(
        key: widget.anchorKey,
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTapInfo(widget.itemId),
        onPanStart: _owned ? _start : null,
        onPanUpdate: _owned ? _update : null,
        onPanEnd: _owned ? _end : null,
        child: Transform.translate(
          offset: _dragging ? _dragTotal : Offset.zero,
          child: _SlotFace(
            itemId: widget.itemId,
            owned: widget.owned,
            price: widget.price,
          ),
        ),
      ),
    );
  }
}

/// The cream chip face: powerup art, dimmed while unowned, with either an
/// owned-count badge or a price chip underneath.
class _SlotFace extends StatelessWidget {
  const _SlotFace({
    required this.itemId,
    required this.owned,
    required this.price,
  });

  final String itemId;
  final int owned;
  final int price;

  static const _faceDecoration = BoxDecoration(
    color: AppColors.pillFill,
    shape: BoxShape.circle,
    border: Border.fromBorderSide(BorderSide(color: AppColors.pillBorder)),
  );

  @override
  Widget build(BuildContext context) {
    final enabled = owned > 0;
    return DecoratedBox(
      decoration: _faceDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: enabled ? 1 : 0.4,
              child: SvgPicture.asset(
                'assets/powerups/$itemId.svg',
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            if (enabled)
              Text(
                'x$owned',
                style: const TextStyle(
                  color: AppColors.padLabel,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PetalIcon(size: 14),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    '$price',
                    style: const TextStyle(
                      color: AppColors.padLabelSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
