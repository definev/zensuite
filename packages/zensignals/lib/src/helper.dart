import 'package:flutter/foundation.dart';
import 'package:zensignals/zensignals.dart';

extension SignalNotifierCast<T> on ValueNotifier<T> {
  SignalNotifier<T> get cast => this as SignalNotifier<T>;
}
