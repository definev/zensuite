import 'package:alien_signals/preset.dart';

/// Runs [getter] without collecting reactive dependencies.
///
/// Any signal reads performed inside [getter] are treated as non-reactive
/// reads, so the current effect/computed will not subscribe to them.
///
/// This is useful when you need a snapshot value in reactive code but do not
/// want that read to trigger future re-runs.
///
/// ```dart
/// final count = signal(0);
/// final log = computed((_) {
///   final snapshot = untrack(() => count());
///   return 'snapshot: $snapshot';
/// });
/// ```
T untrack<T>(T Function() getter) {
  final prevSub = setActiveSub(null);
  try {
    return getter();
  } finally {
    setActiveSub(prevSub);
  }
}
