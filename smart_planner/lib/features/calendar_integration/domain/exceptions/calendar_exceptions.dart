/// User denied calendar access.
class CalendarPermissionDeniedException implements Exception {
  CalendarPermissionDeniedException([this.message]);

  final String? message;

  @override
  String toString() =>
      'CalendarPermissionDeniedException${message != null ? ': $message' : ''}';
}

/// Error from device_calendar plugin.
class CalendarServiceException implements Exception {
  CalendarServiceException(this.operation, this.details);

  final String operation;
  final String details;

  @override
  String toString() => 'CalendarServiceException($operation): $details';
}
