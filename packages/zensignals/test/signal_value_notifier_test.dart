import 'package:flutter_test/flutter_test.dart';
import 'package:zensignals/zensignals.dart';

void main() {
  group('SignalNotifier', () {
    // ─── value ──────────────────────────────────────────────────────────────

    group('value', () {
      test('returns the initial value', () {
        final notifier = SignalNotifier(42);
        expect(notifier.value, 42);
      });

      test('returns updated value after assignment', () {
        final notifier = SignalNotifier('hello');
        notifier.value = 'world';
        expect(notifier.value, 'world');
      });

      test('supports nullable types', () {
        final notifier = SignalNotifier<int?>(null);
        expect(notifier.value, isNull);
        notifier.value = 1;
        expect(notifier.value, 1);
      });
    });

    // ─── hasListeners ────────────────────────────────────────────────────────

    group('hasListeners', () {
      test('is false when no listeners are registered', () {
        final notifier = SignalNotifier(0);
        expect(notifier.hasListeners, isFalse);
      });

      test('is true after a listener is added', () {
        final notifier = SignalNotifier(0);
        notifier.addListener(() {});
        expect(notifier.hasListeners, isTrue);
        notifier.dispose();
      });

      test('is false after the last listener is removed', () {
        final notifier = SignalNotifier(0);
        void listener() {}
        notifier.addListener(listener);
        notifier.removeListener(listener);
        expect(notifier.hasListeners, isFalse);
      });
    });

    // ─── addListener / removeListener ────────────────────────────────────────

    group('addListener', () {
      test('listener is called when value changes', () async {
        final notifier = SignalNotifier(0);
        var callCount = 0;
        notifier.addListener(() => callCount++);

        notifier.value = 1;
        // Allow the alien_signals effect to propagate.
        await Future<void>.delayed(Duration.zero);

        expect(callCount, 1);
        notifier.dispose();
      });

      test(
          'listener is NOT called on the initial value (first call is skipped)',
          () async {
        final notifier = SignalNotifier(0);
        var callCount = 0;
        notifier.addListener(() => callCount++);

        // No value change – listener should not fire.
        await Future<void>.delayed(Duration.zero);

        expect(callCount, 0);
        notifier.dispose();
      });

      test('multiple listeners are all called on value change', () async {
        final notifier = SignalNotifier(0);
        var callA = 0;
        var callB = 0;
        notifier.addListener(() => callA++);
        notifier.addListener(() => callB++);

        notifier.value = 99;
        await Future<void>.delayed(Duration.zero);

        expect(callA, 1);
        expect(callB, 1);
        notifier.dispose();
      });

      test('re-adding the same listener replaces the previous subscription',
          () async {
        // SignalNotifier cancels the old effect when re-adding the same
        // listener (idempotent re-registration), so the listener fires exactly once.
        final notifier = SignalNotifier(0);
        var callCount = 0;
        void listener() => callCount++;

        notifier.addListener(listener);
        notifier.addListener(listener); // replaces previous effect

        notifier.value = 1;
        await Future<void>.delayed(Duration.zero);

        expect(callCount, 1); // only one active effect
        notifier.dispose();
      });
    });

    group('removeListener', () {
      test('removed listener is no longer called on value change', () async {
        final notifier = SignalNotifier(0);
        var callCount = 0;
        void listener() => callCount++;

        notifier.addListener(listener);
        notifier.removeListener(listener);

        notifier.value = 1;
        await Future<void>.delayed(Duration.zero);

        expect(callCount, 0);
      });

      test('removing a listener that was never added is a no-op', () {
        final notifier = SignalNotifier(0);
        expect(() => notifier.removeListener(() {}), returnsNormally);
      });
    });

    // ─── notifyListeners ─────────────────────────────────────────────────────

    group('notifyListeners', () {
      test('triggers listeners without changing the value', () async {
        final notifier = SignalNotifier(5);
        var callCount = 0;
        notifier.addListener(() => callCount++);

        notifier.notifyListeners();
        await Future<void>.delayed(Duration.zero);

        expect(callCount, 1);
        expect(notifier.value, 5); // value unchanged
        notifier.dispose();
      });

      test('calling notifyListeners multiple times fires listener each time',
          () async {
        final notifier = SignalNotifier(0);
        var callCount = 0;
        notifier.addListener(() => callCount++);

        notifier.notifyListeners();
        notifier.notifyListeners();
        await Future<void>.delayed(Duration.zero);

        expect(callCount, greaterThanOrEqualTo(2));
        notifier.dispose();
      });
    });

    // ─── WritableSignal interface (call / set) ────────────────────────────────

    group('WritableSignal interface', () {
      test('call() returns the current value', () {
        final notifier = SignalNotifier(7);
        expect(notifier(), 7);
      });

      test('call() reflects value changes', () {
        final notifier = SignalNotifier('a');
        notifier.value = 'b';
        expect(notifier(), 'b');
      });

      test('set() is equivalent to value= assignment', () async {
        final notifier = SignalNotifier(0);
        var callCount = 0;
        notifier.addListener(() => callCount++);

        notifier.set(42);
        await Future<void>.delayed(Duration.zero);

        expect(notifier.value, 42);
        expect(callCount, 1);
        notifier.dispose();
      });
    });

    // ─── dispose ─────────────────────────────────────────────────────────────

    group('dispose', () {
      test('calling dispose does not throw', () {
        final notifier = SignalNotifier(0);
        notifier.addListener(() {});
        expect(notifier.dispose, returnsNormally);
      });

      test('isDisposed is true after dispose', () {
        final notifier = SignalNotifier(0);
        expect(notifier.isDisposed, isFalse);
        notifier.dispose();
        expect(notifier.isDisposed, isTrue);
      });

      test('hasListeners is false after dispose (effects cleared)', () {
        final notifier = SignalNotifier(0);
        notifier.addListener(() {});
        notifier.dispose();
        expect(notifier.hasListeners, isFalse);
      });

      test('listener fires for changes before dispose', () async {
        final notifier = SignalNotifier(0);
        var callCount = 0;
        notifier.addListener(() => callCount++);

        notifier.value = 1;
        await Future<void>.delayed(Duration.zero);

        expect(callCount, 1);
        notifier.dispose();
      });

      test('value= asserts after dispose', () {
        final notifier = SignalNotifier(0);
        notifier.dispose();
        expect(() => notifier.value = 1, throwsA(isA<AssertionError>()));
      });

      test('addListener asserts after dispose', () {
        final notifier = SignalNotifier(0);
        notifier.dispose();
        expect(
            () => notifier.addListener(() {}), throwsA(isA<AssertionError>()));
      });

      test('notifyListeners asserts after dispose', () {
        final notifier = SignalNotifier(0);
        notifier.dispose();
        expect(notifier.notifyListeners, throwsA(isA<AssertionError>()));
      });

      test('call() asserts after dispose', () {
        final notifier = SignalNotifier(0);
        notifier.dispose();
        expect(notifier.call, throwsA(isA<AssertionError>()));
      });

      test('set() asserts after dispose', () {
        final notifier = SignalNotifier(0);
        notifier.dispose();
        expect(() => notifier.set(1), throwsA(isA<AssertionError>()));
      });
    });
    // ─── .from constructor ───────────────────────────────────────────────────

    group('.from constructor', () {
      test('shares value with the underlying WritableSignal', () {
        final s = signal(10);
        final notifier = SignalNotifier.from(s);
        expect(notifier.value, 10);
        notifier.dispose();
      });

      test('reflects mutations made directly on the original signal', () {
        final s = signal(0);
        final notifier = SignalNotifier.from(s);
        s.set(42);
        expect(notifier.value, 42);
        notifier.dispose();
      });

      test('mutations via notifier are reflected on the original signal', () {
        final s = signal(0);
        final notifier = SignalNotifier.from(s);
        notifier.value = 99;
        expect(untrack(s), 99);
        notifier.dispose();
      });

      test('listener fires when the original signal is mutated externally',
          () async {
        final s = signal(0);
        final notifier = SignalNotifier.from(s);
        var callCount = 0;
        notifier.addListener(() => callCount++);

        s.set(1);
        await Future<void>.delayed(Duration.zero);

        expect(callCount, 1);
        notifier.dispose();
      });

      test('dispose does not affect the original signal', () {
        final s = signal(7);
        final notifier = SignalNotifier.from(s);
        notifier.dispose();
        expect(notifier.isDisposed, isTrue);
        // The original signal is still usable.
        expect(untrack(s), 7);
        s.set(8);
        expect(untrack(s), 8);
      });

      test('two notifiers wrapping the same signal share reactivity', () async {
        final s = signal(0);
        final a = SignalNotifier.from(s);
        final b = SignalNotifier.from(s);
        var callA = 0, callB = 0;
        a.addListener(() => callA++);
        b.addListener(() => callB++);

        s.set(1);
        await Future<void>.delayed(Duration.zero);

        expect(callA, 1);
        expect(callB, 1);
        a.dispose();
        b.dispose();
      });
    });
  });

  // ─── ComputedListenable ───────────────────────────────────────────────────

  group('ComputedListenable', () {
    // ─── value ───────────────────────────────────────────────────────────────

    group('value', () {
      test('derives its initial value from the compute function', () {
        final source = SignalNotifier(3);
        final c = ComputedNotifier((_) => source() * 2);
        expect(c.value, 6);
        c.dispose();
        source.dispose();
      });

      test('value updates when a dependent signal changes', () async {
        final source = SignalNotifier(1);
        final c = ComputedNotifier((_) => source() + 10);

        source.value = 5;
        await Future<void>.delayed(Duration.zero);

        expect(c.value, 15);
        c.dispose();
        source.dispose();
      });

      test('prev is null on the first computation', () {
        int? recordedPrev;
        final source = SignalNotifier(0);
        final c = ComputedNotifier<int>((prev) {
          recordedPrev = prev;
          return source();
        });
        c.value; // trigger first evaluation
        expect(recordedPrev, isNull);
        c.dispose();
        source.dispose();
      });

      test('prev carries the last computed value on subsequent calls',
          () async {
        final source = SignalNotifier(0);
        int? lastPrev;
        final c = ComputedNotifier<int>((prev) {
          lastPrev = prev;
          return source() * 2;
        });

        c.value; // initial: prev == null, result == 0
        source.value = 3;
        await Future<void>.delayed(Duration.zero);
        c.value; // re-evaluate: prev == 0

        expect(lastPrev, 0);
        c.dispose();
        source.dispose();
      });
    });

    // ─── hasListeners ────────────────────────────────────────────────────────

    group('hasListeners', () {
      test('is false with no listeners', () {
        final source = SignalNotifier(0);
        final c = ComputedNotifier((_) => source());
        expect(c.hasListeners, isFalse);
        c.dispose();
        source.dispose();
      });

      test('is true after addListener', () {
        final source = SignalNotifier(0);
        final c = ComputedNotifier((_) => source());
        c.addListener(() {});
        expect(c.hasListeners, isTrue);
        c.dispose();
        source.dispose();
      });

      test('is false after the listener is removed', () {
        final source = SignalNotifier(0);
        final c = ComputedNotifier((_) => source());
        void listener() {}
        c.addListener(listener);
        c.removeListener(listener);
        expect(c.hasListeners, isFalse);
        c.dispose();
        source.dispose();
      });
    });

    // ─── addListener / removeListener ────────────────────────────────────────

    group('addListener', () {
      test('listener fires when the derived value changes', () async {
        final source = SignalNotifier(0);
        final c = ComputedNotifier((_) => source() * 10);
        var callCount = 0;
        c.addListener(() => callCount++);

        source.value = 2;
        await Future<void>.delayed(Duration.zero);

        expect(callCount, 1);
        c.dispose();
        source.dispose();
      });

      test('listener is NOT called on initial attach', () async {
        final source = SignalNotifier(0);
        final c = ComputedNotifier((_) => source());
        var callCount = 0;
        c.addListener(() => callCount++);

        await Future<void>.delayed(Duration.zero);

        expect(callCount, 0);
        c.dispose();
        source.dispose();
      });

      test('multiple listeners all fire on change', () async {
        final source = SignalNotifier(0);
        final c = ComputedNotifier((_) => source());
        var callA = 0;
        var callB = 0;
        c.addListener(() => callA++);
        c.addListener(() => callB++);

        source.value = 1;
        await Future<void>.delayed(Duration.zero);

        expect(callA, 1);
        expect(callB, 1);
        c.dispose();
        source.dispose();
      });

      test('re-adding the same listener replaces the previous subscription',
          () async {
        final source = SignalNotifier(0);
        final c = ComputedNotifier((_) => source());
        var callCount = 0;
        void listener() => callCount++;

        c.addListener(listener);
        c.addListener(listener); // replaces previous effect

        source.value = 5;
        await Future<void>.delayed(Duration.zero);

        expect(callCount, 1); // only one active effect
        c.dispose();
        source.dispose();
      });
    });

    group('removeListener', () {
      test('removed listener no longer fires on change', () async {
        final source = SignalNotifier(0);
        final c = ComputedNotifier((_) => source());
        var callCount = 0;
        void listener() => callCount++;

        c.addListener(listener);
        c.removeListener(listener);

        source.value = 1;
        await Future<void>.delayed(Duration.zero);

        expect(callCount, 0);
        c.dispose();
        source.dispose();
      });
    });

    // ─── notifyListeners ─────────────────────────────────────────────────────

    group('notifyListeners', () {
      test('triggers listeners without changing the computation', () async {
        final source = SignalNotifier(5);
        final c = ComputedNotifier((_) => source());
        var callCount = 0;
        c.addListener(() => callCount++);

        c.notifyListeners();
        await Future<void>.delayed(Duration.zero);

        expect(callCount, 1);
        expect(c.value, 5);
        c.dispose();
        source.dispose();
      });
    });

    // ─── call() ──────────────────────────────────────────────────────────────

    group('call()', () {
      test('returns the current computed value', () {
        final source = SignalNotifier(4);
        final c = ComputedNotifier((_) => source() * 3);
        expect(c(), 12);
        c.dispose();
        source.dispose();
      });
    });

    // ─── .from constructor ───────────────────────────────────────────────────

    group('.from constructor', () {
      test('shares value with the underlying Computed signal', () {
        final source = signal(5);
        final c = computed((_) => source() * 3);
        final listenable = ComputedNotifier.from(c);
        expect(listenable.value, 15);
        listenable.dispose();
      });

      test('reflects changes when the upstream signal mutates', () async {
        final source = signal(1);
        final c = computed((_) => source() + 100);
        final listenable = ComputedNotifier.from(c);

        source.set(9);
        await Future<void>.delayed(Duration.zero);

        expect(listenable.value, 109);
        listenable.dispose();
      });

      test('listener fires when the underlying Computed reacts', () async {
        final source = signal(0);
        final c = computed((_) => source() * 2);
        final listenable = ComputedNotifier.from(c);
        var callCount = 0;
        listenable.addListener(() => callCount++);

        source.set(4);
        await Future<void>.delayed(Duration.zero);

        expect(callCount, 1);
        expect(listenable.value, 8);
        listenable.dispose();
      });

      test('listener is NOT called on initial attach', () async {
        final source = signal(0);
        final c = computed((_) => source());
        final listenable = ComputedNotifier.from(c);
        var callCount = 0;
        listenable.addListener(() => callCount++);

        await Future<void>.delayed(Duration.zero);

        expect(callCount, 0);
        listenable.dispose();
      });

      test('dispose does not affect the original Computed signal', () {
        final source = signal(3);
        final c = computed((_) => source() * 10);
        final listenable = ComputedNotifier.from(c);
        listenable.dispose();
        expect(listenable.isDisposed, isTrue);
        // The underlying Computed is still readable.
        expect(untrack(c), 30);
      });
    });

    // ─── chained computation ──────────────────────────────────────────────────

    group('chained computation', () {
      test('downstream ComputedListenable reacts when source changes',
          () async {
        final source = SignalNotifier(1);
        final doubled = ComputedNotifier((_) => source() * 2);
        final quadrupled = ComputedNotifier((_) => doubled() * 2);
        var callCount = 0;
        quadrupled.addListener(() => callCount++);

        source.value = 3;
        await Future<void>.delayed(Duration.zero);

        expect(quadrupled.value, 12);
        expect(callCount, 1);
        quadrupled.dispose();
        doubled.dispose();
        source.dispose();
      });
    });

    // ─── dispose ─────────────────────────────────────────────────────────────

    group('dispose', () {
      test('calling dispose does not throw', () {
        final source = SignalNotifier(0);
        final c = ComputedNotifier((_) => source());
        c.addListener(() {});
        expect(c.dispose, returnsNormally);
        source.dispose();
      });

      test('isDisposed is true after dispose', () {
        final source = SignalNotifier(0);
        final c = ComputedNotifier((_) => source());
        expect(c.isDisposed, isFalse);
        c.dispose();
        expect(c.isDisposed, isTrue);
        source.dispose();
      });

      test('hasListeners is false after dispose (effects cleared)', () {
        final source = SignalNotifier(0);
        final c = ComputedNotifier((_) => source());
        c.addListener(() {});
        c.dispose();
        expect(c.hasListeners, isFalse);
        source.dispose();
      });

      test('value asserts after dispose', () {
        final source = SignalNotifier(0);
        final c = ComputedNotifier((_) => source());
        c.dispose();
        expect(() => c.value, throwsA(isA<AssertionError>()));
        source.dispose();
      });

      test('addListener asserts after dispose', () {
        final source = SignalNotifier(0);
        final c = ComputedNotifier((_) => source());
        c.dispose();
        expect(() => c.addListener(() {}), throwsA(isA<AssertionError>()));
        source.dispose();
      });

      test('notifyListeners asserts after dispose', () {
        final source = SignalNotifier(0);
        final c = ComputedNotifier((_) => source());
        c.dispose();
        expect(c.notifyListeners, throwsA(isA<AssertionError>()));
        source.dispose();
      });

      test('call() asserts after dispose', () {
        final source = SignalNotifier(0);
        final c = ComputedNotifier((_) => source());
        c.dispose();
        expect(c.call, throwsA(isA<AssertionError>()));
        source.dispose();
      });

      test('removeListener asserts after dispose', () {
        final source = SignalNotifier(0);
        final c = ComputedNotifier((_) => source());
        c.dispose();
        expect(() => c.removeListener(() {}), throwsA(isA<AssertionError>()));
        source.dispose();
      });
    });
  });
}
