import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zensignals/src/mixin.dart';

/// A widget that automatically rebuilds when any reactive signal accessed
/// inside its [builder] changes.
///
/// [SignalBuilder] uses [ReactiveNotifierMixin] under the hood. On each build
/// it runs [builder] inside a `computed` context, so every signal **read**
/// inside [builder] becomes a dependency — the widget re-renders whenever any
/// of those signals emit a new value.
///
/// ## Reading signal values inside the builder
///
/// There are two ways to read a [SignalNotifier] (or any alien-signals `Signal`):
///
/// | Syntax | Reactive? | When to use |
/// |--------|-----------|-------------|
/// | `signal()` | ✅ Yes — registers as a dependency | Inside [SignalBuilder] / `computed` — the widget will rebuild when `signal` changes |
/// | `signal.value` | ❌ No — plain property access | Outside reactive context, or when you intentionally don't want a rebuild |
///
/// **Always use `signal()` (call syntax) inside [builder].** Using
/// `signal.value` inside [builder] will read the current value but NOT
/// subscribe to future changes, so the widget will not rebuild.
///
/// ## Example
///
/// ```dart
/// // Somewhere in your State / ViewModel:
/// final counter = SignalNotifier(0);
/// final label   = SignalNotifier('hello');
///
/// // In your widget tree:
/// SignalBuilder(
///   builder: (context) {
///     // ✅ Reactive reads — widget rebuilds when either signal changes.
///     final count = counter();  // call syntax
///     final text  = label();    // call syntax
///
///     // ❌ Non-reactive read — widget will NOT rebuild when `counter` changes.
///     // final count = counter.value;
///
///     return Text('$text: $count');
///   },
/// )
/// ```
///
/// ## Hot reload
///
/// By default [forceRebuild] is `true` in debug mode ([kDebugMode]) so that
/// hot-reloads recreate the computed context and pick up structural changes
/// to [builder]. Set [forceRebuild] to `false` to opt out.
class SignalBuilder extends StatefulWidget {
  const SignalBuilder({super.key, required this.builder, this.forceRebuild});

  /// Called every time a dependency signal changes. Read signals with the
  /// **call syntax** (`signal()`) to register them as dependencies.
  final WidgetBuilder builder;

  /// When `true`, the computed context is recreated on every build, which
  /// allows hot-reload to pick up structural changes to [builder].
  ///
  /// Defaults to [kDebugMode] when `null`.
  final bool? forceRebuild;

  @override
  State<SignalBuilder> createState() => SignalBuilderViewModel();
}

class SignalBuilderViewModel extends State<SignalBuilder>
    with ReactiveNotifierMixin {
  late var computedWidget = createComputed((_) => widget.builder(context));
  bool isFirstBuild = true;

  @override
  Widget build(BuildContext context) {
    if (isFirstBuild) {
      isFirstBuild = false;
      return computedWidget.value;
    }
    // Support hot reload rebuilt by force recreate computed widget everytime
    if (widget.forceRebuild ?? kDebugMode) {
      detach(computedWidget);
      computedWidget = createComputed((_) => widget.builder(context));
    }
    return computedWidget.value;
  }
}
