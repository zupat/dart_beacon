part of '../producer.dart';

/// An immutable base class for ThrottledBeacon
mixin ReableThrottledBeacon<T> on ReadableBeacon<T> {
  bool _blocked = false;
  Duration? _duration;

  /// Whether or not this beacon is currently blocked.
  bool get isBlocked => _blocked;

  /// Sets the duration of the throttle.
  /// If [unblock] is true, the beacon will be unblocked if
  /// it is currently blocked.
  void setDuration(Duration newDuration, {bool unblock = true}) {
    _duration = newDuration;
    if (unblock) {
      _blocked = false;
    }
  }
}

/// A beacon that throttles updates to its value.
class ThrottledBeacon<T> extends WritableBeacon<T>
    with ReableThrottledBeacon<T> {
  /// @macro [ThrottledBeacon]
  ThrottledBeacon({
    Duration? duration,
    T? initialValue,
    bool dropBlocked = true,
    String? name,
  }) : this._(
          duration: duration,
          initialValue: initialValue,
          dropBlocked: dropBlocked,
          name: name,
        );

  ThrottledBeacon._({
    Duration? duration,
    super.initialValue,
    this.dropBlocked = true,
    super.name,
    super.defaultNameMode,
  }) : super._() {
    _duration = duration;
  }

  Timer? _timer;

  /// If true, values will be dropped while the beacon is blocked.
  /// If false, values will be buffered and
  /// emitted when the beacon is unblocked.
  final bool dropBlocked;

  Queue<(T, bool)>? _buffer;

  @override
  String get _defaultName => _defaultNameMode == _defaultNameFromLazyCreator
      ? 'LazyThrottledBeacon<$T>'
      : super._defaultName;

  void _processBuffer(Timer timer) {
    final buffer = _buffer;
    if (buffer == null || buffer.isEmpty) {
      _timer?.cancel();
      _blocked = false;
      return;
    }

    final (bufferedValue, force) = buffer.removeFirst();
    _setValue(bufferedValue, force: force);
  }

  @override
  void set(T newValue, {bool force = false}) {
    if (_blocked) {
      if (!dropBlocked) {
        (_buffer ??= Queue<(T, bool)>()).addLast((newValue, force));
      }
      return;
    }

    _setValue(newValue, force: force);

    if (_duration == null) return;

    _blocked = true;
    _timer?.cancel();
    _timer = Timer.periodic(_duration!, _processBuffer);
  }

  @override
  void setDuration(Duration newDuration, {bool unblock = true}) {
    super.setDuration(newDuration, unblock: unblock);

    if (unblock) {
      _timer?.cancel();
      _timer = null;
      final buffer = _buffer;
      if (buffer != null && buffer.isNotEmpty) {
        final pending = List<(T, bool)>.of(buffer);
        buffer.clear();
        for (final (bufferedValue, force) in pending) {
          _setValue(bufferedValue, force: force);
        }
      }
    } else if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      _timer = Timer.periodic(_duration!, _processBuffer);
    }
  }

  void _cleanUp() {
    _timer?.cancel();
    _timer = null;
    _blocked = false;
    _buffer = null;
  }

  @override
  void reset({bool force = false}) {
    _cleanUp();
    super.reset(force: force);
  }

  @override
  void dispose() {
    _cleanUp();
    super.dispose();
  }
}
