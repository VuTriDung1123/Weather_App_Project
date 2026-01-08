import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  String apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';

  Future<WeatherModel> getWeather({double? lat, double? lon}) async {
    Position? position;
    if (lat == null || lon == null) position = await _determinePosition();
    final latitude = lat ?? position!.latitude;
    final longitude = lon ?? position!.longitude;

    final url = 'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Lỗi tải thời tiết hiện tại');
    }
  }

  Future<List<WeatherModel>> getForecast({double? lat, double? lon}) async {
    Position? position;
    if (lat == null || lon == null) position = await _determinePosition();
    final latitude = lat ?? position!.latitude;
    final longitude = lon ?? position!.longitude;

    final url = 'https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> list = data['list'];

      // SỬA Ở ĐÂY: Map đầy đủ thông tin bao gồm cả GIÓ (wind)
      return list.map((item) => WeatherModel(
        cityName: '',
        temperature: (item['main']['temp'] as num).toDouble(),
        mainCondition: item['weather'][0]['main'],
        iconCode: item['weather'][0]['icon'],
        time: item['dt_txt'],
        humidity: item['main']['humidity'],

        // --- THÊM 2 DÒNG NÀY ĐỂ HẾT LỖI ---
        windSpeed: (item['wind']['speed'] as num).toDouble(),
        windDeg: item['wind']['deg'] ?? 0,
        // ---------------------------------

      )).toList();
    } else {
      throw Exception('Lỗi tải dự báo');
    }
  }

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