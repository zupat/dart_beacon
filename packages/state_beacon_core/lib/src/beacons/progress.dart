// ignore_for_file: lines_longer_than_80_chars

part of '../producer.dart';

/// A beacon that emits values periodically with progress information.
///
/// The progress is calculated as the ratio of elapsed time to [totalDuration].
/// The value emitted is determined by the [onProgress] callback which receives
/// the progress (a value between 0.0 and 1.0).
class ProgressBeacon<T> extends ReadableBeacon<T> {
  /// Creates a [ProgressBeacon] that emits values periodically.
  ///
  /// [interval] is the duration between updates.
  /// [totalDuration] is the total time the beacon will run.
  /// [onProgress] is a callback that returns the value based on the progress.
  /// [onDone] is a callback that returns the final value when progress reaches 1.0.
  /// [onStart] is a callback that returns the initial value when the beacon starts.
  ///
  /// If [onStart] is provided, the beacon will not start emitting values
  /// until `start()` is called. In that case, [initialValue] must be provided.
  ///
  /// If [onProgress] is not provided, then [onDone] must be provided.
  ProgressBeacon({
    required this.interval,
    required this.totalDuration,
    this.onProgress,
    this.onDone,
    this.onStart,
    this.loop = false,
    super.initialValue,
    super.name,
  })  : assert(
          interval <= totalDuration,
          'Interval must be less than or equal to totalDuration.',
        ),
        assert(
          onProgress != null || onDone != null,
          'If onProgress is not provided, onDone must be provided.',
        ),
        assert(
          onDone == null || onProgress == null,
          'If onDone is provided, onProgress must be null as onDone can'
          ' be replicated easily in onProgress by checking if (progress >= 1.0).',
        ) {
    if (onStart != null) {
      assert(
        !_isEmpty,
        'An initialValue must be provided when onStart is provided.',
      );
    } else {
      start();
    }
  }

  /// The interval at which values are emitted.
  final Duration interval;

  /// Whether to restart the progress when it's done.
  final bool loop;

  /// The function that computes the value based on progress.
  final T Function(double progress)? onProgress;

  /// The total duration over which progress is calculated.
  final Duration totalDuration;

  /// The function that returns the desired
  /// start value when the beacon is started.
  /// If this is not null, the beacon must be started manually.
  final T Function()? onStart;

  /// The function that returns the desired
  /// final value when progress reaches 100%.
  final T Function()? onDone;

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

    if (onStart != null) {
      _setValue(onStart!.call());
    } else if (onProgress != null) {
      _setValue(onProgress!(0));
    }

    _subscription = Stream<dynamic>.periodic(interval).listen((_) {
      if (_isDisposed) return;

      _elapsed += interval;
      final progress = _computeProgress();

      if (onProgress != null) {
        _setValue(onProgress!(progress));
      }

      if (progress >= 1.0) {
        if (onDone != null) {
          _setValue(onDone!.call());
        }

        if (loop) {
          // Restart in the next microtask to allow listeners to
          // process the 1.0 value.
          Future.delayed(interval, start);
        } else {
          stop();
        }
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
    if (totalDuration.inMicroseconds == 0) {
      return 1;
    }
    final raw = _elapsed.inMicroseconds / totalDuration.inMicroseconds;
    return raw.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
