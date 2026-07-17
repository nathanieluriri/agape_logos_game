/// Compact remaining-time label for reward cooldowns: "2d 05h", "5h 12m",
/// "12m 30s", or "30s". Shared by the home [RewardTimerPad] countdown and the
/// level-complete Bonus Gift feedback so both read the clock the same way.
String formatCooldown(Duration d) {
  if (d.isNegative || d == Duration.zero) return 'a moment';
  final int days = d.inDays;
  final int hours = d.inHours % 24;
  final int minutes = d.inMinutes % 60;
  final int seconds = d.inSeconds % 60;
  if (days > 0) return '${days}d ${_two(hours)}h';
  if (hours > 0) return '${hours}h ${_two(minutes)}m';
  if (minutes > 0) return '${minutes}m ${_two(seconds)}s';
  return '${seconds}s';
}

/// Convenience for the raw `nextClaimInMs` the backend returns.
String formatCooldownMs(int milliseconds) =>
    formatCooldown(Duration(milliseconds: milliseconds));

String _two(int n) => n.toString().padLeft(2, '0');
