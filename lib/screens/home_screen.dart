import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _weatherService = WeatherService();

  // Dữ liệu thời tiết
  List<WeatherModel> _allDays = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // BIẾN QUAN TRỌNG: Kiểm soát xem đang ở View 1 hay View 2
  // false = Xem View 1 ngày (Hôm nay)
  // true  = Xem View List (Dự báo nhiều ngày)
  bool _showForecastView = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final current = await _weatherService.getWeather();
      final forecast = await _weatherService.getForecast();

      final currentWithTime = WeatherModel(
        cityName: current.cityName,
        temperature: current.temperature,
        mainCondition: current.mainCondition,
        iconCode: current.iconCode,
        time: DateTime.now().toString(),
      );

      setState(() {
        _allDays = [currentWithTime, ...forecast];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Không tải được dữ liệu.\nKiểm tra kết nối hoặc API Key.";
      });
    }
  }

  LinearGradient _getBackgroundGradient(String? condition) {
    List<Color> colors;
    switch (condition?.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        colors = [const Color(0xFF546E7A), const Color(0xFF263238)];
        break;
      case 'rain':
      case 'drizzle':
      case 'shower rain':
      case 'thunderstorm':
        colors = [const Color(0xFF424242), const Color(0xFF212121)];
        break;
      case 'clear':
        colors = [const Color(0xFF29B6F6), const Color(0xFF0277BD)];
        break;
      default:
        colors = [const Color(0xFF4FC3F7), const Color(0xFF0288D1)];
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  @override
  Widget build(BuildContext context) {
    String condition = _allDays.isNotEmpty ? _allDays[0].mainCondition : 'clear';
    String cityName = _allDays.isNotEmpty ? _allDays[0].cityName : 'Loading...';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: _getBackgroundGradient(condition)),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.white)))
              : Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header luôn hiển thị
                _buildHeader(cityName),
                const SizedBox(height: 30),

                // 2. Logic chuyển đổi View
                Expanded(
                  child: _showForecastView
                      ? _buildForecastView() // Nếu true -> Hiện List
                      : _buildTodayView(),   // Nếu false -> Hiện 1 ngày
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String cityName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text("Location", style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Text(cityName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.settings, color: Colors.white))
      ],
    );
  }

  // --- VIEW 1: XEM 1 NGÀY (TODAY) ---
  Widget _buildTodayView() {
    final today = _allDays[0];
    DateTime date = DateTime.parse(today.time!);
    String formattedDate = DateFormat('EEEE, d MMMM').format(date);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Ảnh to đùng
        Image.network(
          'https://openweathermap.org/img/wn/${today.iconCode}@4x.png',
          scale: 0.5,
        ),
        // Nhiệt độ to
        Text(
          '${today.temperature.round()}°',
          style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          today.mainCondition,
          style: const TextStyle(fontSize: 24, color: Colors.white70),
        ),
        const SizedBox(height: 10),
        Text(
          formattedDate,
          style: const TextStyle(color: Colors.white60, fontSize: 16),
        ),

        const Spacer(), // Đẩy nút xuống dưới cùng

        // Nút chuyển sang View Forecast
        GestureDetector(
          onTap: () {
            setState(() {
              _showForecastView = true; // Bấm vào thì chuyển sang View 2
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))]
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Forecast report",
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(width: 10),
                Icon(Icons.arrow_upward, color: Colors.blue),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- VIEW 2: XEM LIST (FORECAST) ---
  Widget _buildForecastView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nút Back nhỏ để quay về View 1
        GestureDetector(
          onTap: () {
            setState(() {
              _showForecastView = false; // Quay về View 1
            });
          },
          child: const Row(
            children: [
              Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
              SizedBox(width: 5),
              Text("Back to Today", style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          "Next Forecast",
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // Danh sách cuộn
        Expanded(
          child: ListView.builder(
            itemCount: _allDays.length, // Hiện cả hôm nay và các ngày sau
            itemBuilder: (context, index) {
              final day = _allDays[index];
              DateTime date = DateTime.parse(day.time!);
              String dayName = index == 0 ? "Today" : DateFormat('EEEE').format(date);
              String shortDate = DateFormat('dd/MM').format(date);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1), // Trong suốt
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(shortDate, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    Image.network(
                      'https://openweathermap.org/img/wn/${day.iconCode}.png',
                      width: 40,
                    ),
                    Text(
                      '${day.temperature.round()}°',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}