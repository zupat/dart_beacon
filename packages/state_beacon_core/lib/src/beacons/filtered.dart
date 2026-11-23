// ignore_for_file: use_setters_to_change_properties

part of '../producer.dart';

// ignore: public_member_api_docs
typedef BeaconFilter<T> = bool Function(T?, T);

/// An immutable base class for FilteredBeacon
mixin ReadableFilteredBeacon<T> on ReadableBeacon<T> {
  BeaconFilter<T>? _filter;

  /// Set the function that will be used to filter subsequent values.
  void setFilter(BeaconFilter<T> newFilter) {
    _filter = newFilter;
  }

  /// Whether or not this beacon has a filter.
  bool get hasFilter => _filter != null;
}

/// A beacon that filters updates to its value based on a function.
class FilteredBeacon<T> extends WritableBeacon<T>
    with ReadableFilteredBeacon<T> {
  /// @macro [FilteredBeacon]
  FilteredBeacon({
    T? initialValue,
    BeaconFilter<T>? filter,
    String? name,
    bool allowFirst = false,
  }) : this._(
          initialValue: initialValue,
          filter: filter,
          name: name,
          allowFirst: allowFirst,
        );

  FilteredBeacon._({
    super.initialValue,
    BeaconFilter<T>? filter,
    super.name,
    super.defaultNameMode,
    bool allowFirst = false,
  })  : _allowFirst = allowFirst,
        super._() {
    _filter = filter;
  }

  final bool _allowFirst;

  @override
  String get _defaultName => _isExactType<FilteredBeacon<T>>()
      ? (_defaultNameMode == _defaultNameFromLazyCreator
          ? 'LazyFilteredBeacon<$T>'
          : 'FilteredBeacon<$T>')
      : super._defaultName;

  @override
  void set(T newValue, {bool force = false}) {
    if ((_isEmpty && _allowFirst) ||
        (_filter?.call(isEmpty ? null : peek(), newValue) ?? true)) {
      _setValue(newValue, force: force);
    }
  }
}
