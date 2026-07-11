import 'dart:convert';

/// JSON map of device calendar id → device event id for outbound sync.
abstract final class CalendarEventSyncMapping {
  CalendarEventSyncMapping._();

  static Map<String, String> decode(String? json) {
    if (json == null || json.trim().isEmpty) {
      return <String, String>{};
    }
    try {
      final Object? parsed = jsonDecode(json);
      if (parsed is! Map) {
        return <String, String>{};
      }
      final Map<String, String> result = <String, String>{};
      parsed.forEach((Object? key, Object? value) {
        final String calendarId = key?.toString().trim() ?? '';
        final String deviceEventId = value?.toString().trim() ?? '';
        if (calendarId.isNotEmpty && deviceEventId.isNotEmpty) {
          result[calendarId] = deviceEventId;
        }
      });
      return result;
    } catch (_) {
      return <String, String>{};
    }
  }

  static String? encode(Map<String, String> mapping) {
    if (mapping.isEmpty) {
      return null;
    }
    return jsonEncode(mapping);
  }

  static List<String> calendarIds(Map<String, String> mapping) =>
      mapping.keys.toList(growable: false);
}
