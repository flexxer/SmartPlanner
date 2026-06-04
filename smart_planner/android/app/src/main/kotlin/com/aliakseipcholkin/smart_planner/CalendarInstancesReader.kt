package com.aliakseipcholkin.smart_planner

import android.content.ContentResolver
import android.content.ContentUris
import android.database.Cursor
import android.provider.CalendarContract
import org.json.JSONArray
import org.json.JSONObject

/**
 * Reads calendar events from [CalendarContract.Instances] and, as fallback,
 * [CalendarContract.Events] (master table).
 *
 * Google Calendar on Android sometimes shows events that exist in [Events] but
 * are missing from expanded [Instances] until sync completes.
 */
object CalendarInstancesReader {

    private val INSTANCE_PROJECTION: Array<String> = arrayOf(
        CalendarContract.Instances.EVENT_ID,
        CalendarContract.Events.TITLE,
        CalendarContract.Instances.BEGIN,
        CalendarContract.Instances.END,
        CalendarContract.Events.ALL_DAY,
        CalendarContract.Events.CALENDAR_ID,
    )

    private val EVENTS_PROJECTION: Array<String> = arrayOf(
        CalendarContract.Events._ID,
        CalendarContract.Events.TITLE,
        CalendarContract.Events.DTSTART,
        CalendarContract.Events.DTEND,
        CalendarContract.Events.ALL_DAY,
        CalendarContract.Events.CALENDAR_ID,
        CalendarContract.Events.RRULE,
    )

    private const val I_EVENT_ID = 0
    private const val I_TITLE = 1
    private const val I_BEGIN = 2
    private const val I_END = 3
    private const val I_ALL_DAY = 4
    private const val I_CALENDAR_ID = 5

    private const val E_EVENT_ID = 0
    private const val E_TITLE = 1
    private const val E_DTSTART = 2
    private const val E_DTEND = 3
    private const val E_ALL_DAY = 4
    private const val E_CALENDAR_ID = 5
    private const val E_RRULE = 6

    fun retrieveEventsJson(
        contentResolver: ContentResolver,
        calendarIds: List<String>,
        startMs: Long,
        endMs: Long,
    ): String {
        val allowedIds = calendarIds.mapNotNull { it.toLongOrNull() }.toSet()
        if (allowedIds.isEmpty()) {
            return "[]"
        }
        return rowsToJson(
            mergeRows(
                instances = queryInstances(
                    contentResolver = contentResolver,
                    startMs = startMs,
                    endMs = endMs,
                    calendarIdFilter = allowedIds,
                ),
                eventsMaster = queryEventsMaster(
                    contentResolver = contentResolver,
                    startMs = startMs,
                    endMs = endMs,
                    calendarIdFilter = allowedIds,
                ),
            ),
        )
    }

    private fun mergeRows(
        instances: List<JSONObject>,
        eventsMaster: List<JSONObject>,
    ): List<JSONObject> {
        val byId = linkedMapOf<String, JSONObject>()
        for (row in instances) {
            byId[row.getString("eventId")] = row
        }
        for (row in eventsMaster) {
            val id = row.getString("eventId")
            val existing = byId[id]
            if (existing == null) {
                byId[id] = row
                continue
            }
            // Events master holds the latest DTSTART/DTEND after Google edits;
            // Instances can lag until the sync adapter re-expands rows.
            existing.put("title", row.getString("title"))
            existing.put("startMs", row.getLong("startMs"))
            existing.put("endMs", row.getLong("endMs"))
            existing.put("allDay", row.getBoolean("allDay"))
            existing.put("calendarId", row.getString("calendarId"))
            existing.put("fromEventsTable", true)
        }
        return byId.values.toList()
    }

    private fun queryInstances(
        contentResolver: ContentResolver,
        startMs: Long,
        endMs: Long,
        calendarIdFilter: Set<Long>?,
    ): List<JSONObject> {
        val eventsUriBuilder = CalendarContract.Instances.CONTENT_URI.buildUpon()
        ContentUris.appendId(eventsUriBuilder, startMs)
        ContentUris.appendId(eventsUriBuilder, endMs)

        var selection = "(${CalendarContract.Events.DELETED} != 1)"
        if (calendarIdFilter != null && calendarIdFilter.isNotEmpty()) {
            val idList = calendarIdFilter.joinToString(",")
            selection += " AND (${CalendarContract.Events.CALENDAR_ID} IN ($idList))"
        }

        val cursor: Cursor? = contentResolver.query(
            eventsUriBuilder.build(),
            INSTANCE_PROJECTION,
            selection,
            null,
            CalendarContract.Events.DTSTART + " ASC",
        )

        val results = mutableListOf<JSONObject>()
        val seenInstanceKeys = mutableSetOf<String>()

        cursor.use { c ->
            if (c == null) {
                return results
            }
            while (c.moveToNext()) {
                val eventId = c.getLong(I_EVENT_ID).toString()
                val beginMs = c.getLong(I_BEGIN)
                val instanceKey = "${eventId}_$beginMs"
                if (!seenInstanceKeys.add(instanceKey)) {
                    continue
                }
                results.add(
                    buildRow(
                        eventId = eventId,
                        title = c.getString(I_TITLE) ?: "",
                        startMs = c.getLong(I_BEGIN),
                        endMs = c.getLong(I_END),
                        allDay = c.getInt(I_ALL_DAY) > 0,
                        calendarId = c.getLong(I_CALENDAR_ID).toString(),
                        fromEventsTable = false,
                    ),
                )
            }
        }
        return results
    }

    /**
     * Non-recurring rows from [CalendarContract.Events] overlapping [startMs..endMs].
     */
    private fun queryEventsMaster(
        contentResolver: ContentResolver,
        startMs: Long,
        endMs: Long,
        calendarIdFilter: Set<Long>?,
    ): List<JSONObject> {
        var selection =
            "(${CalendarContract.Events.DELETED} != 1)" +
                " AND (${CalendarContract.Events.DTSTART} < ?)" +
                " AND (${CalendarContract.Events.DTEND} > ?)" +
                " AND (${CalendarContract.Events.RRULE} IS NULL OR ${CalendarContract.Events.RRULE} = '')"
        val args = mutableListOf(endMs.toString(), startMs.toString())

        if (calendarIdFilter != null && calendarIdFilter.isNotEmpty()) {
            val idList = calendarIdFilter.joinToString(",")
            selection += " AND (${CalendarContract.Events.CALENDAR_ID} IN ($idList))"
        }

        val cursor: Cursor? = contentResolver.query(
            CalendarContract.Events.CONTENT_URI,
            EVENTS_PROJECTION,
            selection,
            args.toTypedArray(),
            CalendarContract.Events.DTSTART + " ASC",
        )

        val results = mutableListOf<JSONObject>()
        cursor.use { c ->
            if (c == null) {
                return results
            }
            while (c.moveToNext()) {
                val rrule = c.getString(E_RRULE)
                if (!rrule.isNullOrBlank()) {
                    continue
                }
                val eventId = c.getLong(E_EVENT_ID).toString()
                var start = c.getLong(E_DTSTART)
                var end = c.getLong(E_DTEND)
                val allDay = c.getInt(E_ALL_DAY) > 0
                if (allDay && end <= start) {
                    end = start + 86_400_000L
                }
                if (start >= endMs || end <= startMs) {
                    continue
                }
                results.add(
                    buildRow(
                        eventId = eventId,
                        title = c.getString(E_TITLE) ?: "",
                        startMs = start,
                        endMs = end,
                        allDay = allDay,
                        calendarId = c.getLong(E_CALENDAR_ID).toString(),
                        fromEventsTable = true,
                    ),
                )
            }
        }
        return results
    }

    private fun buildRow(
        eventId: String,
        title: String,
        startMs: Long,
        endMs: Long,
        allDay: Boolean,
        calendarId: String,
        fromEventsTable: Boolean,
    ): JSONObject {
        return JSONObject().apply {
            put("eventId", eventId)
            put("calendarId", calendarId)
            put("title", title)
            put("startMs", startMs)
            put("endMs", endMs)
            put("allDay", allDay)
            put("fromEventsTable", fromEventsTable)
        }
    }

    private fun rowsToJson(rows: List<JSONObject>): String {
        val allEvents = JSONArray()
        for (row in rows) {
            allEvents.put(row)
        }
        return allEvents.toString()
    }
}
