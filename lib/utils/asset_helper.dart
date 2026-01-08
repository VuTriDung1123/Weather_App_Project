class AssetHelper {
  static String getLocalIconPath(String iconCode) {
    // iconCode ví dụ: '01d' (ngày), '01n' (đêm)

    switch (iconCode) {
      case '01d': // Trời quang (Ngày)
        return 'assets/icons/sun.png';
      case '01n': // Trời quang (Đêm)
        return 'assets/icons/crescent-moon.png';

      case '02d': // Ít mây (Ngày)
        return 'assets/icons/cloudy.png';
      case '02n': // Ít mây (Đêm) -> Dùng tạm mây hoặc trăng nếu bạn có icon mây đêm
        return 'assets/icons/cloudy.png';

      case '03d': case '03n': // Mây rải rác
      case '04d': case '04n': // Nhiều mây
      case '50d': case '50n': // Sương mù
      return 'assets/icons/overcast.png';

      case '09d': case '09n': // Mưa rào
      return 'assets/icons/rainy-day.png'; // Tên file bạn gửi

      case '10d': case '10n': // Mưa thường
      return 'assets/icons/cloudy_and_rain.png'; // Tên file bạn gửi

      case '11d': case '11n': // Dông
      return 'assets/icons/storm.png';

      case '13d': case '13n': // Tuyết
      return 'assets/icons/snow.png';

      default:
        return 'assets/icons/sun.png';
    }
  }

  static String? getThermometerIcon(double temperature) {
    if (temperature >= 35) {
      return 'assets/icons/hot.png';
    } else if (temperature <= 18) { // Chỉnh lại 18 độ cho dễ hiện icon lạnh
      return 'assets/icons/cold.png';
    } else {
      return null;
    }
  }
}