part of '../producer.dart';

/// A callback keeps track of its dependecies that
/// re-executes whenever one changes.
class Effect with Consumer {
  /// Creates a new [Effect].
  Effect(Function compute, {String? name})
      : _compute = compute as Object? Function(),
        _name = name {
    _schedule();
  }

  final String? _name;
  @override
  String get name => _name ?? 'Effect';

  final Object? Function() _compute;

  void Function()? _disposeChild;
  bool _isDisposed = false;

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
    }
  }

  @override
  void updateIfNecessary() {
    if (_isDisposed) return;
    try {
      super.updateIfNecessary();
    } finally {
      _status = CLEAN;
    }
  }

  void _runCleanup(void Function() cleanup) {
    final prevConsumer = currentConsumer;
    currentConsumer = null;
    try {
      cleanup();
    } finally {
      currentConsumer = prevConsumer;
    }
  }

  @override
  void update() {
    if (_isDisposed) return;

    // Clear and run the previous cleanup untracked before tracking the next
    // run so reads inside cleanup are not tracked and a stale cleanup cannot
    // be invoked twice if _compute throws or returns a non-Function.
    final disposeChild = _disposeChild;
    _disposeChild = null;
    if (disposeChild != null) {
      _runCleanup(disposeChild);
    }

    if (_isDisposed) return;

    final prevConsumer = currentConsumer;
    final prevGets = currentGets;
    final prevGetsIndex = currentGetsIndex;
    final prevRunId = currentRunId;

    currentConsumer = this;
    currentGets = null;
    currentGetsIndex = 0;
    currentRunId = ++_nextRunId;

    try {
      final cleanup = _compute();

      if (_isDisposed) {
        if (cleanup is void Function()) {
          cleanup();
        }
        return;
      }

      if (cleanup is void Function()) {
        _disposeChild = cleanup;
      }

      final gets = currentGets;
      if (gets != null) {
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
        stopWatchingAllAfter(currentGetsIndex);
        sources.length = currentGetsIndex;
      }
    } finally {
      currentGets = prevGets;
      currentGetsIndex = prevGetsIndex;
      currentConsumer = prevConsumer;
      currentRunId = prevRunId;

      // We've rerun with the latest values from all of our sources (or failed
      // and need to remain responsive to future updates).
      _status = CLEAN;
    }
  }

  /// Disposes the effect.
  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    final disposeChild = _disposeChild;
    _disposeChild = null;
    if (disposeChild != null) {
      _runCleanup(disposeChild);
    }
    _effectQueue.removeWhere((consumer) => identical(consumer, this));
    // remove ourselves from the .observers list of all sources
    for (final source in sources) {
      source._removeObserver(this);
    }
    sources.clear();
  }
}
