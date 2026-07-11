# Device calendar integration (Google included)

DayLinx uses the [`device_calendar`](https://pub.dev/packages/device_calendar) plugin. It does **not** call the Google Calendar REST API and does **not** require OAuth client IDs in the project.

## How Google Calendar works

1. On the phone, open **Settings → Accounts** and add a Google account (if needed).
2. Open the system **Calendar** app and enable sync for the calendars you want.
3. In DayLinx: **Settings → Calendars** → allow calendar permission → select the Google calendars (shown with account name and a Google label).

Use **Open device calendar** in the same screen to jump to the system Calendar app (or sync / app permission settings as a fallback).

Events are pushed to Android’s calendar provider through `device_calendar` `createOrUpdateEvent` — the same data the built-in Calendar app uses.

## Permissions

- `READ_CALENDAR` — list calendars for the sync picker (writable filter)
- `WRITE_CALENDAR` — push events to writable device calendars on manual sync

## Event storage and sync model

- **All events are stored in Isar first** (local-first). The dashboard, grid, notifications, and widgets read from Isar only.
- **No automatic import** from device calendars (no pull on dashboard load, pull-to-refresh, foreground resume, or grid open).
- **Outbound sync only**, triggered explicitly:
  - **Create event:** optional multi-select of calendars enabled in Settings; sync runs on Save when at least one calendar is checked.
  - **Event detail:** AppBar **Sync** button → multi-select sheet → push to selected writable calendars.
- Sync mappings (`calendarId` → `deviceEventId`) are stored in `CalendarEvent.syncedDeviceEventIdsJson`.
- **Delete** removes the event from all synced device calendars and from Isar.

## Settings → Calendars

User-selected calendars define the pool shown in sync pickers (create form + event detail). They are **not** used to filter which events appear on the dashboard.

## Developer notes

- Linked calendar IDs: `CalendarPreferencesRepository`.
- Outbound sync: `EventCalendarSyncService` + `DeviceCalendarService.createOrUpdateEvent`.
- Local CRUD: `CalendarEventWriteService.saveLocal` / `LocalCalendarEventRepository`.
- Visible lists: `VisibleCalendarEventsMerger.fromStored` (Isar + recurrence expansion).
- Reusable sync UI: `EventSyncCalendarsSelector` (inline) and `EventSyncCalendarsSheet` (detail screen).
- `SyncAccount` / `SyncRecord` in Isar remain for a future cloud sync engine; they are not used for calendar sync today.
- Legacy `upsertDeviceEvents` / `purgeStaleDeviceEvents` remain in the repository for compatibility but are no longer called from dashboard loaders.
