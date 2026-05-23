import 'package:url_launcher/url_launcher.dart';

/// Opens contacts, maps, and URLs via platform handlers.
class AttachmentLauncherService {
  AttachmentLauncherService._();

  static Future<bool> dialPhone(String phone) {
    final String normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return _launch(Uri(scheme: 'tel', path: normalized));
  }

  static Future<bool> sendSms(String phone) {
    final String normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return _launch(Uri(scheme: 'sms', path: normalized));
  }

  static Future<bool> sendEmail(String email) {
    return _launch(Uri(scheme: 'mailto', path: email));
  }

  static Future<bool> openUrl(String url) {
    final Uri uri = Uri.parse(_ensureScheme(url));
    return _launch(uri);
  }

  static Future<bool> openMaps({
    required double latitude,
    required double longitude,
  }) async {
    final String coords = '$latitude,$longitude';
    final Uri maps = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$coords',
    );
    if (await canLaunchUrl(maps)) {
      return launchUrl(maps, mode: LaunchMode.externalApplication);
    }
    return _launch(Uri.parse('geo:$latitude,$longitude?q=$coords'));
  }

  static String _ensureScheme(String url) {
    final String trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  static Future<bool> _launch(Uri uri) async {
    if (!await canLaunchUrl(uri)) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
