import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zensignals/zensignals.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('SignalBuilder', () {
    // ─── initial render ───────────────────────────────────────────────────────

    group('initial render', () {
      testWidgets('renders the initial signal value', (tester) async {
        final count = SignalNotifier(0);

        await tester.pumpWidget(_wrap(SignalBuilder(
            forceRebuild: false, builder: (context) => Text('${count()}'))));

        expect(find.text('0'), findsOneWidget);
        count.dispose();
      });

      testWidgets('renders the initial value of multiple signals',
          (tester) async {
        final a = SignalNotifier('hello');
        final b = SignalNotifier(42);

        await tester.pumpWidget(_wrap(SignalBuilder(
            forceRebuild: false, builder: (context) => Text('${a()} ${b()}'))));

        expect(find.text('hello 42'), findsOneWidget);
        a.dispose();
        b.dispose();
      });
    });

    // ─── reactive rebuild — call syntax ───────────────────────────────────────

    group('reactive rebuild (call syntax)', () {
      testWidgets('rebuilds when a tracked signal changes', (tester) async {
        final count = SignalNotifier(0);

        await tester.pumpWidget(_wrap(SignalBuilder(
            forceRebuild: false, builder: (context) => Text('${count()}'))));

        count.value = 5;
        await tester.pumpAndSettle();

        expect(find.text('5'), findsOneWidget);
        count.dispose();
      });

      testWidgets('rebuilds when any of multiple tracked signals changes',
          (tester) async {
        final a = SignalNotifier('A');
        final b = SignalNotifier('B');

        await tester.pumpWidget(_wrap(SignalBuilder(
            forceRebuild: false, builder: (context) => Text('${a()} ${b()}'))));

        a.value = 'X';
        await tester.pumpAndSettle();
        expect(find.text('X B'), findsOneWidget);

        b.value = 'Y';
        await tester.pumpAndSettle();
        expect(find.text('X Y'), findsOneWidget);

        a.dispose();
        b.dispose();
      });

      testWidgets('rebuild count matches the number of signal changes',
          (tester) async {
        final count = SignalNotifier(0);
        var buildCount = 0;

        await tester.pumpWidget(
          _wrap(
            SignalBuilder(
              forceRebuild: false,
              builder: (context) {
                buildCount++;
                return Text('${count()}');
              },
            ),
          ),
        );

        final initialBuilds = buildCount;

        count.value = 1;
        await tester.pumpAndSettle();
        count.value = 2;
        await tester.pumpAndSettle();

        expect(buildCount, initialBuilds + 2);
        count.dispose();
      });
    });

    // ─── non-reactive read (.value) ───────────────────────────────────────────

    group('non-reactive read (.value)', () {
      testWidgets('widget does NOT rebuild when signal is read via .value',
          (tester) async {
        final count = SignalNotifier(0);
        var buildCount = 0;

        await tester.pumpWidget(
          _wrap(
            SignalBuilder(
              forceRebuild: false,
              builder: (context) {
                buildCount++;
                // .value — non-reactive, no dependency registered
                return Text('${count.value}');
              },
            ),
          ),
        );

        final buildsAfterMount = buildCount;

        count.value = 99;
        await tester.pumpAndSettle();

        // No extra rebuild should have occurred.
        expect(buildCount, buildsAfterMount);
        // UI still shows the stale value.
        expect(find.text('0'), findsOneWidget);
        count.dispose();
      });
    });

    // ─── computed dependency ──────────────────────────────────────────────────

    group('computed dependency', () {
      testWidgets('rebuilds when a ComputedNotifier dependency changes',
          (tester) async {
        final source = SignalNotifier(1);
        final doubled = ComputedNotifier<int>((_) => source() * 2);

        await tester.pumpWidget(_wrap(SignalBuilder(
            forceRebuild: false, builder: (context) => Text('${doubled()}'))));

        expect(find.text('2'), findsOneWidget);

        source.value = 5;
        await tester.pumpAndSettle();

        expect(find.text('10'), findsOneWidget);
        doubled.dispose();
        source.dispose();
      });
    });

    // ─── forceRebuild ─────────────────────────────────────────────────────────

    group('forceRebuild: false', () {
      testWidgets('still rebuilds on signal change when forceRebuild is false',
          (tester) async {
        final count = SignalNotifier(0);

        await tester.pumpWidget(_wrap(SignalBuilder(
            forceRebuild: false, builder: (context) => Text('${count()}'))));

        count.value = 7;
        await tester.pumpAndSettle();

        expect(find.text('7'), findsOneWidget);
        count.dispose();
      });

      testWidgets('does not recreate computed on parent rebuild',
          (tester) async {
        final tick = ValueNotifier(0);
        var innerBuilds = 0;

        await tester.pumpWidget(
          _wrap(
            ValueListenableBuilder<int>(
              valueListenable: tick,
              builder: (_, __, ___) => SignalBuilder(
                forceRebuild: false,
                builder: (_) {
                  innerBuilds++;
                  return const Text('stable');
                },
              ),
            ),
          ),
        );

        final initial = innerBuilds;
        tick.value++;
        await tester.pumpAndSettle();

        // Parent rebuilt, but SignalBuilder kept its computed instance.
        expect(innerBuilds, initial);
        tick.dispose();
      });
    });

    group('forceRebuild: true', () {
      testWidgets('recreates computed on parent rebuild', (tester) async {
        final tick = ValueNotifier(0);
        var innerBuilds = 0;

        await tester.pumpWidget(
          _wrap(
            ValueListenableBuilder<int>(
              valueListenable: tick,
              builder: (_, __, ___) => SignalBuilder(
                forceRebuild: true,
                builder: (_) {
                  innerBuilds++;
                  return const Text('stable');
                },
              ),
            ),
          ),
        );

        final initial = innerBuilds;
        tick.value++;
        await tester.pumpAndSettle();

        // Parent rebuilt and SignalBuilder recreated computed.
        expect(innerBuilds, initial + 1);
        tick.dispose();
      });
    });

    // ─── untracked signal does not trigger rebuild ────────────────────────────

    group('untracked signal', () {
      testWidgets('changing a signal not read inside builder causes no rebuild',
          (tester) async {
        final tracked = SignalNotifier(0);
        final untracked = SignalNotifier(0);
        var buildCount = 0;

        await tester.pumpWidget(
          _wrap(
            SignalBuilder(
              forceRebuild: false,
              builder: (context) {
                buildCount++;
                return Text('${tracked()}');
              },
            ),
          ),
        );

        final buildsAfterMount = buildCount;

        untracked.value = 99;
        await tester.pumpAndSettle();

        expect(buildCount, buildsAfterMount);
        tracked.dispose();
        untracked.dispose();
      });
    });

    // ─── dispose ─────────────────────────────────────────────────────────────

    group('dispose', () {
      testWidgets('no rebuild after widget is removed from tree',
          (tester) async {
        final count = SignalNotifier(0);
        var buildCount = 0;

        await tester.pumpWidget(
          _wrap(
            SignalBuilder(
              forceRebuild: false,
              builder: (context) {
                buildCount++;
                return Text('${count()}');
              },
            ),
          ),
        );

        // Remove from tree — triggers State.dispose
        await tester.pumpWidget(_wrap(const SizedBox()));
        final buildsAfterRemoval = buildCount;

        count.value = 1;
        await tester.pumpAndSettle();

        expect(buildCount, buildsAfterRemoval);
        count.dispose();
      });
    });
  });
}
