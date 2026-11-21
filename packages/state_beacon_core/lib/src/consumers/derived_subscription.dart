part of '../producer.dart';

/// A subscription implementation specialized for [DerivedBeacon]s.
class DerivedSubscription<T> implements Consumer {
  /// Creates a new [DerivedSubscription].
  DerivedSubscription(
    this.producer,
    this.fn, {
    required this.startNow,
  }) {
    // If the derived beacon already has a value but is stale (DIRTY/CHECK)
    // when subscribing with startNow=false, bring it to CLEAN first so future
    // upstream changes are not swallowed by DerivedBeacon.stale()'s guard.
    if (!startNow &&
        !producer.isEmpty &&
        producer._status != CLEAN &&
        !producer._hadError) {
      producer.updateIfNecessary();
    }

    _forceFirstRun = !startNow && producer.isEmpty;
    if (startNow || _forceFirstRun) {
      _schedule();
    } else {
      // For derived beacons with startNow=false and an existing value,
      // we don't schedule initially but we still mark as CLEAN so
      // future updates will work.
      _status = CLEAN;
    }

    assert(() {
      BeaconObserver.instance?.onWatch(name, producer);
      return true;
    }());
  }

  /// Whether the first scheduled run exists only to force the lazy derived
  /// beacon to evaluate once, so that it registers itself as an observer of
  /// its sources. Such a run must not invoke [fn] unless it would otherwise
  /// swallow a change that landed before the flush.
  bool _forceFirstRun = false;

  /// Baseline value captured when a source changes after [producer] was
  /// evaluated synchronously during a pending [_forceFirstRun], before the
  /// first flush.
  bool _hasBaseline = false;
  T? _baselineValue;

  bool _isDisposed = false;

  /// The derived beacon that this subscription is watching.
  final DerivedBeacon<T> producer;

  /// Whether the subscription should start immediately.
  final bool startNow;

  /// The callback that runs when the producer changes.
  final void Function(T) fn;

  @override
  List<Producer<dynamic>?> sources = [];

  @override
  Status _status = DIRTY;

  void _schedule() {
    if (_isDisposed) return;
    _effectQueue.add(this);
    _flushFn();
  }

  @override
  void stale(Status newStatus) {
    if (_isDisposed) return;
    if (_status < newStatus) {
      final oldStatus = _status;
      _status = newStatus;

      if (oldStatus == CLEAN) {
        _schedule();
      }
    } else if (!startNow && _status == DIRTY && newStatus == CHECK) {
      // edge case: when derived is re-evaluated after we subscribe
      // we are marked as dirty via direct assignment.
      // when derived changes again and puts us in the CHECK state
      // we are DIRTY and never got scheduled.
      // check PR#171 for full explanation
      if (_forceFirstRun && !_hasBaseline && !producer.isEmpty) {
        _hasBaseline = true;
        _baselineValue = producer._value;
      }
      _schedule();
    }
  }

  @override
  void updateIfNecessary() {
    if (_isDisposed) return;

    try {
      // Check dependent sources (only for DerivedBeacon)
      if (_status == CHECK) {
        producer.updateIfNecessary();
      }

      // Update if still dirty
      if (_status == DIRTY) {
        update();
      }
    } finally {
      _status = CLEAN;
    }
  }

  @override
  void update() {
    final forcedFirstRun = _forceFirstRun;
    final hasBaseline = _hasBaseline;
    final baselineValue = _baselineValue;
    _forceFirstRun = false;
    _hasBaseline = false;
    _baselineValue = null;

    // Snapshot before evaluating, since peek() may fill an empty producer.
    // Only the forced first run needs this, so avoid touching _value
    // on every normal update.
    final hadValue = forcedFirstRun && (hasBaseline || !producer.isEmpty);
    final oldValue =
        hasBaseline ? baselineValue : (hadValue ? producer._value : null);

    // Always evaluate the producer. This is what returns it to CLEAN, and a
    // CLEAN producer is required for its stale() to forward any future
    // notification to us. Skipping the evaluation here is what caused the
    // orphan bug: we consumed our DIRTY status while the producer stayed
    // DIRTY, so its `_status < newStatus` guard silenced it forever.
    final newValue = producer.peek();

    // peek() runs the producer's computation, which may dispose this
    // subscription (e.g. by cancelling from inside that computation).
    // Don't invoke the user callback in that case.
    if (_isDisposed) return;

    // Mark ourselves clean *after* evaluating (peek() re-dirties observers
    // when it recomputes) but *before* invoking user code, so that a write
    // performed inside fn() arrives as a fresh notification and a throwing
    // fn() cannot leave us wedged at DIRTY.
    _status = CLEAN;

    if (forcedFirstRun) {
      // This run exists only to force the evaluation above, so fn() is not
      // invoked for the initial value:
      //
      // mybeacon.subscribe((_){}, startNow: false);
      // mybeacon.peek();
      //
      // The one exception is a source changing between that read and this
      // flush, which is a real update that is ours to deliver:
      //
      // source.value = newValue; // before the first flush
      if (hadValue && newValue != oldValue) fn(newValue);
      return;
    }

    fn(newValue);
  }

  /// Disposes of the subscription.
  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    // Remove this subscription from the producer's observer list.
    producer._removeObserver(this);
    // The subscription can be queued more than once (forced first run plus a
    // later source change), so remove every entry to prevent it from running
    // after disposal.
    _effectQueue.removeWhere((consumer) => identical(consumer, this));
  }

  @override
  void markCheck() => stale(CHECK);

  @override
  void _sourceDisposed(Producer<dynamic> source) {
    // if one of our sources is disposed, we should dispose ourselves
    // this is a bit strict because other sources might still be alive
    // but I want to enforce this to promote good practices
    scheduleMicrotask(dispose);
  }

  // these should never be called
  // coverage:ignore-start
  @override
  void markDirty() => throw UnimplementedError();

  @override
  Producer<dynamic>? _producerAtIndex(int index) {
    throw UnimplementedError();
  }

  @override
  void stopWatchingAllAfter(int index) {
    throw UnimplementedError();
  }

  @override
  void startWatching(Producer<dynamic> source) {
    throw UnimplementedError();
  }

  @override
  String get name => 'Subscription<${producer.name}>';
  // coverage:ignore-end
}
