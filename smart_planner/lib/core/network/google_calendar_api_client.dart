/// Заглушка HTTP-клиента для Google Calendar API (OAuth — в calendar_integration).
abstract class GoogleCalendarApiClient {
  Future<void> dispose();
}

class GoogleCalendarApiClientStub implements GoogleCalendarApiClient {
  @override
  Future<void> dispose() async {}
}
