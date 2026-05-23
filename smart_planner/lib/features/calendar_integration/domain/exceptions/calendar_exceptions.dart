/// Пользователь не выдал доступ к календарю.
class CalendarPermissionDeniedException implements Exception {
  CalendarPermissionDeniedException([this.message = 'Доступ к календарю не предоставлен']);

  final String message;

  @override
  String toString() => 'CalendarPermissionDeniedException: $message';
}

/// Ошибка при обращении к device_calendar.
class CalendarServiceException implements Exception {
  CalendarServiceException(this.operation, this.details);

  final String operation;
  final String details;

  @override
  String toString() =>
      'CalendarServiceException($operation): $details';
}
