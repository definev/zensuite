import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zensignals/zensignals.dart';

// ─── Test Widget ─────────────────────────────────────────────────────────────

class _TestWidget extends StatefulWidget {
  const _TestWidget({required this.onBuild, this.externalNotifier});

  final void Function() onBuild;
  final ValueNotifier<int>? externalNotifier;

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget>
    with ReactiveNotifierMixin<_TestWidget> {
  late final local = createSignal(0);

  @override
  void initState() {
    super.initState();
    if (widget.externalNotifier != null) {
      listen(widget.externalNotifier!);
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.onBuild();
    return Text('${local.value}', textDirection: TextDirection.ltr);
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('ValueNotifierListMixin', () {
    // ─── createLocalNotifier ─────────────────────────────────────────────────

    group('createLocalNotifier', () {
      testWidgets('local notifier initial value is rendered', (tester) async {
        await tester.pumpWidget(_wrap(_TestWidget(onBuild: () {})));

        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('widget rebuilds when local notifier value changes',
          (tester) async {
        var buildCount = 0;
        late _TestWidgetState state;

        await tester
            .pumpWidget(_wrap(_TestWidget(onBuild: () => buildCount++)));
        state = tester.state<_TestWidgetState>(find.byType(_TestWidget));
        final initialBuildCount = buildCount;

        state.local.value = 5;
        await tester.pumpAndSettle();

        expect(buildCount, greaterThan(initialBuildCount));
        expect(find.text('5'), findsOneWidget);
      });
    });

    // ─── addListenableNotifier / removeListenableNotifier ────────────────────

    group('addListenableNotifier', () {
      testWidgets('rebuilds when external notifier changes', (tester) async {
        var buildCount = 0;
        final external = SignalNotifier(0);

        await tester.pumpWidget(_wrap(_TestWidget(
            onBuild: () => buildCount++, externalNotifier: external)));
        final initialBuildCount = buildCount;

        external.value = 1;
        await tester.pumpAndSettle();

        expect(buildCount, greaterThan(initialBuildCount));
        external.dispose();
      });
    });

    group('removeListenableNotifier', () {
      testWidgets('widget does NOT rebuild after listener is removed',
          (tester) async {
        var buildCount = 0;
        final external = SignalNotifier(0);

        await tester.pumpWidget(_wrap(_TestWidget(
            onBuild: () => buildCount++, externalNotifier: external)));

        final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));
        state.unlisten(external);

        final countAfterRemove = buildCount;

        external.value = 42;
        await tester.pumpAndSettle();

        expect(buildCount, countAfterRemove); // no extra rebuild
        external.dispose();
      });
    });

    // ─── listen / unlisten ───────────────────────────────────────────────────

    group('listen / unlisten', () {
      testWidgets('listen causes rebuild on notifier change', (tester) async {
        var buildCount = 0;
        await tester
            .pumpWidget(_wrap(_TestWidget(onBuild: () => buildCount++)));
        final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

        final extra = SignalNotifier(7);
        state.attach(extra);
        final countBeforeChange = buildCount;

        extra.value = 8;
        await tester.pumpAndSettle();

        expect(buildCount, greaterThan(countBeforeChange));
        extra.dispose();
      });

      testWidgets('unlisten stops rebuilds from that notifier', (tester) async {
        var buildCount = 0;
        await tester
            .pumpWidget(_wrap(_TestWidget(onBuild: () => buildCount++)));
        final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

        final extra = SignalNotifier(0);
        state.attach(extra);
        state.detach(extra);
        final countAfterUnlisten = buildCount;

        extra.value = 99;
        await tester.pumpAndSettle();

        expect(buildCount, countAfterUnlisten);
        extra.dispose();
      });
    });

    // ─── dispose ─────────────────────────────────────────────────────────────

    group('dispose', () {
      testWidgets(
          'local notifiers are disposed when widget is removed from tree',
          (tester) async {
        late _TestWidgetState state;

        await tester.pumpWidget(_wrap(_TestWidget(onBuild: () {})));
        state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

        expect(state.local.isDisposed, isFalse);

        // Replace widget tree with an empty container (triggers dispose).
        await tester.pumpWidget(_wrap(const SizedBox()));

        // The local notifier should have been disposed by the mixin.
        expect(state.local.isDisposed, isTrue);
      });

      testWidgets('external listenable notifiers are unsubscribed on dispose',
          (tester) async {
        var buildCount = 0;
        final external = SignalNotifier(0);

        await tester.pumpWidget(_wrap(_TestWidget(
            onBuild: () => buildCount++, externalNotifier: external)));

        // Tear down the widget.
        await tester.pumpWidget(_wrap(const SizedBox()));

        final countAfterDispose = buildCount;

        external.value = 1;
        await tester.pumpAndSettle();

        // No rebuild should happen after the widget's lifecycle ended.
        expect(buildCount, countAfterDispose);
        external.dispose();
      });
    });
  });
}
