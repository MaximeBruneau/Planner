package com.vibecalendar.my_dairy

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class DuoVibeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val partnerName = widgetData.getString("partner_name", null) ?: "Partenaire"
                val partnerEmoji = widgetData.getString("partner_emoji", null) ?: ""
                val isPaired = widgetData.getBoolean("is_paired", false)
                val duoStreak = widgetData.getInt("duo_streak", 0)

                // Header title
                setTextViewText(R.id.widget_title, "$partnerName's Vibe 🌸")

                if (!isPaired) {
                    // Unpaired State
                    setTextViewText(R.id.widget_emoji, "🐰")
                    setTextViewText(R.id.widget_status, "Connecte ton duo dans l'app")
                    setViewVisibility(R.id.widget_streak, View.GONE)
                } else if (partnerEmoji.isNotEmpty()) {
                    // Logged today
                    setTextViewText(R.id.widget_emoji, partnerEmoji)
                    setTextViewText(R.id.widget_status, "Humeur du jour ✨")
                    if (duoStreak > 0) {
                        setViewVisibility(R.id.widget_streak, View.VISIBLE)
                        setTextViewText(R.id.widget_streak, "🔥🔥 $duoStreak")
                    } else {
                        setViewVisibility(R.id.widget_streak, View.GONE)
                    }
                } else {
                    // Not filled yet today!
                    setTextViewText(R.id.widget_emoji, "😴")
                    setTextViewText(R.id.widget_status, "Pas encore rempli aujourd'hui 🌸")
                    setViewVisibility(R.id.widget_streak, View.GONE)
                }

                // Tap opens app
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
