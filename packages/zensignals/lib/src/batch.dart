import 'package:alien_signals/preset.dart';

/// Batch multiple signal updates into a single batch.
/// This is useful for performance optimization when updating multiple signals at once.
T batch<T>(T Function() getter) {
  try {
    startBatch();
    return getter();
  } finally {
    endBatch();
  }
}
