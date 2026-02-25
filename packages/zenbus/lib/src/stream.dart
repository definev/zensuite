import 'dart:async';

import 'package:zenbus/src/bus.dart';

/// Stream-based implementation of [ZenBus].
///
/// This implementation uses Dart's [StreamController] to manage event
/// distribution. It creates a broadcast stream that allows multiple
/// listeners to subscribe independently.
///
/// This is the default implementation and is suitable for most use cases.
/// It has no external dependencies beyond Dart's core libraries.
///
/// Example:
/// ```dart
/// final bus = ZenBusStream<String>();
/// // Or using the factory:
/// final bus2 = ZenBus<String>.stream();
///
/// bus.listen((msg) => print('Listener 1: $msg'));
/// bus.listen((msg) => print('Listener 2: $msg'));
///
/// bus.fire('Hello!'); // Both listeners receive the event
/// ```
class ZenBusStream<T> implements ZenBus<T> {
  final StreamController<T> _controller = StreamController.broadcast();

  @override
  void fire(T event) => _controller.sink.add(event);

  @override
  ZenBusSubscription<T> listen(
    void Function(T event) listener, {
    bool Function(T event)? where,
  }) {
    var stream = _controller.stream;
    if (where != null) {
      stream = stream.where(where);
    }
    return _ZenBusSubscriptionStream(stream.listen(listener));
  }

  @override
  void dispose() {
    _controller.close();
  }
}

class _ZenBusSubscriptionStream<T> implements ZenBusSubscription<T> {
  final StreamSubscription<T> _subscription;

  _ZenBusSubscriptionStream(this._subscription);

  @override
  void cancel() => _subscription.cancel();
}
