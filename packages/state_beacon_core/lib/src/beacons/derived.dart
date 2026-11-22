// ignore_for_file: comment_references, lines_longer_than_80_chars

part of '../producer.dart';

/// See [Beacon.derived]
class DerivedBeacon<T> extends ReadableBeacon<T> with Consumer {
  /// See [Beacon.derived]
  DerivedBeacon(this._compute, {super.name});

  final T Function() _compute;

  @override
  String get _defaultName => 'DerivedBeacon<$T>';

  @override
  bool get _isDerived => true;

  @override
  void updateIfNecessary() {
    final status = _status;
    if (status == CLEAN || status == DISPOSED) return;
    try {
      if (status == CHECK) {
        final srcs = sources;
        final len = srcs.length;
        for (var i = 0; i < len; i++) {
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

      if (_status == DIRTY || _status == ERROR) {
        update();
      }

      _status = CLEAN;
    } catch (_) {
      _status = ERROR;
      rethrow;
    }
  }

  @override
  T peek() {
    if (currentConsumer != this) {
      if (_status != CLEAN) {
        updateIfNecessary();
      }
    } else {
      // recursion, make sure this is beacon is not empty
      if (isEmpty) {
        throw StateError(
          'Derived Beacon called recursively before it has a value',
        );
      }
    }
    return super.peek();
  }

  @override
  T get value {
    assert(
      currentConsumer != this,
      'Recursive access detected: DerivedBeacon cannot access its own value during'
      ' computation. Use peek() instead.',
    );
    final consumer = currentConsumer;
    if (consumer != null) _trackRead(consumer, this);
    if (_status != CLEAN) {
      updateIfNecessary();
    }
    return _value;
  }

  @override
  void stale(Status newStatus) {
    if (_status < newStatus) {
      _status = newStatus;

      final observers = _observers;
      final len = observers.length;
      if (len == 0) return;
      if (len == 1) {
        observers[0].markCheck();
        return;
      }
      _notifying++;
      try {
        for (var i = 0; i < len; i++) {
          observers[i].markCheck();
        }
      } finally {
        _notifying--;
      }
    }
  }

  @override
  void update() {
    final prevConsumer = currentConsumer;
    final prevGets = currentGets;
    final prevGetsIndex = currentGetsIndex;
    final prevRunId = currentRunId;

    currentConsumer = this;
    currentGets = null;
    currentGetsIndex = 0;
    currentRunId = ++_nextRunId;

    var didUpdate = false;

    try {
      final newValue = _compute();
      if (_isEmpty) {
        _isEmpty = false;
        _initialValue = newValue;
        _value = newValue;
        didUpdate = true;
      } else if (_value != newValue) {
        _previousValue = _value;
        _value = newValue;
        didUpdate = true;
      }

      // if the sources have changed, update source & observer links
      final gets = currentGets;
      if (gets != null) {
        final idx = currentGetsIndex;
        // remove all old Sources' .observers links to us
        stopWatchingAllAfter(idx);

        if (sources.isNotEmpty && idx > 0) {
          sources.length = idx;
          sources.addAll(gets);
        } else {
          sources = gets;
        }

        // Add ourselves to the end of the parent .observers array
        final srcs = sources;
        final len = srcs.length;
        for (var i = idx; i < len; i++) {
          srcs[i]._addObserver(this);
        }
      } else if (sources.isNotEmpty && currentGetsIndex < sources.length) {
        final idx = currentGetsIndex;
        // remove all old sources' .observers links to us
        stopWatchingAllAfter(idx);
        sources.length = idx;
      }

      // handles diamond depenendencies if we're the parent of a diamond.
      if (didUpdate) {
        final observers = _observers;
        final len = observers.length;
        // We've changed value, so mark our children as
        // dirty so they'll reevaluate
        for (var i = 0; i < len; i++) {
          observers[i]._status = DIRTY;
        }
      }

      // We've rerun with the latest values from all of our sources.
      // This means that we no longer need to update until a signal changes
      _status = CLEAN;
    } catch (_) {
      _status = ERROR;
      // If the very first run failed after reading one or more sources,
      // subscribe to them so subsequent source changes can trigger recovery.
      final gets = currentGets;
      if (sources.isEmpty && gets != null) {
        sources = gets;
        for (var i = 0; i < sources.length; i++) {
          sources[i]._addObserver(this);
        }
      }
      rethrow;
    } finally {
      // Always restore the enclosing capture context, even when _compute
      // throws. Otherwise the globals keep pointing at this beacon and any
      // later read is misdetected as a recursive access.
      currentGets = prevGets;
      currentGetsIndex = prevGetsIndex;
      currentConsumer = prevConsumer;
      currentRunId = prevRunId;
    }

    // Notify observers only after the capture context has been restored.
    // Observers may read this beacon's value, which would otherwise be
    // misdetected as a recursive access.
    assert(() {
      if (didUpdate) {
        BeaconObserver.instance?.onUpdate(this);
      }
      return true;
    }());
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _status = DISPOSED;
    final srcs = sources;
    for (var i = 0; i < srcs.length; i++) {
      srcs[i]._removeObserver(this);
    }
    srcs.clear();
    super.dispose();
  }
}
