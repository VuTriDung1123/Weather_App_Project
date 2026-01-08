import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Thư viện xử lý ngày tháng
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _weatherService = WeatherService();
  WeatherModel? _currentWeather;
  List<WeatherModel> _forecast = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Gọi song song cả 2 API cho nhanh
      final current = await _weatherService.getWeather();
      final forecast = await _weatherService.getForecast();

      setState(() {
        _currentWeather = current;
        _forecast = forecast;
        _isLoading = false;
      });
    } catch (e) {
      //print(e);
      setState(() { _isLoading = false; });
    }
  }

  // Hàm chọn màu nền dựa trên thời tiết (Điểm cộng UI!)
  LinearGradient _getBackgroundGradient(String? condition) {
    List<Color> colors;
    switch (condition?.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        colors = [Colors.blueGrey.shade400, Colors.blueGrey.shade900]; // Mây mù
        break;
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        colors = [Colors.grey.shade700, Colors.black87]; // Mưa
        break;
      case 'thunderstorm':
        colors = [Colors.deepPurple.shade900, Colors.black]; // Bão
        break;
      case 'clear':
        colors = [Colors.orange.shade400, Colors.orangeAccent.shade700]; // Nắng
        break;
      default:
        colors = [Colors.blue.shade400, Colors.blue.shade900]; // Mặc định
    }
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _getBackgroundGradient(_currentWeather?.mainCondition),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
          children: [
            // PHẦN 1: THỜI TIẾT HIỆN TẠI (Chiếm 60% màn hình)
            Expanded(
              flex: 6,
              child: SingleChildScrollView( // <--- THÊM CÁI NÀY
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Thêm khoảng cách an toàn ở trên để không sát mép quá
                    const SizedBox(height: 30),

                    Text(
                      _currentWeather?.cityName ?? "Đang định vị...",
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      DateFormat('EEEE, d MMMM').format(DateTime.now()),
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 20),

                    if (_currentWeather != null)
                      Image.network(
                        'https://openweathermap.org/img/wn/${_currentWeather!.iconCode}@4x.png',
                        scale: 0.8,
                      ),

                    Text(
                      '${_currentWeather?.temperature.round()}°',
                      style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      _currentWeather?.mainCondition ?? "",
                      style: const TextStyle(fontSize: 24, color: Colors.white70),
                    ),

                    // Thêm khoảng cách an toàn ở dưới
                    const SizedBox(height: 30),
                  ],
                ),
              ), // <--- ĐÓNG NGOẶC SingleChildScrollView
            ),

            // PHẦN 2: DỰ BÁO 5 NGÀY (Chiếm 40% màn hình)
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.black26, // Nền mờ cho phần dưới
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Forecast Next 5 Days", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _forecast.length,
                        itemBuilder: (context, index) {
                          final day = _forecast[index];
                          // Parse ngày tháng từ String
                          DateTime date = DateTime.parse(day.time!);
                          String dayName = DateFormat('EEEE').format(date); // Lấy tên thứ (Monday...)

                          return Card(
                            color: Colors.white.withValues(alpha: 0.1), // Hiệu ứng kính (Glassmorphism)
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              leading: Image.network(
                                'https://openweathermap.org/img/wn/${day.iconCode}.png',
                                width: 40,
                              ),
                              title: Text(dayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(day.mainCondition, style: const TextStyle(color: Colors.white70)),
                              trailing: Text(
                                  '${day.temperature.round()}°C',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white.withValues(alpha: 0.3),
        onPressed: _loadData,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}