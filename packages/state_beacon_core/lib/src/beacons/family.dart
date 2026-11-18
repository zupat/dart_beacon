part of '../producer.dart';

/// This returns a beacon that is created using the provided `create` function.
/// The beacon is cached and returned if the same argument is provided again.
class BeaconFamily<Arg, BeaconType extends ReadableBeacon<dynamic>> {
  /// @macro [BeaconFamily]
  BeaconFamily(this._create, {this.shouldCache = true});

  /// Whether or not to cache the created beacons.
  final bool shouldCache;

  late final _cache = <Arg, BeaconType>{};

  late final _entries = Beacon.list<MapEntry<Arg, BeaconType>>(
    [],
    name: 'family entries',
  );

  /// All beacons in the cache
  ReadableBeacon<List<MapEntry<Arg, BeaconType>>> get entries {
    if (!_beaconsAccessed && _cache.isNotEmpty) {
      // populate the list on first access
      _entries.value = _cache.entries.toList();
    }
    _beaconsAccessed = true;
    return _entries;
  }

  final BeaconType Function(Arg) _create;

  var _clearing = false;

  // if the beacons list isnt accessed,
  // we dont need to keep track of the beacons
  var _beaconsAccessed = false;

  /// Retrieves a `Beacon` based on the given argument.
  /// If caching is enabled and a beacon for the provided argument
  /// exists in the cache, it is returned.
  /// Otherwise, a new beacon is created using the `create` function.
  BeaconType call(Arg arg) {
    if (!shouldCache) return _create(arg);

    var beacon = _cache[arg];

    if (beacon != null) return beacon;

    beacon = _create(arg);
    _cache[arg] = beacon;
    if (_beaconsAccessed) _entries.add(MapEntry(arg, beacon));

    beacon.onDispose(() {
      if (_clearing) return;
      // The beacon may have been removed from the family and replaced by a
      // new one for the same argument. Only evict the cache entry if it is
      // still this beacon.
      if (!identical(_cache[arg], beacon)) return;
      _cache.remove(arg);
      if (!_beaconsAccessed) return;
      _entries.removeWhere((e) => identical(e.value, beacon));
    });

    return beacon;
  }

  /// Returns `true` if the cache contains a beacon for the provided argument.
  bool containsKey(Arg arg) => _cache.containsKey(arg);

  /// Removes a beacon from the cache if it exists.
  BeaconType? remove(Arg arg) {
    final removed = _cache.remove(arg);
    if (removed != null && _beaconsAccessed) {
      // Match by key: distinct beacons can compare equal, and removing by
      // value would drop their entries too.
      _entries.removeWhere((e) => e.key == arg);
    }
    return removed;
  }

  /// Clears the cache of beacon if caching is enabled.
  /// Beacons are disposed before they are removed
  void clear() {
    if (!shouldCache) return;

    _clearing = true;

    for (final beacon in _cache.values.toList()) {
      beacon.dispose();
    }

    _clearing = false;

    _cache.clear();
    if (_beaconsAccessed) _entries.clear();
    _beaconsAccessed = false;
  }
}
