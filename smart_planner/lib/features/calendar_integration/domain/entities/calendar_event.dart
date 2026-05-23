/// Доменная сущность события календаря (без привязки к Isar).
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.calendarId,
    required this.colorValue,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String calendarId;
  final int colorValue;
}
