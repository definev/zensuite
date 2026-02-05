// ignore_for_file: non_constant_identifier_names, avoid_print

import 'package:zenbus/zenbus.dart';

void main() {
  print('=== ZenBus Examples ===\n');

  example1_basicUsage();
  example2_multipleListeners();
  example3_eventFiltering();
  example4_typedEvents();
  example5_performanceComparison();
}

/// Example 1: Basic Usage
void example1_basicUsage() {
  print('📌 Example 1: Basic Usage');
  print('-' * 40);

  // Create a bus
  final bus = ZenBus<String>.alienSignals();

  // Subscribe to events
  final subscription = bus.listen((message) {
    print('  Received: $message');
  });

  // Fire events
  bus.fire('Hello, ZenBus!');
  bus.fire('This is easy!');

  // Clean up
  subscription.cancel();
  print('');
}

/// Example 2: Multiple Listeners
void example2_multipleListeners() {
  print('📌 Example 2: Multiple Listeners');
  print('-' * 40);

  final bus = ZenBus<String>.alienSignals();

  // Add multiple listeners
  final sub1 = bus.listen((msg) => print('  Listener 1: $msg'));
  final sub2 = bus.listen((msg) => print('  Listener 2: $msg'));
  final sub3 = bus.listen((msg) => print('  Listener 3: $msg'));

  // All listeners receive the event
  bus.fire('Broadcast message');

  // Cancel all
  sub1.cancel();
  sub2.cancel();
  sub3.cancel();
  print('');
}

/// Example 3: Event Filtering
void example3_eventFiltering() {
  print('📌 Example 3: Event Filtering');
  print('-' * 40);

  final bus = ZenBus<int>.alienSignals();

  // Only receive even numbers
  final evenSub = bus.listen(
    (number) => print('  Even: $number'),
    where: (number) => number % 2 == 0,
  );

  // Only receive numbers > 5
  final largeSub = bus.listen(
    (number) => print('  Large: $number'),
    where: (number) => number > 5,
  );

  // Fire various numbers
  for (int i = 1; i <= 10; i++) {
    bus.fire(i);
  }

  evenSub.cancel();
  largeSub.cancel();
  print('');
}

/// Example 4: Typed Events
void example4_typedEvents() {
  print('📌 Example 4: Typed Events');
  print('-' * 40);

  // Define event types
  final loginBus = ZenBus<UserLoggedIn>.alienSignals();
  final logoutBus = ZenBus<UserLoggedOut>.alienSignals();

  // Subscribe to events
  loginBus.listen((event) {
    print('  👤 ${event.username} logged in');
  });

  logoutBus.listen((event) {
    print('  👋 ${event.username} logged out');
  });

  // Fire events
  loginBus.fire(UserLoggedIn('alice'));
  loginBus.fire(UserLoggedIn('bob'));
  logoutBus.fire(UserLoggedOut('alice'));
  print('');
}

/// Example 5: Performance Comparison
void example5_performanceComparison() {
  print('📌 Example 5: Performance Comparison');
  print('-' * 40);

  const iterations = 100000;

  // Test Stream implementation
  final streamBus = ZenBus<int>.stream();
  final streamSub = streamBus.listen((_) {});

  final streamStart = DateTime.now();
  for (int i = 0; i < iterations; i++) {
    streamBus.fire(i);
  }
  final streamDuration = DateTime.now().difference(streamStart);
  streamSub.cancel();

  // Test Alien Signal implementation
  final alienBus = ZenBus<int>.alienSignals();
  final alienSub = alienBus.listen((_) {});

  final alienStart = DateTime.now();
  for (int i = 0; i < iterations; i++) {
    alienBus.fire(i);
  }
  final alienDuration = DateTime.now().difference(alienStart);
  alienSub.cancel();

  print('  Stream: ${streamDuration.inMicroseconds}µs for $iterations events');
  print(
      '  Alien Signal: ${alienDuration.inMicroseconds}µs for $iterations events');

  final speedup = streamDuration.inMicroseconds / alienDuration.inMicroseconds;
  print('  Alien Signal is ${speedup.toStringAsFixed(2)}x faster! 🚀');
  print('');
}

// Event classes for Example 4
class UserLoggedIn {
  final String username;
  UserLoggedIn(this.username);
}

class UserLoggedOut {
  final String username;
  UserLoggedOut(this.username);
}
