// the input type can differ from the output type
// eg: in the case of buffered beacons,
// the input type is int then the output type is List<int>

part of '../producer.dart';

/// A utility mixin for beacons that consume other beacons.
mixin BeaconWrapper<InputT, OutputT> on ReadableBeacon<OutputT> {
  Map<ReadableBeacon<dynamic>, VoidCallback>? _wrapped;

  /// Disposes all currently wrapped beacons
  void clearWrapped() {
    final wrapped = _wrapped;
    if (wrapped == null) return;
    _wrapped = null;
    for (final unsub in wrapped.values) {
      unsub();
    }
  }

  /// Wrapper beacons can have different methods to set the value,
  /// so this is should be implemented by the wrapper.
  void _onNewValueFromWrapped(InputT value);

  /// Subscribes to changes in the beacon
  /// returns a function that can be called to unsubscribe
  ///
  /// This disables automatic batching is not recommended for
  /// most usecases. Use [subscribe] if you are unsure.
  ///
  /// If [startNow] is true, the callback will be called immediately
  /// with the current value of the beacon.
  ///
  /// WARNING: Do not cancel another subscription in the callback.
  VoidCallback subscribeSynchronously(
    void Function(OutputT) callback, {
    bool startNow = true,
  }) {
    assert(!_isDisposed, 'Cannot subscribe to a disposed beacon.');
    final sub = SyncSubscription(
      this,
      callback,
      startNow: startNow,
    );
    _addObserver(sub);
    return sub.dispose;
  }
}
