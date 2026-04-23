# ZenSignals

[![Pub](https://img.shields.io/pub/v/zensignals.svg)](https://pub.dev/packages/zensignals)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=flat&logo=dart&logoColor=white)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Fine-grained reactive state for Flutter, bridging `alien_signals` and the `ValueNotifier` ecosystem.**

ZenSignals wraps the battle-tested [`alien_signals`](https://pub.dev/packages/alien_signals) reactive core and exposes it through familiar Flutter primitives — `ValueNotifier`, `ValueListenable`, `ChangeNotifier` — so you get push-based reactivity without abandoning the widgets you already know.

---

## Table of contents

- [Core concepts](#core-concepts)
- [Getting started](#getting-started)
- [API reference](#api-reference)
  - [signal / SignalNotifier](#signal--signalnotifier)
  - [computed / ComputedNotifier](#computed--computednotifier)
  - [effect / effectScope](#effect--effectscope)
  - [batch](#batch)
  - [untrack](#untrack)
  - [ReactiveNotifierMixin](#reactivenotifiermixin)
  - [SignalBuilder](#signalbuilder)
- [Reading values: reactive vs non-reactive](#reading-values-reactive-vs-non-reactive)
- [Lifecycle and disposal](#lifecycle-and-disposal)
- [ZenSuite integration](#zensuite-integration)

---

## Core concepts

| Concept | What it is |
|---------|-----------|
| **Signal** | A mutable reactive value. Notify dependants automatically when changed. |
| **Computed** | A read-only value derived from one or more signals. Re-evaluates only when its sources change. |
| **Effect** | A side-effectful reaction that re-runs when any signal it reads changes. |
| **Batch** | Defers notifications until a block of updates finishes, coalescing multiple changes into one flush. |
| **Untrack** | Reads a signal's current value without registering a reactive dependency. |

---

## Getting started

Add the dependency:

```yaml
dependencies:
  zensignals: ^0.0.1
```

Import the library:

```dart
import 'package:zensignals/zensignals.dart';
```

---

## API reference

### `signal` / `SignalNotifier`

`signal<T>(T initialValue)` creates a `SignalNotifier<T>` — a mutable reactive value that implements both `ValueNotifier<T>` (Flutter ecosystem) and `WritableSignal<T>` (alien_signals).

```dart
final count = signal(0);

// Write
count.value = 1;
count.set(2);   // equivalent to count.value = 2

// Read (non-reactive — does not track in effects/computed)
print(count.value);

// Read (reactive — registers dependency inside effect/computed)
final current = count();
```

**`SignalNotifier.from`** wraps an existing `WritableSignal` from `alien_signals`:

```dart
final raw = alien_signals.signal(42);
final notifier = SignalNotifier.from(raw);
```

---

### `computed` / `ComputedNotifier`

`computed<T>(T Function(T? prev) compute)` creates a `ComputedNotifier<T>` — a read-only reactive value derived from other signals. It implements `ValueListenable<T>` and `Computed<T>`.

The `prev` parameter holds the previous computed value (`null` on the first evaluation), enabling accumulation or diff-based logic.

```dart
final firstName = signal('Ada');
final lastName  = signal('Lovelace');

final fullName = computed((_) => '${firstName()} ${lastName()}');

print(fullName.value); // "Ada Lovelace"

firstName.value = 'Grace';
print(fullName.value); // "Grace Lovelace"
```

**Chaining computeds:**

```dart
final count   = signal(1);
final doubled = computed((_) => count() * 2);
final label   = computed((_) => 'doubled = ${doubled()}');
```

**`ComputedNotifier.from`** wraps an existing `Computed` from `alien_signals`:

```dart
final raw = alien_signals.computed((_) => 42);
final notifier = ComputedNotifier.from(raw);
```

---

### `effect` / `effectScope`

`effect(void Function(bool firstCall) fn)` creates a reactive side effect that re-runs whenever any signal read inside `fn` changes.

The `firstCall` parameter is `true` on the initial run and `false` on every subsequent re-run. It lets you skip side effects that should only happen on *changes* (prints, network calls, etc.) while still reading every signal you need to track.

> **Important:** signals and computeds must be read with the **call syntax** (`signal()`) on **every** run — including the first one. The first run is how `alien_signals` discovers what dependencies to watch. Returning early before any reads means no dependencies are registered and the effect will never react.

```dart
final count = signal(0);

final stop = effect((firstCall) {
  final current = count(); // always read to register the dependency
  if (firstCall) return;   // skip the side effect on the initial run
  print('count changed to $current');
});

count.value = 1; // prints "count changed to 1"
count.value = 2; // prints "count changed to 2"

stop.dispose(); // stop the effect
```

`effectScope` groups multiple effects so they can all be stopped at once:

```dart
final scope = effectScope((_) {
  effect((_) => print('a: ${a()}'));
  effect((_) => print('b: ${b()}'));
});

scope.dispose(); // stops both effects
```

---

### `batch`

Defers all reactive notifications until the callback completes. Useful when updating multiple signals that drive the same computation, avoiding intermediate re-renders.

```dart
final x = signal(1);
final y = signal(2);
final sum = computed((_) => x() + y());

batch(() {
  x.value = 10;
  y.value = 20;
  // sum is NOT re-evaluated yet
});
// sum is re-evaluated exactly once here → 30
```

---

### `untrack`

Reads a signal inside a reactive context without creating a dependency. The enclosing effect or computed will not re-run when that signal changes.

```dart
final a = signal(1);
final b = signal(2);

final result = computed((_) {
  final aVal = a();                     // tracked — reruns when a changes
  final bSnapshot = untrack(() => b()); // NOT tracked — ignores b changes
  return aVal + bSnapshot;
});
```

---

### `ReactiveNotifierMixin`

A `State` mixin that automates signal ownership and widget rebuilds. It handles `addListener`/`removeListener` and `dispose` for you.

```dart
class _CounterState extends State<CounterWidget>
    with ReactiveNotifierMixin<CounterWidget> {

  late final count   = createSignal(0);
  late final doubled = createComputed((_) => count() * 2);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('count:   ${count.value}'),
      Text('doubled: ${doubled.value}'),
      ElevatedButton(
        onPressed: () => count.value++,
        child: const Text('Increment'),
      ),
    ]);
  }
}
```

**Ownership vs. listening:**

| Method | Owns (disposes on State.dispose) | Triggers rebuild |
|--------|----------------------------------|------------------|
| `createSignal` / `createComputed` | ✅ | ✅ by default |
| `attach(notifier)` | ✅ | optional via `listen:` param |
| `listen(notifier)` | ❌ | ✅ |

Use `listen` to observe an externally-owned notifier without taking responsibility for its lifetime. Pair with `unlisten` for manual cleanup:

```dart
@override
void initState() {
  super.initState();
  listen(widget.externalNotifier); // no ownership
}
```

Use `attach` when the `State` should own the notifier's lifecycle but you created it outside `createSignal`/`createComputed`:

```dart
final myNotifier = SignalNotifier(42);
attach(myNotifier); // owned + listened
```

Use `detach` to release ownership and stop listening without disposing:

```dart
detach(myNotifier); // caller must dispose myNotifier themselves
```

---

### `SignalBuilder`

A drop-in widget for reactive subtrees. Any signal read with the **call syntax** (`signal()`) inside `builder` automatically becomes a dependency — the widget rebuilds whenever any of those signals change.

```dart
final counter = signal(0);
final label   = signal('count');

SignalBuilder(
  builder: (context) {
    return Text('${label()}: ${counter()}');
  },
);
```

| Syntax inside `builder` | Reactive? |
|------------------------|-----------|
| `signal()` — call syntax | ✅ Yes — widget rebuilds on change |
| `signal.value` — property | ❌ No — snapshot only |

**Hot reload:** by default `forceRebuild` is `true` in `kDebugMode`, recreating the computed context on every build so structural changes to `builder` are picked up immediately. Set `forceRebuild: false` to opt out.

---

## Reading values: reactive vs non-reactive

Every `SignalNotifier` and `ComputedNotifier` supports two read modes:

```dart
final n = signal(10);

// Inside an effect or computed: reactive (tracks dependency)
final reactive = n();        // call syntax

// Anywhere: non-reactive snapshot (does NOT track)
final snapshot = n.value;    // property access
```

Use `untrack` when you need a snapshot inside a reactive context but explicitly do not want a dependency:

```dart
computed((_) {
  final tracked   = a();
  final untracked = untrack(() => b());
  return tracked + untracked;
});
```

---

## Lifecycle and disposal

All notifiers must be disposed when no longer needed to stop internal effects and prevent memory leaks.

```dart
final n = signal(0);
final c = computed((_) => n() * 2);
final e = effect((_) => print(n()));

n.dispose();
c.dispose();
e.dispose(); // or e.call()
```

When using `ReactiveNotifierMixin`, all signals and computeds created with `createSignal`/`createComputed` are disposed automatically when the `State` is disposed — you do not need to manage them manually.

---

## ZenSuite integration

ZenSignals is part of the [ZenSuite](https://github.com/definev/zensuite) monorepo. It serves as the **reactive state layer** — providing fine-grained, push-based reactivity to Flutter widgets — complementing the other pillars:

| Package | Role |
|---------|------|
| **ZenSignals** | Fine-grained reactive state (this package) |
| **[ZenBus](../zenbus)** | High-performance event bus for cross-component communication |
| **[ZenQuery](../zenquery)** | Async state management for data fetching and mutations |

A typical ZenSuite data-flow using ZenSignals:

```dart
// 1. Define reactive state with ZenSignals
final userSignal = signal<User?>(null);

// 2. Derive UI state via computed
final displayName = computed((_) => userSignal()?.name ?? 'Guest');

// 3. Bind to UI with SignalBuilder — zero boilerplate
SignalBuilder(
  builder: (_) => Text('Hello, ${displayName()}'),
);

// 4. ZenBus events update signals; ZenQuery persists/fetches data
```

---

## License

MIT © [Bui Dai Duong](https://github.com/definev)
