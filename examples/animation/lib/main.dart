import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';

// Bouncing ball animation using state_beacon
const _kBounceDuration = Duration(milliseconds: 800);
const _kBounceInterval = Duration(milliseconds: 16); // ~60fps

final _bounceAnimation = Beacon.progress(
  interval: _kBounceInterval,
  totalDuration: _kBounceDuration,
  manualStart: true,
  initialValue: 0.0,
  onProgress: (progress) {
    // Create a bouncing effect using a sine wave
    // The ball goes up and down in a parabolic motion
    return (1.0 - progress * progress) * 200;
  },
);

class BouncingBallView extends StatelessWidget {
  const BouncingBallView({super.key});

  @override
  Widget build(BuildContext context) {
    final bounceProgress = _bounceAnimation.watch(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Bouncing Ball Animation')),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ground line
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                color: Colors.grey[300],
              ),
            ),
            // Bouncing ball
            AnimatedPositioned(
              duration: _kBounceDuration * 0.5,
              bottom: 50 + bounceProgress, // Move up to 200px from ground
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _bounceAnimation.start(),
        tooltip: 'Bounce Ball',
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}

class AnimationDemoApp extends StatelessWidget {
  const AnimationDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'State Beacon Animation Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animation Example')),
      body: const BouncingBallView(),
    );
  }
}

void main() {
  runApp(const LiteRefScope(child: AnimationDemoApp()));
}
