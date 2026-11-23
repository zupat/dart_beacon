part of '../producer.dart';

/// A beacon that debounces updates to its value.
class DebouncedBeacon<T> extends WritableBeacon<T> {
  /// @macro [DebouncedBeacon]
  DebouncedBeacon({
    Duration? duration,
    T? initialValue,
    String? name,
    bool allowFirst = false,
  }) : this._(
          duration: duration,
          initialValue: initialValue,
          name: name,
          allowFirst: allowFirst,
        );

  DebouncedBeacon._({
    this.duration,
    super.initialValue,
    super.name,
    super.defaultNameMode,
    bool allowFirst = false,
  })  : _allowFirst = allowFirst,
        super._();

  final bool _allowFirst;

  /// The duration to debounce updates for.
  final Duration? duration;

  Timer? _debounceTimer;

  @override
  String get _defaultName => _isExactType<DebouncedBeacon<T>>()
      ? (_defaultNameMode == _defaultNameFromLazyCreator
          ? 'LazyDebouncedBeacon<$T>'
          : 'DebouncedBeacon<$T>')
      : super._defaultName;

  @override
  void set(T newValue, {bool force = false}) {
    if (duration == null || (_isEmpty && _allowFirst)) {
      _setValue(newValue, force: force);
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration!, () {
      _setValue(newValue, force: force);
    });
  }

  @override
  void reset({bool force = false}) {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    super.reset(force: force);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    super.dispose();
  }
}
