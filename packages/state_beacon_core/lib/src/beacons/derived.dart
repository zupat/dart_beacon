// ignore_for_file: comment_references, lines_longer_than_80_chars

part of '../producer.dart';

/// See [Beacon.derived]
class DerivedBeacon<T> extends ReadableBeacon<T> with Consumer {
  /// See [Beacon.derived]
  DerivedBeacon(this._compute, {super.name});

  final T Function() _compute;

  bool _hadError = false;

  @override
  bool get _isDerived => true;

  @override
  void updateIfNecessary() {
    try {
      super.updateIfNecessary();
    } catch (_) {
      _hadError = true;
      rethrow;
    }
  }

  @override
  T peek() {
    if (currentConsumer != this) {
      updateIfNecessary();
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
    currentConsumer?.startWatching(this);
    updateIfNecessary();
    return _value;
  }

  @override
  void stale(Status newStatus) {
    if (_isDisposed) return;
    if (_status < newStatus || _hadError) {
      _hadError = false;
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
    _previousValue = isEmpty ? null : _value;

    final prevConsumer = currentConsumer;
    final prevGets = currentGets;
    final prevGetsIndex = currentGetsIndex;

    currentConsumer = this;
    currentGets = null;
    currentGetsIndex = 0;

    // Assigned inside the try; only read below when no exception was thrown.
    late final bool didUpdate;

    try {
      _value = _compute();
      _hadError = false;
      if (_isEmpty) {
        _initialValue = _value;
        didUpdate = true;
      } else {
        didUpdate = _previousValue != _value;
      }
      _isEmpty = false;

      // if the sources have changed, update source & observer links
      final gets = currentGets;
      if (gets != null) {
        // remove all old Sources' .observers links to us
        stopWatchingAllAfter(currentGetsIndex);

        if (sources.isNotEmpty && currentGetsIndex > 0) {
          sources.length = currentGetsIndex;
          sources.addAll(gets);
        } else {
          sources = gets;
        }

        // Add ourselves to the end of the parent .observers array
        for (var i = currentGetsIndex; i < sources.length; i++) {
          sources[i]._addObserver(this);
        }
      } else if (sources.isNotEmpty && currentGetsIndex < sources.length) {
        // remove all old sources' .observers links to us
        stopWatchingAllAfter(currentGetsIndex);
        sources.length = currentGetsIndex;
      }

      // handles diamond depenendencies if we're the parent of a diamond.
      if (didUpdate && _observers.isNotEmpty) {
        // We've changed value, so mark our children as
        // dirty so they'll reevaluate
        for (var i = 0; i < _observers.length; i++) {
          _observers[i]._status = DIRTY;
        }
      }

      // We've rerun with the latest values from all of our sources.
      // This means that we no longer need to update until a signal changes
      _status = CLEAN;
    } catch (_) {
      _hadError = true;
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
    for (final source in sources) {
      source._removeObserver(this);
    }
    sources.clear();
    super.dispose();
  }
}
