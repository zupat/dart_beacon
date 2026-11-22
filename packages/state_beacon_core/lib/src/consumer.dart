part of 'producer.dart';

// Shared empty sentinel (growable rather than const so AOT keeps sources
// monomorphic _GrowableList for direct indexed loads). Never mutated directly.
final _emptySources = <Producer<dynamic>>[];

/// This class represents anything that can consume a [Producer].
/// This includes [DerivedBeacon] and [Subscription] and [Effect].
mixin Consumer {
  /// The name of the consumer. For debugging purposes.
  String get name;

  /// The list of [Producer]s that this consumer is currently watching.
  List<Producer<dynamic>> sources = _emptySources;
  var _status = DIRTY;

  /// Intrusive doubly-linked pointers for the effect scheduler queue.
  Consumer? _prevQueued;
  Consumer? _nextQueued;
  bool _inQueue = false;

  /// Handles the status of the consumer when a producer changes.
  void stale(Status newStatus);

  /// Called by a producer when it updates and it's sure that the consumer
  /// is dirty and needs to be updated.
  void markDirty() => stale(DIRTY);

  /// Called by a producer when it updates and it's unsure if the consumer
  /// is dirty and needs to be updated.
  void markCheck() => stale(CHECK);

  /// Called by [Effect]s and [Subscription]s to tell the consumer to update.
  void updateIfNecessary() {
    if (_status == CLEAN) return;

    if (_status == CHECK) {
      final srcs = sources;
      for (var i = 0; i < srcs.length; i++) {
        final source = srcs[i];
        if (source._isDerived) {
          (source as DerivedBeacon).updateIfNecessary();

          if (_status == DIRTY) {
            // No need to check further because we are dirty and must update
            break;
          }
        }
      }
    }

    if (_status == DIRTY) {
      update();
    }

    _status = CLEAN;
  }

  /// remove all old sources' .observers links to us
  void stopWatchingAllAfter(int index) {
    final srcs = sources;
    final len = srcs.length;
    if (len == 0) return;

    for (var i = index; i < len; i++) {
      // Use _removeObserver so producer hooks (e.g. auto-sleep) run when a
      // conditional dependency is dropped.
      srcs[i]._removeObserver(this);
    }
  }

  void _sourceDisposed(Producer<dynamic> source) {
    // if one of our sources is disposed, we should dispose ourselves
    // this is a bit strict because other sources might still be alive
    // but I want to enforce this to promote good practices
    Future.microtask(dispose);
  }

  /// Update the consumer.
  void update();

  /// Dispose the consumer.
  void dispose();
}

void _trackRead(Consumer consumer, Producer<dynamic> source) {
  final runId = currentRunId;
  if (source._lastReadRun == runId) return;
  source._lastReadRun = runId;

  // we have to check if currentGets is null because if it's not
  // then we changed sources in the past so we can't just increment
  // we can only increment when sources are in the same order
  // Compare by identity: two distinct producers can override `==` (e.g.
  // RawStreamBeacon with the same options) while watching different streams.
  // Reusing the old source then leaves us subscribed to the wrong beacon.
  final idx = currentGetsIndex;
  final sources = consumer.sources;
  if (currentGets == null &&
      idx < sources.length &&
      identical(sources[idx], source)) {
    currentGetsIndex = idx + 1;
    return;
  }
  _trackReadSlow(consumer, source);
}

void _trackReadSlow(Consumer consumer, Producer<dynamic> source) {
  assert(() {
    BeaconObserver.instance?.onWatch(consumer.name, source);
    return true;
  }());
  (currentGets ??= []).add(source);
}
