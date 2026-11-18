// ignore_for_file: public_member_api_docs, use_setters_to_change_properties

import 'package:flutter/foundation.dart';

/// @macro [ValueNotifierBeacon]
class ValueNotifierBeacon<T> extends ValueNotifier<T> {
  ValueNotifierBeacon(super.value);

  final disposeListeners = <VoidCallback>[];

  var _isDisposed = false;

  /// Whether this notifier has already been disposed.
  bool get isDisposed => _isDisposed;

  void addDisposeCallback(VoidCallback callback) {
    disposeListeners.add(callback);
  }

  void set(T newValue) {
    value = newValue;
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    for (final cb in disposeListeners) {
      cb();
    }
    super.dispose();
  }
}
