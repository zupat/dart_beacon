part of '../producer.dart';

/// A record containing a value and a timestamp.
typedef TimestampValue<T> = ({T value, DateTime timestamp});

/// A beacon that attaches a timestamp to its value.
class TimestampBeacon<T> extends ReadableBeacon<TimestampValue<T>> {
  /// @macro [TimestampBeacon]
  TimestampBeacon({T? initialValue, String? name})
      : this._(initialValue: initialValue, name: name);

  TimestampBeacon._({
    T? initialValue,
    super.name,
    super.defaultNameMode,
  }) : super._(
          initialValue: initialValue != null || null is T
              ? (value: initialValue as T, timestamp: DateTime.now())
              : null,
        );

  @override
  String get _defaultName => _defaultNameMode == _defaultNameFromLazyCreator
      ? 'LazyTimestampBeacon<$T>'
      : super._defaultName;

  /// Set the value of this beacon.
  void set(T newValue) {
    _setValue((value: newValue, timestamp: DateTime.now()));
  }
}
