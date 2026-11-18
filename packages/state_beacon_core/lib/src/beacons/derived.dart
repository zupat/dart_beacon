// ignore_for_file: comment_references, lines_longer_than_80_chars

part of '../producer.dart';

/// See [Beacon.derived]
class DerivedBeacon<T> extends ReadableBeacon<T> with Consumer {
  /// See [Beacon.derived]
  DerivedBeacon(this._compute, {super.name});

  final T Function() _compute;

  @override
  bool get _isDerived => true;

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
    if (_status < newStatus) {
      _status = newStatus;

      for (var i = 0; i < _observers.length; i++) {
        _observers[i].markCheck();
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
    currentGets = [];
    currentGetsIndex = 0;

    // Assigned inside the try; only read below when no exception was thrown.
    late final bool didUpdate;

    try {
      _value = _compute();
      if (_isEmpty) {
        _initialValue = _value;
        didUpdate = true;
      } else {
        didUpdate = _previousValue != _value;
      }
      _isEmpty = false;

      // if the sources have changed, update source & observer links
      if (currentGets.isNotEmpty) {
        // remove all old Sources' .observers links to us
        stopWatchingAllAfter(currentGetsIndex);

        if (sources.isNotEmpty && currentGetsIndex > 0) {
          sources.length = currentGetsIndex + currentGets.length;
          for (var i = 0; i < currentGets.length; i++) {
            sources[currentGetsIndex + i] = currentGets[i];
          }
        } else {
          sources = currentGets;
        }

        // Add ourselves to the end of the parent .observers array
        for (var i = currentGetsIndex; i < sources.length; i++) {
          final source = sources[i]!;
          source._observers.add(this);
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
    for (final source in sources) {
      source!._removeObserver(this);
    }
    sources.clear();
    super.dispose();
  }
}
