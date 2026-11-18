import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:state_beacon_core/state_beacon_core.dart';
import 'package:state_beacon_flutter/src/value_notifier_beacon.dart';
import 'package:state_beacon_flutter/state_beacon_flutter.dart'
    show TextEditingBeacon;

part 'beacon_controller.dart';
part 'beacon_group.dart';
part 'readable.dart';
part 'watch_observe.dart';
part 'writable.dart';

final Map<int, ValueNotifierBeacon<dynamic>> _vnCache = {};

@visibleForTesting

/// The number of value notifiers currently in use
/// This is used for testing purposes only
bool hasNotifier(BaseBeacon<dynamic> beacon) {
  return _vnCache.containsKey(beacon.hashCode);
}

ValueNotifier<T> _toValueNotifier<T>(ReadableBeacon<T> beacon) {
  final key = beacon.hashCode;

  final existing = _vnCache[key];

  if (existing != null) {
    return existing as ValueNotifierBeacon<T>;
  }

  final notifier = ValueNotifierBeacon(beacon.peek());

  _vnCache[key] = notifier;

  final unsub = beacon.subscribe(notifier.set, startNow: false);

  late VoidCallback removeBeaconDisposeCallback;

  notifier.addDisposeCallback(() {
    unsub();

    // When the beacon is disposing, it is already iterating its dispose
    // callbacks. Removing this callback from that list mid-iteration would
    // throw a ConcurrentModificationError and skip the remaining cleanup.
    // This can happen through our own callback or one registered earlier.
    if (!beacon.isDisposed) {
      removeBeaconDisposeCallback();
    }

    if (identical(_vnCache[key], notifier)) {
      _vnCache.remove(key);
    }
  });

  // `ValueNotifierBeacon.dispose` is idempotent, so an earlier dispose
  // callback may already have disposed the notifier before this hook runs.
  removeBeaconDisposeCallback = beacon.onDispose(notifier.dispose);

  return notifier;
}
