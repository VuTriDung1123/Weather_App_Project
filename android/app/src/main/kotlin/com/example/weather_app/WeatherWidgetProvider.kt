package com.example.weather_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

// Sửa: Kế thừa AppWidgetProvider (của Android) thay vì HomeWidgetProvider
class WeatherWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_weather).apply {
                // Cách lấy dữ liệu chuẩn từ Plugin
                val widgetData = HomeWidgetPlugin.getData(context)

                val city = widgetData.getString("city", "No Data")
                val temp = widgetData.getString("temp", "--")
                val status = widgetData.getString("status", "Open App")

                // Gán dữ liệu vào giao diện
                setTextViewText(R.id.tv_city, city)
                setTextViewText(R.id.tv_temp, temp)
                setTextViewText(R.id.tv_status, status)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}