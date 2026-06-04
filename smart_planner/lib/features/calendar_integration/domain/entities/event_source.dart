/// Origin of a persisted [CalendarEvent] row.
enum EventSource {
  /// Created in-app only (`deviceEventId` prefix `local_`).
  local,

  /// Imported from the device calendar plugin.
  device,

  /// Legacy rows from an removed Google API import path; new data uses [device].
  googleApi,
}
