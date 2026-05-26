import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/narrator_service.dart';

class ShakeDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onShake;
  final double shakeThresholdGravity;
  final int shakeSlopTimeMS;

  const ShakeDetector({
    Key? key,
    required this.child,
    required this.onShake,
    this.shakeThresholdGravity = 2.7,
    this.shakeSlopTimeMS = 1000,
  }) : super(key: key);

  @override
  State<ShakeDetector> createState() => _ShakeDetectorState();
}

class _ShakeDetectorState extends State<ShakeDetector> {
  StreamSubscription<AccelerometerEvent>? _streamSubscription;
  int _lastShakeTime = 0;

  @override
  void initState() {
    super.initState();
    _streamSubscription = accelerometerEventStream().listen((event) {
      double x = event.x;
      double y = event.y;
      double z = event.z;

      double gX = x / 9.80665;
      double gY = y / 9.80665;
      double gZ = z / 9.80665;

      double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

      if (gForce > widget.shakeThresholdGravity) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (_lastShakeTime + widget.shakeSlopTimeMS > now) {
          return;
        }
        _lastShakeTime = now;
        widget.onShake();
      }
    }, onError: (error) {
      // Ignore sensor errors (e.g. not available on emulator without config)
      print("Sensors not available: $error");
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
