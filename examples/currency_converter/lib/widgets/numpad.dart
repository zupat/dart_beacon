part of 'widgets.dart';

class Numpad extends StatelessWidget {
  const Numpad({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: KeyboardListener(
        autofocus: true,
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is! KeyDownEvent) return;

          final controller = controllerRef.read(context);
          final keyLabel = _getKeyLabel(event.logicalKey);

          if (keyLabel != null) {
            if (keyLabel == 'clear') {
              controller.clearAmount();
            } else if (keyLabel == 'backspace') {
              controller.removeLastDigit();
            } else {
              controller.addDigit(keyLabel);
            }
          }
        },
        child: GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 1.7,
          children: List.generate(12, (index) {
            if (index < 9) {
              return _NumPadButton('${index + 1}');
            } else if (index == 9) {
              return _NumPadButton('.');
            } else if (index == 10) {
              return _NumPadButton('0');
            } else {
              return _ClearButton();
            }
          }),
        ),
      ),
    );
  }

  String? _getKeyLabel(LogicalKeyboardKey key) {
    // Handle numeric keys (0-9)
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      return '0';
    } else if (key == LogicalKeyboardKey.digit1 ||
        key == LogicalKeyboardKey.numpad1) {
      return '1';
    } else if (key == LogicalKeyboardKey.digit2 ||
        key == LogicalKeyboardKey.numpad2) {
      return '2';
    } else if (key == LogicalKeyboardKey.digit3 ||
        key == LogicalKeyboardKey.numpad3) {
      return '3';
    } else if (key == LogicalKeyboardKey.digit4 ||
        key == LogicalKeyboardKey.numpad4) {
      return '4';
    } else if (key == LogicalKeyboardKey.digit5 ||
        key == LogicalKeyboardKey.numpad5) {
      return '5';
    } else if (key == LogicalKeyboardKey.digit6 ||
        key == LogicalKeyboardKey.numpad6) {
      return '6';
    } else if (key == LogicalKeyboardKey.digit7 ||
        key == LogicalKeyboardKey.numpad7) {
      return '7';
    } else if (key == LogicalKeyboardKey.digit8 ||
        key == LogicalKeyboardKey.numpad8) {
      return '8';
    } else if (key == LogicalKeyboardKey.digit9 ||
        key == LogicalKeyboardKey.numpad9) {
      return '9';
    }

    // Handle decimal point
    if (key == LogicalKeyboardKey.period ||
        key == LogicalKeyboardKey.numpadDecimal) {
      return '.';
    }

    if (key == LogicalKeyboardKey.backspace) {
      return 'backspace';
    }

    if (key == LogicalKeyboardKey.delete) {
      return 'clear';
    }

    return null;
  }
}

class _NumPadButton extends StatelessWidget {
  final String label;

  const _NumPadButton(this.label);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        onPressed: () => controllerRef.read(context).addDigit(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurfaceVariant,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
          padding: const EdgeInsets.all(8),
        ),
        child: Text(label, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        onPressed: controllerRef.read(context).removeLastDigit,
        onLongPress: controllerRef.read(context).clearAmount,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.errorContainer,
          foregroundColor: colorScheme.onSurfaceVariant,
          side: BorderSide(color: colorScheme.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
          padding: const EdgeInsets.all(8),
        ),
        child: const Icon(Icons.backspace),
      ),
    );
  }
}
