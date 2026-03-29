import 'dart:async';

/// Increments [usageMinutes] every minute via [Timer.periodic].
class UsageTracker {
  UsageTracker({required this.onTick});

  final void Function(int usageMinutes) onTick;

  Timer? _timer;
  int usageMinutes = 0;

  void start() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      usageMinutes++;
      onTick(usageMinutes);
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
