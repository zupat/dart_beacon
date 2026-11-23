part of 'producer.dart';

_QueuedConsumer? _queueHead;
_QueuedConsumer? _queueTail;
void Function() _flushFn = _asyncScheduler;
bool _flushing = false;

void _enqueueEffect(_QueuedConsumer consumer) {
  if (consumer._inQueue) return;
  consumer._inQueue = true;
  final tail = _queueTail;
  if (tail == null) {
    _queueHead = consumer;
    _queueTail = consumer;
  } else {
    consumer._prevQueued = tail;
    tail._nextQueued = consumer;
    _queueTail = consumer;
  }
  _flushFn();
}

void _dequeueEffect(_QueuedConsumer consumer) {
  if (!consumer._inQueue) return;
  final prev = consumer._prevQueued;
  final next = consumer._nextQueued;
  if (prev == null) {
    _queueHead = next;
  } else {
    prev._nextQueued = next;
  }
  if (next == null) {
    _queueTail = prev;
  } else {
    next._prevQueued = prev;
  }
  consumer._prevQueued = null;
  consumer._nextQueued = null;
  consumer._inQueue = false;
}

// coverage:ignore-start
/// `Effects` are not synchronous, their execution is controlled by a scheduler.
/// When a dependency of an `effect` changes, it is added to a queue and
/// the scheduler decides when is the best time to flush the queue.
/// By default, the queue is flushed with a DARTVM microtask which runs
/// on the next loop; this can be changed by setting a custom scheduler.
/// Flutter comes with its own scheduler, so it is recommended to use
/// flutter's scheduler when using beacons in a flutter app.
/// This can be done by calling `BeaconScheduler.useFlutterScheduler();`
/// in the `main` function.
///
/// ```dart
/// void main() {
///  BeaconScheduler.useFlutterScheduler();
///
///  runApp(const MyApp());
/// }
/// ```
abstract class BeaconScheduler {
  /// Runs all queued effects/subscriptions
  /// This is made available for testing and should not be used in production
  static void flush() => _flushEffects();

  /// Sets the scheduler to the provided function
  static void setScheduler(void Function() fn) => _flushFn = fn;

  /// This is the default scheduler which processes updates asynchronously
  /// as a DartVM microtask. This does automatic batching of updates.
  static void useAsyncScheduler() {
    _flushing = false;
    _flushFn = _asyncScheduler;
  }

  /// This scheduler limits the frequency that updates
  /// are processed to 60 times per second.
  static void use60fpsScheduler() {
    _flushing = false;
    _flushFn = _sixtyfpsScheduler;
  }

  /// This scheduler limits the frequency that updates
  /// are processed to a custom fps.
  static void useCustomFpsScheduler(int updatesPerSecond) {
    assert(updatesPerSecond > 0, 'updatesPerSecond must be greater than 0');
    _flushing = false;
    _flushFn = _customFPS(updatesPerSecond);
  }
}

void _flushEffects() {
  while (_queueHead != null) {
    final consumer = _queueHead!;
    final next = consumer._nextQueued;
    _queueHead = next;
    if (next == null) {
      _queueTail = null;
    } else {
      next._prevQueued = null;
    }
    consumer._prevQueued = null;
    consumer._nextQueued = null;
    consumer._inQueue = false;
    consumer.updateIfNecessary();
  }
}

void _asyncScheduler() {
  if (!_flushing) {
    _flushing = true;
    Future.microtask(() {
      try {
        _flushEffects();
      } finally {
        _flushing = false;
        if (_queueHead != null) {
          _flushFn();
        }
      }
    });
  }
}

const _k16ms = Duration(milliseconds: 16);

void Function() _customFPS(int fps) {
  final duration = Duration(milliseconds: (1000 / fps).round());
  return () {
    if (_flushing) return;
    _flushing = true;
    Future.delayed(duration, () {
      try {
        _flushEffects();
      } finally {
        _flushing = false;
        if (_queueHead != null) {
          _flushFn();
        }
      }
    });
  };
}

void _sixtyfpsScheduler() {
  if (_flushing) return;
  _flushing = true;
  Future.delayed(_k16ms, () {
    try {
      _flushEffects();
    } finally {
      _flushing = false;
      if (_queueHead != null) {
        _flushFn();
      }
    }
  });
}

// void _syncScheduler() {
//   if (!_stabilizationQueued) {
//     _stabilizationQueued = true;
//     _flushEffects();
//     _stabilizationQueued = false;
//   }
// }
// coverage:ignore-end
