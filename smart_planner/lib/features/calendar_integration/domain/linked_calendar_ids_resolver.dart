import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';

/// Resolves linked device calendar ids against calendars currently on the device.
abstract final class LinkedCalendarIdsResolver {
  LinkedCalendarIdsResolver._();

  static String normalizeId(String id) => id.trim();

  /// Returns ids that exist on the device. Repairs [CalendarPreferencesRepository]
  /// when saved ids are stale (account re-sync, OEM calendar id changes).
  static Future<List<String>> resolve({
    required DeviceCalendarService calendarService,
    required CalendarPreferencesRepository preferences,
    List<String>? overrideIds,
    bool persistRepair = true,
  }) async {
    if (!await calendarService.ensurePermissions()) {
      return const <String>[];
    }

    final List<DeviceCalendarInfo> calendars =
        await calendarService.getCalendars();
    if (calendars.isEmpty) {
      return const <String>[];
    }

    final Map<String, String> canonicalByNormalized = <String, String>{
      for (final DeviceCalendarInfo calendar in calendars)
        normalizeId(calendar.id): calendar.id,
    };

    List<String>? rawIds = overrideIds;
    if (rawIds == null || rawIds.isEmpty) {
      rawIds = await preferences.getSelectedCalendarIds();
    }

    if (rawIds != null && rawIds.isNotEmpty) {
      final List<String> matched = _matchToDevice(rawIds, canonicalByNormalized);
      if (matched.isNotEmpty) {
        if (persistRepair && !_sameIds(rawIds, matched)) {
          await preferences.saveSelectedCalendarIds(matched);
        }
        return matched;
      }
    }

    final List<String> defaults =
        await calendarService.resolveDefaultCalendarIds();
    final List<String> resolvedDefaults = defaults
        .map((String id) => canonicalByNormalized[normalizeId(id)] ?? id)
        .where(canonicalByNormalized.containsValue)
        .toList(growable: false);

    final List<String> fallback = resolvedDefaults.isNotEmpty
        ? resolvedDefaults
        : calendars.map((DeviceCalendarInfo c) => c.id).toList(growable: false);

    if (persistRepair) {
      await preferences.saveSelectedCalendarIds(fallback);
    }
    return fallback;
  }

  static List<String> _matchToDevice(
    List<String> rawIds,
    Map<String, String> canonicalByNormalized,
  ) {
    final List<String> matched = <String>[];
    final Set<String> seen = <String>{};
    for (final String raw in rawIds) {
      final String? canonical = canonicalByNormalized[normalizeId(raw)];
      if (canonical == null || !seen.add(canonical)) {
        continue;
      }
      matched.add(canonical);
    }
    return matched;
  }

  static bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (normalizeId(a[i]) != normalizeId(b[i])) {
        return false;
      }
    }
    return true;
  }

  /// When the user linked at least one calendar, import from **all** user
  /// calendars on the device (excluding birthday/holiday feeds). External
  /// events often land on a different calendar row than the checkbox label
  /// (e.g. localized «Мой календарь» vs email-named primary).
  static List<String> expandForDeviceSync({
    required List<String> selectedIds,
    required List<DeviceCalendarInfo> allCalendars,
  }) {
    if (selectedIds.isEmpty) {
      return const <String>[];
    }

    final Set<String> syncIds = <String>{
      ...allCalendars.map((DeviceCalendarInfo c) => c.id),
      ...selectedIds,
    };

    return syncIds.toList(growable: false);
  }

  /// Resolves user-selected calendar ids for device read/write (no expansion).
  static Future<List<String>> resolveForDeviceSync({
    required DeviceCalendarService calendarService,
    required CalendarPreferencesRepository preferences,
    List<String>? overrideIds,
  }) async {
    return resolve(
      calendarService: calendarService,
      preferences: preferences,
      overrideIds: overrideIds,
    );
  }
}
