import 'package:flutter/widgets.dart';
import 'package:state_beacon_core/state_beacon_core.dart';

/// This is a wrapper around a [TextEditingController] that
/// allows you to hook into the controller's lifecycle.
class _TextEditingController extends TextEditingController {
  _TextEditingController({super.text});

  VoidCallback? disposeCallback;
  bool _disposed = false;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    disposeCallback?.call();
    super.dispose();
  }
}

/// A beacon that wraps a [TextEditingController].
class TextEditingBeacon extends WritableBeacon<TextEditingValue> {
  /// @macro [TextEditingBeacon]
  TextEditingBeacon({String? text, BeaconGroup? group, super.name})
      : _controller = _TextEditingController(text: text),
        super(
          initialValue: text == null
              ? TextEditingValue.empty
              : TextEditingValue(text: text),
        ) {
    var syncingToController = false;
    var syncingToBeacon = false;

    _controller.addListener(() {
      final controllerValue = _controller.value;
      if (syncingToController &&
          (identical(controllerValue, peek()) || controllerValue == peek())) {
        return;
      }
      if (syncingToBeacon) return;
      syncingToBeacon = true;
      try {
        set(controllerValue, force: true);
      } finally {
        syncingToBeacon = false;
      }
    });

    subscribeSynchronously(
      (v) {
        if (syncingToBeacon &&
            (identical(_controller.value, v) || _controller.value == v)) {
          return;
        }
        syncingToController = true;
        try {
          _controller.value = v;
        } finally {
          syncingToController = false;
        }
      },
      startNow: false,
    );

    _controller.disposeCallback = dispose;
    group?.add(this);
  }

  final _TextEditingController _controller;

  /// The current [TextEditingController].
  TextEditingController get controller => _controller;

  /// The current string the user is editing.
  String get text => _controller.text;

  set text(String newText) {
    _controller.text = newText;
  }

  /// The currently selected [text].
  ///
  /// If the selection is collapsed, then this property gives
  /// the offset of the cursor within the text.
  TextSelection get selection => _controller.selection;

  /// Alias for controller.clear()
  void clear() => _controller.clear();

  @override
  void dispose() {
    // we are being disposed so controller doesn't
    // need to call our dispose method.
    _controller.disposeCallback = null;

    _controller.dispose();
    super.dispose();
  }
}
