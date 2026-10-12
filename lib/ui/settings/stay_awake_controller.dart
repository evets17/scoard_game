import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// The "Stay awake when scoring" setting.
///
/// The screen is kept on only while the setting is on and a score entry
/// screen is showing.
class StayAwakeController extends ChangeNotifier {
  StayAwakeController({
    bool initialEnabled = false,
    Future<void> Function(bool enabled)? onEnabledChanged,
    Future<void> Function(bool keepAwake)? setWakeLock,
  })  : _enabled = initialEnabled,
        _onEnabledChanged = onEnabledChanged,
        _setWakeLock =
            setWakeLock ?? ((keepAwake) => WakelockPlus.toggle(enable: keepAwake));

  bool _enabled;
  final Future<void> Function(bool enabled)? _onEnabledChanged;
  final Future<void> Function(bool keepAwake) _setWakeLock;
  int _activeScoringScreens = 0;
  bool _isAwake = false;

  bool get enabled => _enabled;

  void setEnabled(bool enabled) {
    if (_enabled == enabled) {
      return;
    }

    _enabled = enabled;
    notifyListeners();
    _applyWakeLock();

    if (_onEnabledChanged != null) {
      unawaited(_onEnabledChanged(enabled));
    }
  }

  void beginScoring() {
    _activeScoringScreens += 1;
    _applyWakeLock();
  }

  void endScoring() {
    if (_activeScoringScreens > 0) {
      _activeScoringScreens -= 1;
    }
    _applyWakeLock();
  }

  void _applyWakeLock() {
    final keepAwake = _enabled && _activeScoringScreens > 0;
    if (keepAwake == _isAwake) {
      return;
    }

    _isAwake = keepAwake;
    unawaited(_setWakeLock(keepAwake));
  }
}

/// Keeps the screen on while [active], if the setting allows it.
class StayAwakeWhileScoring extends StatefulWidget {
  const StayAwakeWhileScoring({
    required this.controller,
    required this.active,
    required this.child,
    super.key,
  });

  final StayAwakeController controller;
  final bool active;
  final Widget child;

  @override
  State<StayAwakeWhileScoring> createState() => _StayAwakeWhileScoringState();
}

class _StayAwakeWhileScoringState extends State<StayAwakeWhileScoring> {
  bool _isScoring = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant StayAwakeWhileScoring oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller && _isScoring) {
      oldWidget.controller.endScoring();
      _isScoring = false;
    }
    _sync();
  }

  @override
  void dispose() {
    if (_isScoring) {
      widget.controller.endScoring();
    }
    super.dispose();
  }

  void _sync() {
    if (widget.active == _isScoring) {
      return;
    }

    _isScoring = widget.active;
    if (_isScoring) {
      widget.controller.beginScoring();
    } else {
      widget.controller.endScoring();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
