/// ZenBus - A high-performance event bus for Flutter
///
/// ZenBus provides multiple implementation strategies for event handling,
/// allowing you to choose the best approach for your performance needs.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:zenbus/zenbus.dart';
///
/// // Create a bus (Alien Signal recommended for best performance)
/// final bus = ZenBus<String>.alienSignal();
///
/// // Listen to events
/// final subscription = bus.listen((event) {
///   print('Received: $event');
/// });
///
/// // Fire events
/// bus.fire('Hello, ZenBus!');
///
/// // Clean up
/// subscription.cancel();
/// ```
///
/// // Dispose bus
/// bus.dispose();
///
/// ## Implementations
///
/// - **Alien Signal** (Recommended): Best performance and memory efficiency
/// - **Stream**: Standard Dart async patterns, good for few listeners
library;

export 'src/bus.dart';
export 'src/stream.dart';
export 'src/alien_signals.dart';
