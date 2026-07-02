package com.listriq.listriq_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class ListriQWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.listriq_widget_layout)

            val widgetData = HomeWidgetPlugin.getData(context)
            val dailyUsageStr = widgetData.getString("dailyUsage", "")
            val lastKWhStr = widgetData.getString("lastKWh", "")
            val lastCheckInMillisStr = widgetData.getString("lastCheckInMillis", "0")
            val days = widgetData.getString("days", "--")

            // Hitung estimasi real-time
            val now = System.currentTimeMillis()
            val lastCheckInMillis = lastCheckInMillisStr.toLongOrNull() ?: 0L
            val dailyUsage = dailyUsageStr.toDoubleOrNull() ?: -1.0
            val lastKWh = lastKWhStr.toDoubleOrNull() ?: -1.0

            val kwh: String
            if (dailyUsage > 0 && lastKWh >= 0 && lastCheckInMillis > 0) {
                val elapsedHours = (now - lastCheckInMillis) / (1000.0 * 60 * 60)
                val estimatedKWh = lastKWh - (dailyUsage * elapsedHours / 24.0)
                val displayKWh = maxOf(estimatedKWh, 0.0)
                kwh = String.format("%.1f kWh", displayKWh)
            } else {
                // Fallback ke snapshot statis
                val storedKwh = widgetData.getString("kwh", "--")
                kwh = if (storedKwh != null && storedKwh.isNotEmpty()) "${storedKwh} kWh" else "--"
            }

            views.setTextViewText(R.id.widget_kwh, kwh)
            views.setTextViewText(R.id.widget_days, days)

            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val pendingIntent = android.app.PendingIntent.getActivity(
                context, 0, intent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or
                    android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
