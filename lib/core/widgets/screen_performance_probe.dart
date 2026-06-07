import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:olmeg_connect/core/config/environment.dart';

class ScreenPerformanceProbe extends StatefulWidget {
  final String screenName;
  final Widget child;

  const ScreenPerformanceProbe({
    super.key,
    required this.screenName,
    required this.child,
  });

  @override
  State<ScreenPerformanceProbe> createState() => _ScreenPerformanceProbeState();
}

class _ScreenPerformanceProbeState extends State<ScreenPerformanceProbe> {
  final Stopwatch _stopwatch = Stopwatch()..start();
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
  }

  Future<void> _report() async {
    if (_reported) return;
    _reported = true;
    _stopwatch.stop();
    if (!_shouldReport()) return;
    try {
      await FirebaseFirestore.instance.collection('performance_events').add({
        'screenName': widget.screenName,
        'firstFrameMs': _stopwatch.elapsedMilliseconds,
        'environment': EnvironmentConfig.analyticsPrefix,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Performance telemetry must never block the user interface.
    }
  }

  bool _shouldReport() {
    if (!EnvironmentConfig.isProduction) return true;

    // Keep production telemetry low-volume and scattered; detailed monitoring
    // should use Firebase Performance/Crashlytics or backend aggregation.
    final minuteBucket = DateTime.now().toUtc().millisecondsSinceEpoch ~/
        Duration.millisecondsPerMinute;
    final seed = widget.screenName.codeUnits.fold<int>(
      minuteBucket,
      (value, codeUnit) => value + codeUnit,
    );
    return seed % 20 == 0;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
