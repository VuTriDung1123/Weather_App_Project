import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  // Đừng quên thay API KEY của bạn vào đây nhé!
  String apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';

  // Lấy thời tiết hiện tại
  Future<WeatherModel> getWeather() async {
    Position position = await _determinePosition();
    final url = 'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return WeatherModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Lỗi tải thời tiết hiện tại');
    }
  }

  // MỚI: Lấy dự báo 5 ngày (API trả về mỗi 3 giờ 1 lần -> Ta sẽ lọc lấy 1 cái mỗi ngày)
  Future<List<WeatherModel>> getForecast() async {
    Position position = await _determinePosition();
    final url = 'https://api.openweathermap.org/data/2.5/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> list = data['list'];

      // Lọc dữ liệu: Chỉ lấy các mốc giờ 12:00 trưa mỗi ngày để hiển thị cho gọn
      // (Vì API miễn phí trả về 40 điểm dữ liệu, ta không cần hết)
      List<WeatherModel> forecastList = [];
      for (var item in list) {
        String dateText = item['dt_txt']; // Dạng "2026-01-08 12:00:00"
        if (dateText.contains("12:00:00")) {
          forecastList.add(WeatherModel(
            cityName: '', // Không cần tên phố cho forecast
            temperature: (item['main']['temp'] as num).toDouble(),
            mainCondition: item['weather'][0]['main'],
            iconCode: item['weather'][0]['icon'],
            time: dateText, // Lưu thêm thời gian để hiển thị thứ/ngày
          ));
        }
      }
      return forecastList;
    } else {
      throw Exception('Lỗi tải dự báo');
    }
  }

  // Giữ nguyên hàm xin quyền GPS cũ
  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied');
    }
    if (permission == LocationPermission.deniedForever) return Future.error('Location permissions are permanently denied.');
    return await Geolocator.getCurrentPosition();
  }
}