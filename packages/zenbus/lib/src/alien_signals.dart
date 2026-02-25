import 'package:alien_signals/alien_signals.dart';
import 'package:zenbus/src/bus.dart';

/// Reactive signals-based implementation of [ZenBus].
///
/// This implementation uses the `alien_signals` package to provide a reactive
/// event bus. It leverages signals, computed values, and effects to efficiently
/// handle event distribution and filtering.
///
/// This implementation can provide better performance in scenarios with:
/// - Complex event filtering logic
/// - Integration with other signal-based reactive code
/// - Fine-grained reactivity requirements
///
/// The implementation uses:
/// - A [WritableSignal] to store the latest event
/// - A [computed] signal for filtering events based on the [where] predicate
/// - An [effect] to trigger listener callbacks when filtered events change
///
/// Example:
/// ```dart
/// final bus = ZenBusAlienSignals<int>();
/// // Or using the factory:
/// final bus2 = ZenBus<int>.alienSignals();
///
/// // The reactive nature allows efficient filtering
/// bus.listen(
///   (value) => print('Even: $value'),
///   where: (value) => value % 2 == 0,
/// );
///
/// bus.fire(1); // Not printed
/// bus.fire(2); // Prints: Even: 2
/// ```
class ZenBusAlienSignals<T> implements ZenBus<T> {
  WritableSignal<T?>? _signal = signal(null);

  @override
  void fire(T event) {
    assert(_signal != null, 'Bus is disposed cannot fire events');
    _signal!.set(event);
  }

  @override
  ZenBusSubscription<T> listen(
    void Function(T event) listener, {
    bool Function(T event)? where,
  }) {
    bool firstCall = true;

    final filter = computed<T?>((prev) {
      assert(_signal != null, 'Bus is disposed cannot listen');
      final value = _signal!();
      if (value != null && (where?.call(value) ?? true)) {
        return value;
      }
      return prev;
    });
    return _ZenBusSubscriptionAlienSignals(
      effect(() {
        final value = filter();
        // Skip the first call because it's the initial value
        if (value != null) {
          if (firstCall) {
            firstCall = false;
            return;
          }
          listener(value);
        }
      }),
    );
  }

  @override
  void dispose() {
    _signal = null;
  }
}

class _ZenBusSubscriptionAlienSignals<T> implements ZenBusSubscription<T> {
  final Effect _subscription;

  _ZenBusSubscriptionAlienSignals(this._subscription);

  @override
  void cancel() => _subscription();
}
