import 'package:home_widget/home_widget.dart';
import '../models/weather_model.dart';

class HomeWidgetUtils {
  static Future<void> updateWidget(WeatherModel weather) async {
    // 1. Lưu dữ liệu vào bộ nhớ chung (Shared Storage)
    await HomeWidget.saveWidgetData<String>('city', weather.cityName);
    await HomeWidget.saveWidgetData<String>('temp', '${weather.temperature.round()}°');
    await HomeWidget.saveWidgetData<String>('status', weather.mainCondition);

    // 2. Thông báo cho Widget cập nhật ngay lập tức
    await HomeWidget.updateWidget(
      name: 'WeatherWidgetProvider', // Phải trùng tên class Kotlin
      androidName: 'WeatherWidgetProvider',
    );
  }
}