import 'package:no_screenshot/no_screenshot.dart';
import 'package:screen_protector/screen_protector.dart';

class ScreenshotProtection {
  static final ScreenshotProtection _instance =
      ScreenshotProtection._internal();
  static final _noScreenshot = NoScreenshot.instance;
  static bool _isProtected = false;

  factory ScreenshotProtection() {
    return _instance;
  }

  ScreenshotProtection._internal();

  static Future<void> enableProtection() async {
    if (!_isProtected) {
      try {
        // Enable screenshot blocking
        await _noScreenshot.screenshotOff();

        // Enable screen recording protection
        await ScreenProtector.protectDataLeakageOn();

        // Prevent screenshots in app switcher
        await ScreenProtector.preventScreenshotOn();

        _isProtected = true;
        print('Screen protection enabled successfully');
      } catch (e) {
        print('Failed to enable screen protection: $e');
      }
    }
  }

  static Future<void> disableProtection() async {
    if (_isProtected) {
      try {
        // Disable screenshot blocking
        await _noScreenshot.screenshotOn();

        // Disable screen recording protection
        await ScreenProtector.protectDataLeakageOff();

        // Allow screenshots
        await ScreenProtector.preventScreenshotOff();

        _isProtected = false;
        print('Screen protection disabled successfully');
      } catch (e) {
        print('Failed to disable screen protection: $e');
      }
    }
  }
}
