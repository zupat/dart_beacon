import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';

// Bouncing ball animation using state_beacon
const _kBounceDuration = Duration(milliseconds: 800);
const _kBounceInterval = Duration(milliseconds: 16); // ~60fps

final _bounceAnimation = Beacon.progress(
  interval: _kBounceInterval,
  totalDuration: _kBounceDuration,
  loop: true,
  initialValue: 0.0,
  onStart: () => 0.0,
  onProgress: (p) {
    // Parabolic bounce: 0 -> 1 -> 0
    // h = 4 * max_height * p * (1 - p)
    // max_height = 200
    return 800 * p * (1 - p);
  },
);

void main() {
  runApp(
    MaterialApp(
      title: 'State Beacon Animation Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    ),
  );
}

class BouncingBall extends StatelessWidget {
  const BouncingBall({super.key});

  @override
  Widget build(BuildContext context) {
    final bounceProgress = _bounceAnimation.watch(context);

    return Center(
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
          Positioned(
            bottom: 50 + bounceProgress, // Move up to 200px from ground
            child: Icon(
              Icons.sports_basketball_outlined,
              size: 50,
              color: Colors.orange.shade300,
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bouncing Ball Animation')),
      body: const BouncingBall(),
      floatingActionButton: Builder(builder: (context) {
        final status = _bounceAnimation.status.watch(context);
        final (icon, onPressed) = switch (status) {
          ProgressStatus.running => (Icons.pause, _bounceAnimation.pause),
          ProgressStatus.paused => (Icons.play_arrow, _bounceAnimation.resume),
          ProgressStatus.stopped => (Icons.play_arrow, _bounceAnimation.start),
        };
        return FloatingActionButton(
          onPressed: onPressed,
          tooltip: 'Bounce Ball',
          child: Icon(icon),
        );
      }),
    );
  }
}
