package com.aliakseipcholkin.smart_planner

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class DayLinxWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_day_medium)
            bindWidget(context, views, widgetData)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun bindWidget(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
    ) {
        views.setTextViewText(
            R.id.widget_date_label,
            widgetData.getString("dw_date_label", "") ?: "",
        )
        views.setTextViewText(
            R.id.widget_header_title,
            widgetData.getString("dw_header_title", "") ?: "",
        )

        val progressPercent = widgetData.getString("dw_progress_percent", "-1")?.toIntOrNull() ?: -1
        if (progressPercent < 0) {
            views.setViewVisibility(R.id.widget_progress_bar, View.GONE)
        } else {
            views.setViewVisibility(R.id.widget_progress_bar, View.VISIBLE)
            views.setProgressBar(R.id.widget_progress_bar, 100, progressPercent, false)
        }

        val nowVisible = widgetData.getString("dw_now_visible", "0") == "1"
        val nowTime = widgetData.getString("dw_now_time", "") ?: ""
        val nowTitle = widgetData.getString("dw_now_title", "") ?: ""
        val eventsEmpty = widgetData.getString("dw_events_empty", "") ?: ""

        if (nowVisible && nowTitle.isNotEmpty()) {
            views.setViewVisibility(R.id.widget_now_block, View.VISIBLE)
            views.setViewVisibility(R.id.widget_events_empty, View.GONE)
            views.setTextViewText(R.id.widget_now_time, nowTime)
            views.setTextViewText(R.id.widget_now_title, nowTitle)
        } else {
            views.setViewVisibility(R.id.widget_now_block, View.GONE)
            if (eventsEmpty.isNotEmpty()) {
                views.setViewVisibility(R.id.widget_events_empty, View.VISIBLE)
                views.setTextViewText(R.id.widget_events_empty, eventsEmpty)
            } else {
                views.setViewVisibility(R.id.widget_events_empty, View.GONE)
            }
        }

        bindNextLine(views, R.id.widget_next0, widgetData.getString("dw_next0", ""))
        bindNextLine(views, R.id.widget_next1, widgetData.getString("dw_next1", ""))

        views.setTextViewText(
            R.id.widget_tasks_section,
            widgetData.getString("dw_tasks_section", "") ?: "",
        )
        bindTaskLine(context, views, R.id.widget_task0, widgetData.getString("dw_task0", ""))
        bindTaskLine(context, views, R.id.widget_task1, widgetData.getString("dw_task1", ""))
        bindTaskLine(context, views, R.id.widget_task2, widgetData.getString("dw_task2", ""))

        views.setTextViewText(
            R.id.widget_footer,
            widgetData.getString("dw_footer", "") ?: "",
        )

        val launchIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
        )
        views.setOnClickPendingIntent(R.id.widget_root, launchIntent)
    }

    private fun bindNextLine(views: RemoteViews, viewId: Int, raw: String?) {
        if (raw.isNullOrBlank()) {
            views.setViewVisibility(viewId, View.GONE)
            return
        }
        val parts = raw.split('\t', limit = 2)
        val label = if (parts.size == 2) "${parts[0]}  ${parts[1]}" else raw
        views.setViewVisibility(viewId, View.VISIBLE)
        views.setTextViewText(viewId, label)
    }

    private fun bindTaskLine(
        context: Context,
        views: RemoteViews,
        viewId: Int,
        raw: String?,
    ) {
        if (raw.isNullOrBlank()) {
            views.setViewVisibility(viewId, View.GONE)
            return
        }
        val parts = raw.split('\t', limit = 3)
        if (parts.size < 3) {
            views.setViewVisibility(viewId, View.GONE)
            return
        }
        val done = parts[1] == "1"
        val prefix = if (done) {
            context.getString(R.string.widget_task_done_prefix)
        } else {
            context.getString(R.string.widget_task_todo_prefix)
        }
        views.setViewVisibility(viewId, View.VISIBLE)
        views.setTextViewText(viewId, prefix + parts[2])
    }
}
