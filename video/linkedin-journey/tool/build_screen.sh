#!/usr/bin/env bash
# Cuts footage/demo.mp4 into the 40s beat-aligned phone-screen track.
# Run from video/linkedin-journey/:  bash tool/build_screen.sh
set -euo pipefail

SRC="footage/demo.mp4"
OUT="assets/screen.mp4"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Actual source duration (the recording is 56.947s, variable-frame-rate). Used to
# clamp any requested "end" that runs past the real end of the file (see seg 8).
SRC_DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$SRC")

# seg <index> <start> <end> <target_duration>
# Trims [start,end) from SRC and retimes it to exactly target_duration.
# Ratio is computed with awk (bc is not reliably available in Git Bash on Windows).
# "end" is clamped to the real source duration, and the pts ratio is computed against
# the CLAMPED span, so a requested end past EOF still lands on the exact target
# duration/frame count instead of coming up short.
# The output frame count is also hard-capped with -frames:v (target * 30, rounded) because
# the VFR source, once retimed with setpts and resampled to a 30fps CFR output, can
# overshoot the target duration by a fractional frame per segment; left uncapped this
# compounds across 9 segments into a multi-frame drift in the concatenated output.
seg() {
  local i="$1" start="$2" end="$3" target="$4"
  local actual_end pts frames
  actual_end=$(awk -v e="$end" -v d="$SRC_DUR" 'BEGIN { print (e < d) ? e : d }')
  pts=$(awk -v s="$start" -v e="$actual_end" -v t="$target" 'BEGIN { printf "%.10f", t / (e - s) }')
  frames=$(awk -v t="$target" 'BEGIN { printf "%d", (t * 30) + 0.5 }')
  ffmpeg -y -v error -ss "$start" -to "$actual_end" -i "$SRC" \
    -filter:v "setpts=${pts}*PTS" -an -frames:v "$frames" \
    -c:v libx264 -preset slow -crf 16 -pix_fmt yuv420p -r 30 \
    "$TMP/seg_${i}.mp4"
}

seg 0  33.0 40.0 4.0   # cold open: combo x2                (7s src -> 4.0s, 0.571x)
seg 1  40.0 44.0 4.0   # the claim: combo x3                 (4s src -> 4.0s, 1.0x)

# The ranges below were corrected from the brief's shot-list timecodes after the
# contact-sheet check in Step 3 showed real mismatches against the actual footage:
#   - seg 2/3 boundary: home pond visibly starts fading in around 4.2s, not 6.0s, and a
#     Dictionary sheet covers the screen from ~7.1-9.0s. The brief's 6.0-10.0 pond range
#     landed squarely on that Dictionary sheet. Split the splash/pond handoff at the real
#     crossfade point (4.2s) so seg 3 only ever samples pure pond footage (4.2-7.1s).
#   - seg 4: by 44.0s the board is already static with 3/4 words found; "MAY" formed
#     earlier (it's what seg 0 shows) and the only new word-forming action in this stretch
#     is "MY", which starts right at 49.0-49.8s, just before the level-complete transition
#     at ~50.0s. Narrowed to that actual forming action instead of the mostly-idle 44-50 span.
#   - seg 6: the store screen (with the 1285 -> 1280 hint purchase, "Hint purchased!" toast)
#     is only on screen through about 18.5s; by 19s the recording has already cut back to
#     the home pond and later to a Friends screen. Narrowed from 12.0-22.0 to 12.0-18.5 so
#     the segment stays on the store the whole time.
#   - seg 7: "board completing" doesn't really exist as a multi-second animation, the last
#     word lands at ~49.8s and the level-complete screen (with its progress-bar fill) is on
#     screen within half a second. Moved the range to 49.8-51.3s (picking up right where the
#     corrected seg 4 leaves off) so the slowdown actually shows the landing-to-complete
#     transition instead of a screen that was already static for the whole source span.
#   - seg 8: the "Level 38 Completed!" banner is only actually on screen from 52.0-54.0s;
#     by 54.5s a Dictionary sheet has already slid up over it and stays up through the end
#     of the file. The brief's 52.0-57.0 (clamped to the real 56.947s EOF) spent over half
#     its span on that Dictionary sheet instead of the win banner. Narrowed to 52.0-54.2 so
#     the whole close beat stays on the win screen.
seg 2   0.0  4.2 4.0   # the rewind: launcher -> icon-tap -> splash   (4.2s src -> 4.0s, ~1.05x)
seg 3   4.2  7.1 4.0   # build: home pond (pure pond, no dictionary detour)
seg 4  48.0 49.8 3.0   # build: the word ("MY" forms, right before level-complete)
seg 5  28.0 33.0 5.0   # build: offline/sync  [RESERVED SLOT - see Task 8]  (5s src -> 5.0s, 1.0x)
seg 6  12.0 18.5 4.0   # build: the backend (store purchase, stays on the store screen)
seg 7  49.8 51.3 6.0   # the wall: word lands -> level-complete transition, slowed
seg 8  52.0 54.2 6.0   # close: level complete (win banner only, before the dictionary sheet)

for i in 0 1 2 3 4 5 6 7 8; do echo "file 'seg_${i}.mp4'" >> "$TMP/list.txt"; done

ffmpeg -y -v error -f concat -safe 0 -i "$TMP/list.txt" \
  -c:v libx264 -preset slow -crf 16 -pix_fmt yuv420p -r 30 -an "$OUT"

echo "Built $OUT"
ffprobe -v error -show_entries format=duration -show_entries stream=width,height,nb_frames \
  -of default=noprint_wrappers=1 "$OUT"
