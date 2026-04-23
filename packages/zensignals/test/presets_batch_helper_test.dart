import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zensignals/zensignals.dart';

void main() {
  group('batch', () {
    test('returns the callback result', () {
      final result = batch(() => 42);
      expect(result, 42);
    });

    test('coalesces multiple signal writes into one reactive pass', () async {
      final a = signal(0);
      final b = signal(0);
      var runs = 0;

      final stop = effect((_) {
        a();
        b();
        runs++;
      });

      expect(runs, 1); // initial tracking run

      batch(() {
        a.value = 1;
        b.value = 2;
      });
      await Future<void>.delayed(Duration.zero);

      expect(runs, 2); // exactly one re-run after the batch
      stop.dispose();
      a.dispose();
      b.dispose();
    });

    test('restores batching state when callback throws', () async {
      final s = signal(0);
      var runs = 0;
      final stop = effect((_) {
        s();
        runs++;
      });
      expect(runs, 1);

      expect(
        () => batch<void>(() {
          s.value = 1;
          throw StateError('boom');
        }),
        throwsA(isA<StateError>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(runs, 2);

      // Ensure reactivity continues normally after the failed batch.
      s.value = 2;
      await Future<void>.delayed(Duration.zero);
      expect(runs, 3);

      stop.dispose();
      s.dispose();
    });
  });

  group('effect/effectScope presets', () {
    test('effect firstCall flips from true to false', () async {
      final s = signal(0);
      final seen = <bool>[];

      final stop = effect((firstCall) {
        s();
        seen.add(firstCall);
      });

      s.value = 1;
      await Future<void>.delayed(Duration.zero);
      s.value = 2;
      await Future<void>.delayed(Duration.zero);

      expect(seen, [true, false, false]);
      stop.dispose();
      s.dispose();
    });

    test('effectScope callback runs with firstCall=true', () {
      final seen = <bool>[];
      final scope = effectScope((firstCall) {
        seen.add(firstCall);
      });

      expect(seen, [true]);
      scope.dispose();
    });

    test('dependencies must be read on first run to react', () async {
      final tracked = signal(0);
      final untracked = signal(0);
      var trackedCalls = 0;
      var untrackedCalls = 0;

      final e1 = effect((firstCall) {
        tracked(); // always read -> tracked
        if (!firstCall) trackedCalls++;
      });

      final e2 = effect((firstCall) {
        if (firstCall) return; // no reads on initial run -> no deps
        untracked();
        untrackedCalls++;
      });

      tracked.value = 1;
      untracked.value = 1;
      await Future<void>.delayed(Duration.zero);

      expect(trackedCalls, 1);
      expect(untrackedCalls, 0);

      e1.dispose();
      e2.dispose();
      tracked.dispose();
      untracked.dispose();
    });
  });

  group('helper extensions', () {
    test('SignalNotifierCast.cast returns same instance for SignalNotifier', () {
      final notifier = SignalNotifier(1);
      final casted = notifier.cast;
      expect(identical(casted, notifier), isTrue);
      notifier.dispose();
    });

    test('SignalNotifierCast.cast throws for non-SignalNotifier ValueNotifier',
        () {
      final plain = ValueNotifier<int>(1);
      expect(() => plain.cast, throwsA(isA<TypeError>()));
      plain.dispose();
    });
  });
}
