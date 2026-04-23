import 'package:zensignals/zensignals.dart';

import 'package:alien_signals/alien_signals.dart' as alien
    show effect, effectScope;

export 'package:alien_signals/preset.dart';

/// Helper extension to dispose of an [Effect].
extension EffectDisposeHelper on Effect {
  /// Disposes of this effect, cancelling it and removing it from the global
  /// effect registry.
  @pragma('vm:prefer-inline')
  void dispose() => call();
}

/// Helper extension to dispose of an [EffectScope].
extension EffectScopeDisposeHelper on EffectScope {
  /// Disposes of this effect, cancelling it and removing it from the global
  /// effect registry.
  @pragma('vm:prefer-inline')
  void dispose() => call();
}

/// Creates a [SignalNotifier] with the given [initialValue].
///
/// This is a convenience factory for concise signal creation:
///
/// ```dart
/// final count = signal(0);
/// count.set(1);
/// final current = count(); // reactive read
/// ```
SignalNotifier<T> signal<T>(T initialValue) => SignalNotifier<T>(initialValue);

/// Creates a [ComputedNotifier] derived from other reactive values.
///
/// The [compute] callback is re-run whenever any signal read with call syntax
/// inside it changes. The previous computed value is provided via [prev]
/// (`null` on first evaluation).
///
/// ```dart
/// final first = signal('Ada');
/// final last = signal('Lovelace');
/// final fullName = computed((_) => '${first()} ${last()}');
/// ```
ComputedNotifier<T> computed<T>(T Function(T? prev) compute) =>
    ComputedNotifier<T>(compute);

/// Creates a reactive [Effect] that re-runs [fn] whenever any signal read
/// inside it changes.
///
/// The [firstCall] argument passed to [fn] is `true` on the initial run and
/// `false` on every subsequent reactive re-run. Use it to skip side effects
/// that should only fire on *changes* (prints, API calls, etc.), while still
/// reading every signal you want to track.
///
/// **Signals must be read on every run, including the first.** The initial run
/// is how `alien_signals` discovers which signals to watch. Returning early
/// before any reads registers zero dependencies and the effect will never
/// re-run.
///
/// ```dart
/// final count = signal(0);
/// final e = effect((firstCall) {
///   final current = count(); // always read to register the dependency
///   if (firstCall) return;   // skip side effect on the initial run
///   print('count changed to $current');
/// });
/// ```
///
/// Remember to call [Effect.dispose] (or let [ReactiveNotifierMixin] dispose it)
/// when the effect is no longer needed.
Effect effect(void Function(bool firstCall) fn) {
  bool firstCall = true;
  return alien.effect(() {
    fn(firstCall);
    firstCall = false;
  });
}

/// Creates a reactive [EffectScope] that groups one or more effects together
/// so they can all be stopped at once.
///
/// The [firstCall] argument passed to [fn] is `true` on the initial run and
/// `false` on every subsequent reactive re-run.
EffectScope effectScope(void Function(bool firstCall) fn) {
  bool firstCall = true;
  return alien.effectScope(() {
    fn(firstCall);
    firstCall = false;
  });
}
