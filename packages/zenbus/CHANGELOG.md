## 1.0.3
- Fixed an issue where data was filtered incorrectly when the type T was already T?. (Thanks @medz)
- ZenBus does not rely on Flutter, therefore the unnecessary dependency restrictions have been removed. (Thanks @medz)

## 1.0.2

- Added `dispose` method to all implementations.

## 1.0.1

- Fixed `AlienSignals` implementation to skip the first call prevent recursive calls.

## 1.0.0

- Initial release of ZenBus.
- Added `ZenBus` class with `Stream` and `AlienSignals` implementations.
- Added event filtering and typed events.
