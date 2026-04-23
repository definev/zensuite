# ZenSuite

[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=flat&logo=dart&logoColor=white)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**The opinionated, high-performance data flow architecture for Flutter.**

ZenSuite provides a cohesive set of tools for building scalable, type-safe, and performant Flutter applications. It separates concerns into three complementary pillars: **Fine-Grained Reactive State**, **Event-Driven Communication**, and **Asynchronous State Management**.

---

## 🏛️ Architecture

ZenSuite decouples your application logic across three layers: *reactive state* (ZenSignals), *events* (ZenBus), and *async data* (ZenQuery).

```mermaid
graph TD
    UI[Flutter UI]

    subgraph ZenSuite
        ZS[ZenSignals\nreactive state]
        ZB[ZenBus\nevent bus]
        ZQ[ZenQuery\nasync data]
    end

    subgraph External
        API[Backend API]
        DB[Local Database]
    end

    %% Flows
    ZS -- "1. Drives widget rebuilds" --> UI
    UI -- "2. Dispatches Event" --> ZB
    ZB -- "3. Triggers Side Effect" --> ZQ
    ZQ -- "4. Fetches/Mutates Data" --> API
    ZQ -- "5. Updates Signals" --> ZS

    %% Styles
    classDef flutter fill:#02569B,stroke:#fff,color:#fff;
    classDef suite fill:#4B2C20,stroke:#D7B19D,color:#fff;
    classDef ext fill:#333,stroke:#fff,color:#fff;

    class UI flutter;
    class ZS,ZB,ZQ suite;
    class API,DB ext;
```

---

## 📦 Packages

| Package | Version | Description |
|---------|---------|-------------|
| **[ZenSignals](./packages/zensignals)** | [![Pub](https://img.shields.io/pub/v/zensignals.svg)](https://pub.dev/packages/zensignals) | Fine-grained reactive state bridging `alien_signals` and `ValueNotifier`. |
| **[ZenBus](./packages/zenbus)** | [![Pub](https://img.shields.io/pub/v/zenbus.svg)](https://pub.dev/packages/zenbus) | Blazing-fast event bus with `Stream` and `AlienSignals` engines. |
| **[ZenQuery](./packages/zenquery)** | [![Pub](https://img.shields.io/pub/v/zenquery.svg)](https://pub.dev/packages/zenquery) | Async state management wrapper around Riverpod. |

### [ZenSignals](./packages/zensignals)
*Fine-grained reactive state.*
- ⚡ **Push-based**: Signals propagate changes directly to dependants — no polling, no unnecessary rebuilds.
- 🔗 **Flutter-native**: `SignalNotifier` and `ComputedNotifier` implement `ValueNotifier` / `ValueListenable`, so they work with any existing Flutter widget.
- 🧹 **Zero boilerplate**: `ReactiveNotifierMixin` and `SignalBuilder` handle subscriptions and disposal automatically.

### [ZenBus](./packages/zenbus)
*High-performance event bus.*
- 🚀 **Fast**: Up to 51x faster than standard Streams.
- 🎯 **Type-Safe**: Generic event handling.
- 🧠 **Efficient**: Zero-overhead memory usage.

### [ZenQuery](./packages/zenquery)
*Async state management.*
- 🔄 **Standardized**: Stores, Queries, and Mutations.
- ∞ **Infinite Scroll**: Native support for pagination.
- 🔮 **Optimistic Updates**: Immediate UI feedback.

---

## � Getting Started

ZenSuite is a monorepo. You can use packages individually or together.

1. **Add dependencies**:
   ```yaml
   dependencies:
     zensignals: ^0.0.1
     zenbus: ^1.0.0
     zenquery: ^1.0.0
   ```

2. **Setup your root provider** (if using ZenQuery):
   ```dart
   void main() {
     runApp(
       ProviderScope(
         child: MyApp(),
       ),
     );
   }
   ```

3. **Explore the docs**:
   - [ZenSignals Documentation](./packages/zensignals/README.md)
   - [ZenBus Documentation](./packages/zenbus/README.md)
   - [ZenQuery Documentation](./packages/zenquery/README.md)

---

## 🤝 Contributing

We welcome contributions! This is a monorepo managed with simple workspace structure.

1. **Clone the repo**:
   ```bash
   git clone https://github.com/definev/zensuite.git
   ```

2. **Install dependencies**:
   ```bash
   dart pub get
   ```

3. **Run tests**:
   ```bash
   cd packages/zensignals && flutter test
   cd packages/zenbus && flutter test
   cd packages/zenquery && flutter test
   ```

## � License

MIT © [Bui Dai Duong](https://github.com/definev)
