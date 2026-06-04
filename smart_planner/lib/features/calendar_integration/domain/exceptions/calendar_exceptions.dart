/// User denied calendar access.
class CalendarPermissionDeniedException implements Exception {
  CalendarPermissionDeniedException([this.message]);

  final String? message;

  @override
  String toString() =>
      'CalendarPermissionDeniedException${message != null ? ': $message' : ''}';
}

/// Target calendar does not allow creating or editing events.
class CalendarReadOnlyException implements Exception {
  CalendarReadOnlyException(this.calendarName);

  final String calendarName;

  @override
  String toString() => 'CalendarReadOnlyException($calendarName)';
}

/// Error from device_calendar plugin.
class CalendarServiceException implements Exception {
  CalendarServiceException(this.operation, this.details);

  final String operation;
  final String details;

  @override
  String toString() => 'CalendarServiceException($operation): $details';
}
