import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/foundation.dart';

import 'untrack.dart';

/// A [ValueNotifier] backed by an [alien_signals] reactive signal.
///
/// [SignalNotifier] bridges Flutter's `Listenable` / `ValueNotifier` ecosystem
/// with `alien_signals` reactivity:
///
/// * It implements both [ValueNotifier] (for use with [ValueListenableBuilder]
///   and [AnimatedBuilder]) **and**
///   [WritableSignal] (so it can be read inside other computed signals /
///   effects as `notifier()`).
/// * Listeners registered via [addListener] are driven by an `alien_signals`
///   [Effect], so they fire automatically whenever [value] or
///   [notifyListeners] triggers a reactive change.
/// * The **first** effect execution is silently skipped to match the
///   `ValueNotifier` contract (listeners are only notified on *changes*, not
///   on initial subscription).
/// * All mutating methods assert `!isDisposed` in debug mode to catch use-
///   after-dispose bugs early.
///
/// ## Basic usage
/// ```dart
/// final counter = SignalNotifier(0);
///
/// counter.addListener(() => print('value: ${counter.value}'));
///
/// counter.value = 1; // prints "value: 1"
/// counter.set(2);    // equivalent – prints "value: 2"
/// counter();         // reads reactively inside an effect / computed
///
/// counter.dispose();
/// ```
class SignalNotifier<T> implements ValueNotifier<T>, WritableSignal<T> {
  /// Creates a [SignalNotifier] with the given [initialValue].
  SignalNotifier(T initialValue) : _signal = signal(initialValue);

  /// Creates a [SignalNotifier] that binds to an existing [WritableSignal].
  SignalNotifier.from(WritableSignal<T> signal) : _signal = signal;

  WritableSignal<T>? _signal;
  final Map<VoidCallback, Effect> _effects = {};
  final WritableSignal<int> _version = signal(0);

  bool _isDisposed = false;

  /// Whether [dispose] has been called.
  ///
  /// Once `true`, all mutating operations (setting [value], calling
  /// [addListener], etc.) will throw an [AssertionError] in debug mode.
  bool get isDisposed => _isDisposed;

  /// The current value, read without tracking reactive dependencies.
  ///
  /// Reading [value] inside an `alien_signals` effect will **not** create a
  /// dependency – use [call] if reactive tracking is needed.
  @override
  T get value {
    final s = _signal;
    assert(s != null, 'SignalNotifier is disposed');
    return untrack(s!);
  }

  /// Updates the underlying signal value and notifies all registered listeners.
  @override
  set value(T value) {
    final s = _signal;
    assert(s != null, 'SignalNotifier is disposed');
    s!.set(value);
  }

  /// Registers [listener] to be called whenever the value changes.
  ///
  /// The listener is **not** called immediately on registration. It will be
  /// invoked (via an `alien_signals` effect) on every subsequent change to
  /// [value] or [notifyListeners] call.
  ///
  /// If [listener] is already registered, the previous subscription is
  /// replaced with a fresh one (idempotent re-registration).
  @override
  void addListener(VoidCallback listener) {
    final s = _signal;
    assert(s != null, 'SignalNotifier is disposed');
    _effects[listener]?.call();
    bool firstCall = true;
    _effects[listener] = effect(() {
      _version();
      s!();
      if (firstCall) {
        firstCall = false;
        return;
      }
      listener();
    });
  }

  /// Cancels all active effects and marks this notifier as disposed.
  ///
  /// After disposal, calling any mutating method will throw an
  /// [AssertionError] in debug mode. [hasListeners] will return `false`.
  @override
  void dispose() {
    _isDisposed = true;
    for (final effect in _effects.values) {
      effect();
    }
    _effects.clear();
    _signal = null;
  }

  /// Whether at least one listener is currently registered.
  @override
  bool get hasListeners => _effects.isNotEmpty;

  /// Forces all registered listeners to be called without changing [value].
  ///
  /// Internally increments an internal version signal, which triggers all
  /// active effects – and therefore all listeners – on the next microtask.
  @override
  void notifyListeners() {
    assert(!_isDisposed, 'SignalNotifier is disposed');
    _version.set(untrack(_version) + 1);
  }

  /// Removes a previously registered [listener].
  ///
  /// If [listener] was not registered, this is a no-op.
  @override
  void removeListener(VoidCallback listener) {
    final effect = _effects.remove(listener);
    if (effect != null) effect();
  }

  /// Reads the current value **with** reactive tracking.
  ///
  /// Use this inside `alien_signals` effects or [ComputedNotifier] compute
  /// functions to create a reactive dependency on this notifier.
  @override
  T call() {
    final s = _signal;
    assert(s != null, 'SignalNotifier is disposed');
    return s!();
  }

  /// Equivalent to `value = value`. Provided to satisfy [WritableSignal].
  @override
  void set(T value) {
    final s = _signal;
    assert(s != null, 'SignalNotifier is disposed');
    s!.set(value);
  }
}

/// A read-only [ValueListenable] whose value is derived reactively from other
/// `alien_signals` signals or [SignalNotifier]s.
///
/// [ComputedNotifier] wraps an `alien_signals` [Computed] signal and exposes
/// it as a Flutter [ValueListenable] so it can be used in
/// [ValueListenableBuilder] and [AnimatedBuilder].
///
/// The [compute] function receives the **previous** computed value (`prev`) on
/// every re-evaluation, which allows accumulation or diff-based computations.
/// `prev` is `null` on the first evaluation.
///
/// Like [SignalNotifier], listeners are **not** called on initial registration –
/// only on subsequent reactive changes. All mutating methods assert
/// `!isDisposed` in debug mode.
///
/// ## Basic usage
/// ```dart
/// final firstName = SignalNotifier('Alice');
/// final lastName  = SignalNotifier('Smith');
///
/// // Derived full name – updates automatically when either source changes.
/// final fullName = ComputedNotifier((_) => '${firstName()} ${lastName()}');
///
/// fullName.addListener(() => print(fullName.value));
///
/// firstName.value = 'Bob'; // prints "Bob Smith"
///
/// fullName.dispose();
/// firstName.dispose();
/// lastName.dispose();
/// ```
///
/// ## Chaining
/// ```dart
/// final count    = SignalNotifier(1);
/// final doubled  = ComputedNotifier((_) => count() * 2);
/// final greeting = ComputedNotifier((_) => 'Count × 4 = ${doubled() * 2}');
/// ```
class ComputedNotifier<T> extends ChangeNotifier
    implements ValueListenable<T>, Computed<T> {
  /// Creates a [ComputedNotifier] whose value is derived by [compute].
  ///
  /// [compute] is called reactively by `alien_signals` whenever any signal
  /// read inside it changes. The `prev` argument holds the result of the
  /// previous computation (`null` on first call).
  ComputedNotifier(T Function(T? prev) compute) : _signal = computed(compute);

  /// Creates a [ComputedNotifier] that binds to an existing [Computed] signal.
  ComputedNotifier.from(Computed<T> signal) : _signal = signal;

  Computed<T>? _signal;
  final Map<VoidCallback, Effect> _effects = {};
  final WritableSignal<int> _version = signal(0);

  bool _isDisposed = false;

  /// Whether [dispose] has been called.
  bool get isDisposed => _isDisposed;

  /// The current derived value, read without tracking reactive dependencies.
  ///
  /// Reading [value] inside another `alien_signals` effect will **not** create
  /// a dependency – use [call] for reactive tracking.
  @override
  T get value {
    final s = _signal;
    assert(s != null, 'ComputedNotifier is disposed');
    return untrack(s!);
  }

  /// Registers [listener] to be called whenever the computed value changes.
  ///
  /// The listener is **not** called immediately on registration. It fires on
  /// every subsequent reactive update to the derived value.
  ///
  /// If [listener] is already registered, any existing subscription is
  /// cancelled before creating a fresh one (idempotent re-registration).
  @override
  void addListener(VoidCallback listener) {
    final s = _signal;
    assert(s != null, 'ComputedNotifier is disposed');
    _effects[listener]?.call();
    bool firstCall = true;
    _effects[listener] = effect(() {
      _version();
      s!();
      if (firstCall) {
        firstCall = false;
        return;
      }
      listener();
    });
  }

  /// Reads the current computed value **with** reactive tracking.
  ///
  /// Use this inside other `alien_signals` effects or [ComputedNotifier]
  /// compute functions to create a reactive dependency on this computation.
  @override
  T call() {
    final s = _signal;
    assert(s != null, 'ComputedNotifier is disposed');
    return s!();
  }

  /// Cancels all active effects, releases the underlying [Computed] signal,
  /// and marks this listenable as disposed.
  ///
  /// After disposal, calling any method will throw an [AssertionError] in
  /// debug mode.
  @override
  void dispose() {
    _isDisposed = true;
    for (final effect in _effects.values) {
      effect();
    }
    _effects.clear();
    _signal = null;
    super.dispose();
  }

  /// Whether at least one listener is currently registered.
  @override
  bool get hasListeners => _effects.isNotEmpty;

  /// Forces all registered listeners to fire without re-running the
  /// [compute] function.
  @override
  void notifyListeners() {
    assert(!_isDisposed, 'ComputedNotifier is disposed');
    _version.set(untrack(_version) + 1);
  }

  /// Removes a previously registered [listener].
  ///
  /// If [listener] was not registered, this is a no-op.
  @override
  void removeListener(VoidCallback listener) {
    assert(!_isDisposed, 'ComputedNotifier is disposed');
    final effect = _effects.remove(listener);
    if (effect != null) effect();
  }
}
