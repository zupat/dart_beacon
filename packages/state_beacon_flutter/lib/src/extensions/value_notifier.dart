import 'package:flutter/widgets.dart';
import 'package:state_beacon_core/state_beacon_core.dart';

/// Extensions for [ValueNotifier].
extension ValueNotifierUtils<T> on ValueNotifier<T> {
  /// Converts this to a [WritableBeacon].
  WritableBeacon<T> toBeacon({BeaconGroup? group, String? name}) {
    final beaconCreator = group ?? Beacon;

    final beacon = beaconCreator.writable<T>(value, name: name);

    var syncingToNotifier = false;
    var syncingToBeacon = false;

    void update() {
      final currentValue = value;
      if (syncingToNotifier &&
          (identical(currentValue, beacon.peek()) ||
              currentValue == beacon.peek())) {
        return;
      }
      if (syncingToBeacon) return;
      syncingToBeacon = true;
      try {
        beacon.set(currentValue);
      } finally {
        syncingToBeacon = false;
      }
    }

    addListener(update);

    beacon
      ..subscribeSynchronously(
        (v) {
          if (syncingToBeacon && (identical(value, v) || value == v)) {
            return;
          }
          syncingToNotifier = true;
          try {
            value = v;
          } finally {
            syncingToNotifier = false;
          }
        },
        startNow: false,
      )
      ..onDispose(() => removeListener(update));

    return beacon;
  }
}
