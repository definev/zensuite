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
/// - A [WritableSignal] to store the latest wrapped event
/// - An [effect] to trigger listener callbacks on each fired event
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
  WritableSignal<_ZenBusEvent<T>?>? _signal = signal<_ZenBusEvent<T>?>(null);
  int _eventId = 0;

  @override
  void fire(T event) {
    assert(_signal != null, 'Bus is disposed cannot fire events');
    _signal!.set(_ZenBusEvent(++_eventId, event));
  }

  @override
  ZenBusSubscription<T> listen(
    void Function(T event) listener, {
    bool Function(T event)? where,
  }) {
    bool firstCall = true;
    return _ZenBusSubscriptionAlienSignals(
      effect(() {
        assert(_signal != null, 'Bus is disposed cannot listen');
        final event = _signal!();
        // Skip the first call because it's the initial value
        if (firstCall) {
          firstCall = false;
          return;
        }

        switch (event) {
          case _ZenBusEvent<T>(:final value) when where?.call(value) ?? true:
            listener(value);
          case _:
            break;
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

class _ZenBusEvent<T> {
  final int id;
  final T value;

  const _ZenBusEvent(this.id, this.value);
}
