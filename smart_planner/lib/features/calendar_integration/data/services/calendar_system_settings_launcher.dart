import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the device calendar app or related system settings (no OAuth keys).
abstract final class CalendarSystemSettingsLauncher {
  CalendarSystemSettingsLauncher._();

  static const MethodChannel _channel = MethodChannel(
    'com.aliakseipcholkin.smart_planner/calendar_settings',
  );

  static Future<bool> open() async {
    if (kIsWeb) {
      return false;
    }
    if (Platform.isAndroid) {
      try {
        final bool? opened =
            await _channel.invokeMethod<bool>('openCalendarSettings');
        return opened ?? false;
      } on PlatformException {
        return false;
      }
    }
    if (Platform.isIOS) {
      final Uri calshow = Uri.parse('calshow://');
      if (await canLaunchUrl(calshow)) {
        return launchUrl(calshow, mode: LaunchMode.externalApplication);
      }
      final Uri settings = Uri.parse('app-settings:');
      if (await canLaunchUrl(settings)) {
        return launchUrl(settings, mode: LaunchMode.externalApplication);
      }
      return false;
    }
    return false;
  }
}
