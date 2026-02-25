import 'stream.dart';
import 'alien_signals.dart';

/// A lightweight event bus for publishing and subscribing to events of type [T].
///
/// ZenBus provides a simple pub/sub pattern for decoupled communication between
/// different parts of your application. Events are fired using [fire] and can be
/// listened to using [listen].
///
/// Two implementations are available:
/// - [ZenBus.stream]: Uses Dart's `StreamController` for event handling
/// - [ZenBus.alienSignals]: Uses the alien_signals package for reactive event handling
///
/// Example:
/// ```dart
/// // Create a bus for string events
/// final messageBus = ZenBus<String>.stream();
///
/// // Subscribe to events
/// final subscription = messageBus.listen((message) {
///   print('Received: $message');
/// });
///
/// // Fire an event
/// messageBus.fire('Hello, World!');
///
/// // Clean up
/// subscription.cancel();
/// ```
abstract class ZenBus<T> {
  /// Creates a ZenBus implementation using Dart's `StreamController`.
  ///
  /// This implementation uses a broadcast stream controller to handle events.
  /// It's suitable for most use cases and has no external dependencies beyond
  /// Dart's core libraries.
  factory ZenBus.stream() = ZenBusStream;

  /// Creates a ZenBus implementation using the alien_signals package.
  ///
  /// This implementation uses reactive signals for event handling, which can
  /// provide better performance in scenarios with complex filtering or when
  /// integrating with other signal-based reactive code.
  ///
  /// Requires the `alien_signals` package as a dependency.
  factory ZenBus.alienSignals() = ZenBusAlienSignals;

  /// Fires an event to all active listeners.
  ///
  /// All listeners that have subscribed via [listen] will be notified of this
  /// event, unless they have specified a [where] filter that excludes it.
  ///
  /// Example:
  /// ```dart
  /// final bus = ZenBus<int>.stream();
  /// bus.fire(42); // All listeners will receive this event
  /// ```
  void fire(T event);

  /// Subscribes to events from this bus.
  ///
  /// The [listener] callback will be invoked each time an event is fired,
  /// unless the optional [where] filter is provided and returns false for
  /// that event.
  ///
  /// Returns a [ZenBusSubscription] that can be used to cancel the subscription.
  ///
  /// Parameters:
  /// - [listener]: The callback function to invoke when events are received
  /// - [where]: Optional filter predicate. If provided, only events for which
  ///   this function returns true will be passed to the listener
  ///
  /// Example:
  /// ```dart
  /// final bus = ZenBus<int>.stream();
  ///
  /// // Listen to all events
  /// final sub1 = bus.listen((value) => print('Got: $value'));
  ///
  /// // Listen only to even numbers
  /// final sub2 = bus.listen(
  ///   (value) => print('Even: $value'),
  ///   where: (value) => value % 2 == 0,
  /// );
  ///
  /// bus.fire(1); // Only sub1 receives this
  /// bus.fire(2); // Both sub1 and sub2 receive this
  /// ```
  ZenBusSubscription<T> listen(
    void Function(T event) listener, {
    bool Function(T event)? where,
  });

  /// Disposes of this bus.
  ///
  /// This method should be called when the bus is no longer needed to free up
  /// resources. It is safe to call this method multiple times.
  void dispose();
}

/// A subscription to a [ZenBus] that can be cancelled.
///
/// Returned by [ZenBus.listen] to allow unsubscribing from events.
/// Always call [cancel] when you no longer need to receive events to
/// prevent memory leaks.
///
/// Example:
/// ```dart
/// final bus = ZenBus<String>.stream();
/// final subscription = bus.listen((msg) => print(msg));
///
/// // Later, when done listening:
/// subscription.cancel();
/// ```
abstract class ZenBusSubscription<T> {
  /// Cancels this subscription.
  ///
  /// After calling this method, the listener will no longer receive events
  /// from the bus. This method should be called to clean up resources when
  /// the subscription is no longer needed.
  ///
  /// It is safe to call this method multiple times.
  void cancel();
}
