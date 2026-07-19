# Powerup effect jank measurement

Worst case: fog (shader + backdrop blur) + a frozen letter + the armed
shield + the ward ring all live at once, DURING a wheel drag.

1. `C:\flutter\bin\flutter run --profile` on the low-end Android target.
2. Open DevTools > Performance overlay (or `P` in the console).
3. Start a match against a second device/account. Have the opponent cast
   fog and letter_freeze at you; arm shield and combo_lock yourself.
4. While all four are visibly active, drag continuously across the letter
   wheel for 10 seconds. Watch the raster thread bar.
5. Record: average frame time and count of frames over 16ms, in each of:
   - all effects active + dragging
   - fog roll-in window specifically (the animated blur clip is the most
     expensive moment)
   - no effects (baseline drag)

Pass: no sustained raster frames over 16ms on the fog hold; the roll-in
window may briefly spike but must not chain multi-frame skips.

Escape hatches (pre-agreed in the spec, apply in this order):
1. Replace the animated ClipRect on the BackdropFilter with a fade-in of
   the blur layer during roll-in.
2. Drop the BackdropFilter entirely (shader-only fog); thin-patch alpha
   still gives the glimpse effect.
