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
      _setValue(_compute(_count, _computeProgress(_count)));
      start();
    }
  }

  final Duration _period;
  final T Function(int count, double progress) _compute;
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

      _count++;
      _setValue(_compute(_count, _computeProgress(_count)));

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

  double _computeProgress(int count) {
    if (_maxIterations == null || _maxIterations == 0) {
      return 0;
    }
    final raw = count / _maxIterations!;
    if (raw <= 0) return 0;
    if (raw >= 1) return 1;
    return raw;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
