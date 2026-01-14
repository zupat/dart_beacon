part of 'widgets.dart';

// This animates the slide offsets for both currency selectors
// when the currencies are swapped.
// It can be global since it lives for the lifetime of the app.

const _kSlideDurationMs = 300;
const _kSlideIntervalMs = 15;
const _kSlideMaxIterations = _kSlideDurationMs ~/ _kSlideIntervalMs;

final _slideOffsets = Beacon.progress<(double, double)>(
  const Duration(milliseconds: _kSlideIntervalMs),
  (i, progress) {
    // Move from sides to center: -1.0 -> 0.0 and 1.0 -> 0.0
    final leftOffset = -1.0 + (progress * 1.0);
    final rightOffset = 1.0 - (progress * 1.0);
    return (leftOffset, rightOffset);
  },
  maxIterations: _kSlideMaxIterations,
  manualStart: true,
  initialValue: (0.0, 0.0),
);

void _startAnimation() {
  // Restart the slide animation from the beginning.
  _slideOffsets.start();
}
