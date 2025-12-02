import 'dart:async';
import 'dart:isolate';

import 'package:reyveld/config.dart';
import '/scripting/sinterface.dart';

part 'tracker.interface.dart';

/// Will check if any changes have occurred with the [changeChecker] function.
class ChangeTracker {
  Isolate? _isolate;
  final Future<bool> Function() changeChecker;
  final StreamController _controller;
  final Duration? interval;

  Stream get onChange => _controller.stream;

  ChangeTracker(this.changeChecker, {this.interval})
      : _controller = StreamController.broadcast();

  Future<void> start() async {
    _isolate = await Isolate.spawn(_run, this);
  }

  /// Stops the tracker.
  Future<void> stop() async {
    _isolate?.kill();
    _isolate = null;
  }

  static Future<void> _run(ChangeTracker tracker) async {
    while (true) {
      if (await tracker.changeChecker()) {
        tracker._notifyListeners();
      }
      await Future.delayed(
          tracker.interval ?? await RConfig.defaultTrackerInterval);
    }
  }

  void _notifyListeners() {
    _controller.add(null);
  }
}
