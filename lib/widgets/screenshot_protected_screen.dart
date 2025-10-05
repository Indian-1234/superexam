import 'package:flutter/material.dart';
import 'package:superexam/utils/screenshot_protection.dart';

class ScreenshotProtectedScreen extends StatefulWidget {
  final Widget child;
  final bool enforceProtection;

  const ScreenshotProtectedScreen({
    Key? key,
    required this.child,
    this.enforceProtection = true,
  }) : super(key: key);

  @override
  State<ScreenshotProtectedScreen> createState() =>
      _ScreenshotProtectedScreenState();
}

class _ScreenshotProtectedScreenState extends State<ScreenshotProtectedScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.enforceProtection) {
      ScreenshotProtection.enableProtection();
    }
  }

  @override
  void dispose() {
    if (widget.enforceProtection) {
      ScreenshotProtection.disableProtection();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
