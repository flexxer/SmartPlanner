import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';

export 'device_calendar_service.dart' show DeviceCalendarService;

/// Алиас сервиса календаря для внедрения в BLoC и UI.
typedef CalendarService = DeviceCalendarService;
