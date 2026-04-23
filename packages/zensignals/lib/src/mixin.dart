import 'package:flutter/widgets.dart';

import 'notifier.dart';

/// A mixin for [State] subclasses that simplifies working with reactive
/// [SignalNotifier]s and [ChangeNotifier]s.
///
/// ## Ownership vs. listening
///
/// | Method | Owns (disposes on [dispose]) | Listens (triggers rebuild) |
/// |--------|------------------------------|----------------------------|
/// | [createSignal] / [createComputed] | ✅ | ✅ by default |
/// | [attach] | ✅ | optional via `listen:` |
/// | [listen] | ❌ | ✅ |
///
/// Use [createSignal] for signals that belong to this widget's [State]. Use
/// [listen] to subscribe to an externally-owned notifier without taking
/// ownership of its lifetime.
mixin ReactiveNotifierMixin<T extends StatefulWidget> on State<T> {
  final _ownedNotifiers = <ChangeNotifier>[];
  final _listenableNotifiers = <ChangeNotifier>[];

  void _rebuild() => setState(() {});

  /// Create a new SignalNotifier and listen to it.
  /// If listen is true, the widget will rebuild when the notifier changes. The notifier is disposed when [State] is disposed.
  /// If listen is false, the SignalNotifier is owned by [State] and disposed when [State] is disposed.
  SignalNotifier<S> createSignal<S>(S initialValue, {bool listen = true}) {
    final notifier = SignalNotifier(initialValue);
    attach(notifier, listen: listen);
    return notifier;
  }

  /// Create a new ValueNotifier and listen to it.
  /// If listen is true, the widget will rebuild when the notifier changes. The notifier is disposed when [State] is disposed.
  /// If listen is false, the ValueNotifier is owned by [State] and disposed when [State] is disposed.
  @Deprecated('Use `createSignal` instead.')
  ValueNotifier<S> createValueNotifier<S>(S initialValue,
      {bool listen = true}) {
    final notifier = ValueNotifier(initialValue);
    attach(notifier, listen: listen);
    return notifier;
  }

  /// Creates a [ComputedNotifier] whose value is derived from a [compute]
  /// function.
  ///
  /// The notifier is owned by this [State] (disposed on [dispose]). When
  /// [listen] is `true` (the default) the widget rebuilds whenever the
  /// computed value changes.
  ///
  /// Any signal read inside [compute] using the **call syntax** (`signal()`)
  /// is automatically tracked as a dependency.
  ComputedNotifier<S> createComputed<S>(S Function(S? prev) compute,
      {bool listen = true}) {
    final notifier = ComputedNotifier(compute);
    attach(notifier, listen: listen);
    return notifier;
  }

  /// Subscribes to [notifier] so the widget rebuilds on each notification.
  ///
  /// Unlike [attach], this does **not** take ownership of [notifier] — it will
  /// not be disposed when this [State] is disposed. Pair with [unlisten] to
  /// clean up manually if needed.
  void listen(ChangeNotifier notifier) {
    _listenableNotifiers.add(notifier);
    notifier.addListener(_rebuild);
  }

  /// Removes the rebuild subscription previously added by [listen].
  ///
  /// Safe to call even if [notifier] was never listened to.
  void unlisten(ChangeNotifier notifier) {
    final removed = _listenableNotifiers.remove(notifier);
    if (removed) notifier.removeListener(_rebuild);
  }

  /// Takes ownership of [notifier] so it is disposed when this [State] is
  /// disposed. Optionally also subscribes for rebuilds (default: `true`).
  ///
  /// Prefer [createSignal] or [createComputed] over calling this directly.
  void attach(ChangeNotifier notifier, {bool listen = true}) {
    _ownedNotifiers.add(notifier);
    if (listen) this.listen(notifier);
  }

  /// Releases ownership of [notifier] and removes its rebuild subscription.
  ///
  /// The notifier is **not** disposed by this call — the caller is responsible
  /// for its lifetime after detaching.
  void detach(ChangeNotifier notifier) {
    _ownedNotifiers.remove(notifier);
    unlisten(notifier);
  }

  @override
  void dispose() {
    for (final notifier in _listenableNotifiers) {
      notifier.removeListener(_rebuild);
    }
    for (final notifier in _ownedNotifiers) {
      notifier.dispose();
    }
    _listenableNotifiers.clear();
    _ownedNotifiers.clear();
    super.dispose();
  }
}
