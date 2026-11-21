// ignore_for_file: public_member_api_docs, use_setters_to_change_properties

import 'package:flutter/foundation.dart';

/// @macro [ValueNotifierBeacon]
class ValueNotifierBeacon<T> extends ValueNotifier<T> {
  ValueNotifierBeacon(super.value);

  final disposeListeners = <VoidCallback>[];

  var _isDisposed = false;
  var _hasWriteBack = false;
  var _hasSyncedValue = false;
  T? _syncedValue;

  /// Whether this notifier has already been disposed.
  bool get isDisposed => _isDisposed;

  void addDisposeCallback(VoidCallback callback) {
    if (_isDisposed) return;
    disposeListeners.add(callback);
  }

  /// Registers a single write-back callback for external mutations to [value].
  void enableWriteBack(void Function(T) onSet) {
    if (_hasWriteBack) return;
    _hasWriteBack = true;
    addListener(() {
      if (_hasSyncedValue &&
          (identical(value, _syncedValue) || value == _syncedValue)) {
        return;
      }
      onSet(value);
    });
  }

  void set(T newValue) {
    if (_isDisposed) return;
    _hasSyncedValue = true;
    _syncedValue = newValue;
    try {
      value = newValue;
    } finally {
      _hasSyncedValue = false;
      _syncedValue = null;
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    for (final cb in List<VoidCallback>.of(disposeListeners)) {
      cb();
    }
    disposeListeners.clear();
    super.dispose();
  }
}
