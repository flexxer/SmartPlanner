# Device calendar integration (Google included)

DayLinx uses the [`device_calendar`](https://pub.dev/packages/device_calendar) plugin. It does **not** call the Google Calendar REST API and does **not** require OAuth client IDs in the project.

## How Google Calendar works

1. On the phone, open **Settings → Accounts** and add a Google account (if needed).
2. Open the system **Calendar** app and enable sync for the calendars you want.
3. In DayLinx: **Settings → Calendars** → allow calendar permission → select the Google calendars (shown with account name and a Google label).

Use **Open device calendar** in the same screen to jump to the system Calendar app (or sync / app permission settings as a fallback).

Events are read through Android’s calendar provider—the same data the built-in Calendar app uses.

On Android, DayLinx reads instances via a **direct** `CalendarContract` query (Instances + Events master table). When Google edits event times, **Instances** can lag; **Events.DTSTART/DTEND** is preferred for the same `eventId`. The `device_calendar` plugin is still used for calendar list, permissions, and write-back.

## Permissions

- `READ_CALENDAR` — load events for the dashboard and notifications
- `WRITE_CALENDAR` — create, edit, and delete events on writable device calendars

## Write-back (create / edit / delete)

When you save an event in DayLinx and pick a **writable** calendar, the app calls `device_calendar` `createOrUpdateEvent`. The event appears in the system Calendar app (and syncs to Google if that calendar is synced). DayLinx keeps Isar metadata: reminders, recurrence JSON, task links.

**Read-only** calendars (some shared calendars): the event is stored in Isar only; a snackbar explains that it was not written to the device provider.

## Import from device (read path)

On dashboard load, pull-to-refresh, and when the app returns to the foreground, DayLinx:

1. Fetches events for the selected day from the device provider.
2. Upserts them into Isar (`upsertDeviceEvents`).
3. Builds the event strip from that **fresh fetch** (not from a stale Isar-only filter).
4. **Purges stale device rows** in the sync window that were not returned by the latest fetch (non-recurring only; local `local_*` rows are kept).

Edits made in Google Calendar appear after sync reaches the device calendar, then after the next refresh or resume. There is no background polling of Google.

**If events created in the system Calendar app do not appear:** ensure at least one calendar is selected in **Settings → Calendars** and calendar permission is granted. DayLinx imports from **all user calendars on the device** when any calendar is selected — external events often land on a different calendar row (e.g. localized «Мой календарь» vs the email-named primary).

**If times do not update:** pull to refresh on the dashboard or reopen the app (foreground reload). Ensure calendar permission is granted.

## Developer notes

- Linked calendar IDs are stored in `CalendarPreferencesRepository`.
- Device rows are upserted via `LocalCalendarEventRepository.upsertDeviceEvents` with `EventSource.device`.
- Visible list merge: `VisibleCalendarEventsMerger` in `lib/features/dashboard/domain/`.
- Stale purge: `DeviceCalendarStalePurge` + `LocalCalendarEventRepository.purgeStaleDeviceEvents`.
- `SyncAccount` / `SyncRecord` in Isar remain for a future cloud sync engine; they are not used for calendar import today.
