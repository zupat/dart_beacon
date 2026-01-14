part of '../producer.dart';

/// A beacon that emits values periodically with progress information.
class ProgressBeacon<T> extends ReadableBeacon<T> {
  /// Creates a [ProgressBeacon] that emits values periodically.
  ///
  /// If [manualStart] is `true`, the beacon will not start emitting values
  /// until [start] is called. In that case an [initialValue] must be
  /// provided so the beacon has a well-defined value before it starts.
  ProgressBeacon(
    this._period,
    this._compute, {
    required Duration totalDuration,
    super.initialValue,
    super.name,
    bool manualStart = false,
  })  : _totalDuration = totalDuration,
        _manualStart = manualStart {
    if (_manualStart) {
      assert(
        !_isEmpty,
        'An initialValue must be provided when manualStart is true.',
      );
    } else {
      _setValue(_compute(0));
      start();
    }
  }

  final Duration _period;
  final T Function(double progress) _compute;
  final Duration _totalDuration;
  final bool _manualStart;

  StreamSubscription<dynamic>? _subscription;
  Duration _elapsed = Duration.zero;

  /// Starts emitting values periodically.
  ///
  /// If a previous progression is in progress, it will be stopped and
  /// restarted from the beginning.
  void start() {
    if (_isDisposed) return;

    // Stop any existing progression.
    _subscription?.cancel();

    // Reset elapsed time for a fresh start.
    _elapsed = Duration.zero;

    _subscription = Stream<dynamic>.periodic(_period).listen((_) {
      if (_isDisposed) return;

      _elapsed += _period;
      final progress = _computeProgress();
      _setValue(_compute(progress));

      if (progress >= 1.0) {
        stop();
      }
    });
  }

  /// Stops emitting values and resets the elapsed time.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _elapsed = Duration.zero;
  }

  /// Pauses emission of values.
  void pause() => _subscription?.pause();

  /// Resumes emission of values.
  void resume() => _subscription?.resume();

  double _computeProgress() {
    if (_totalDuration.inMicroseconds == 0) {
      return 1;
    }
    final raw = _elapsed.inMicroseconds / _totalDuration.inMicroseconds;
    return raw.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
