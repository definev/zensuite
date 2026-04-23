## 1.0.0

Initial release of `zensignals`.

- Add fine-grained reactive state primitives:
  - `signal` / `SignalNotifier`
  - `computed` / `ComputedNotifier`
  - `effect` / `effectScope`
  - `batch`
  - `untrack`
- Add Flutter integration utilities:
  - `ReactiveNotifierMixin` for notifier ownership/listening lifecycle in `State`
  - `SignalBuilder` for dependency-tracked widget rebuilds
- Add helper extensions for disposing `Effect` / `EffectScope`
- Add comprehensive documentation and package README
- Add test coverage for notifier behavior, builder behavior, mixin lifecycle, and presets/helpers
