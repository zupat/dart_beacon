// ignore_for_file: invalid_use_of_protected_member, use_if_null_to_convert_nulls_to_bools, lines_longer_than_80_chars, deprecated_member_use

part of 'extensions.dart';

// ignore: public_member_api_docs
typedef ObserverCallback<T> = void Function(T prev, T next);

// coverage:ignore-start
// requires a manual GC trigger to test
final Finalizer<void Function()> _finalizer = Finalizer((fn) => fn());
// coverage:ignore-end

/// The latest `observe` callback for each beacon subscription key.
///
/// Keyed by beacon identity (via [Expando]) and by the widget's subscription
/// key, so rebuilding a widget can replace its callback without creating a
/// second subscription.
final _observerCallbacks = Expando<Map<int, VoidCallback>>();

/// @macro WidgetUtils
extension WidgetUtils<T> on BaseBeacon<T> {
  /// Watches a beacon and triggers a widget
  /// rebuild when its value changes.
  ///
  /// Note: must be called within a widget's build method.
  ///
  /// Usage:
  /// ```dart
  /// final counter = Beacon.writable(0);
  ///
  /// class Counter extends StatelessWidget {
  ///  const Counter({super.key});
  ///
  ///  @override
  ///  Widget build(BuildContext context) {
  ///    final count = counter.watch(context);
  ///    return Text(count.toString());
  ///  }
  ///}
  /// ```
  T watch(BuildContext context) {
    final key = identityHashCode(context);

    return _watchOrObserve(
      key,
      context,
    );
  }

  /// Observes the state of a beacon and triggers a callback with the current state.
  ///
  /// The callback is provided with the current state of the beacon and a BuildContext.
  /// This can be used to show snackbars or other side effects.
  ///
  /// Usage:
  /// ```dart
  /// final exampleBeacon = Beacon.writable("Initial State");
  ///
  /// class ExampleWidget extends StatelessWidget {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     context.observe(exampleBeacon, (state, context) {
  ///       ScaffoldMessenger.of(context).showSnackBar(
  ///         SnackBar(content: Text(state)),
  ///       );
  ///     });
  ///     return Container();
  ///   }
  /// }
  /// ```
  void observe(BuildContext context, ObserverCallback<T> callback) {
    final key = Object.hash(
      identityHashCode(context),
      'isObserving', // create 1 subscription for each widget
    );

    _watchOrObserve(
      key,
      context,
      callback: () => callback(previousValue as T, peek()),
    );
  }

  T _watchOrObserve(
    int key,
    BuildContext context, {
    VoidCallback? callback,
  }) {
    final callbacks = callback == null
        ? null
        : (_observerCallbacks[this] ??= <int, VoidCallback>{});

    // Rebuilding with a new `observe` callback must replace the old one, even
    // though the beacon subscription itself already exists.
    if (callback != null) callbacks![key] = callback;

    if ($$widgetSubscribers$$.contains(key)) {
      return peek();
    }

    $$widgetSubscribers$$.add(key);

    final elementRef = WeakReference(context as Element);
    late VoidCallback unsub;

    void handleNewValue(T value) {
      if (elementRef.target?.mounted == true) {
        final cb = callbacks?[key];
        if (cb != null) {
          cb();
        } else {
          elementRef.target!.markNeedsBuild();
        }
      } else {
        unsub();
        $$widgetSubscribers$$.remove(key);
        callbacks?.remove(key);
      }
    }

    unsub = subscribe(
      handleNewValue,
      startNow: false,
    );

    // coverage:ignore-start
    // clean up if the widget is disposed
    // and value is never modified again
    _finalizer.attach(
      context,
      () {
        unsub();
        $$widgetSubscribers$$.remove(key);
        callbacks?.remove(key);
      },
    );
    // coverage:ignore-end

    return peek();
  }
}
