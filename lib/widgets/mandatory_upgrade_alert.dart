import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

/// Uses Upgrader's default Material dialog while preventing every dismissal
/// path until the application has been updated.
class MandatoryUpgradeAlert extends UpgradeAlert {
  MandatoryUpgradeAlert({
    super.key,
    required super.upgrader,
    required super.child,
  }) : super(
         barrierDismissible: false,
         showIgnore: false,
         showLater: false,
         shouldPopScope: _preventDismissal,
       );

  static bool _preventDismissal() => false;

  @override
  UpgradeAlertState createState() => _MandatoryUpgradeAlertState();
}

class _MandatoryUpgradeAlertState extends UpgradeAlertState {
  @override
  void onUserUpdated(BuildContext context, bool shouldPop) {
    // Keep the dialog open when Play Store launches. If the user returns
    // without updating, the application remains inaccessible behind it.
    widget.upgrader.sendUserToAppStore();
  }
}
