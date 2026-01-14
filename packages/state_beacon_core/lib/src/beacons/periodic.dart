part of '../producer.dart';

/// A beacon that emits values periodically.
class PeriodicBeacon<T> extends ReadableBeacon<T> {
  /// Creates a [PeriodicBeacon] that emits values periodically.
  ///
  /// If [manualStart] is `true`, the beacon will not start emitting values
  /// until [start] is called. In that case an [initialValue] must be
  /// provided so the beacon has a well-defined value before it starts.
  PeriodicBeacon(
    this._period,
    this._compute, {
    super.initialValue,
    super.name,
    int? maxIterations,
    bool manualStart = false,
  })  : _maxIterations = maxIterations,
        _manualStart = manualStart {
    if (_manualStart) {
      assert(
        !_isEmpty,
        'An initialValue must be provided when manualStart is true.',
      );
    } else {
      _setValue(_compute(_count));
      start();
    }
  }

  final Duration _period;
  final T Function(int count) _compute;
  final int? _maxIterations;
  final bool _manualStart;

  StreamSubscription<dynamic>? _subscription;
  var _count = 0;

  /// Starts emitting values periodically.
  ///
  /// If a previous progression is in progress, it will be stopped and
  /// restarted from the beginning.
  void start() {
    if (_isDisposed) return;

    // Stop any existing progression.
    _subscription?.cancel();

    // Restart the iteration count from the beginning.
    _count = 0;

    _subscription = Stream<dynamic>.periodic(_period).listen((_) {
      if (_isDisposed) return;

      _setValue(_compute(++_count));

      if (_maxIterations != null && _count >= _maxIterations!) {
        stop();
      }
    });
  }

  /// Stops emitting values and resets the iteration count.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _count = 0;
  }

  /// Pauses emission of values.
  void pause() => _subscription?.pause();

  /// Resumes emission of values.
  void resume() => _subscription?.resume();

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
