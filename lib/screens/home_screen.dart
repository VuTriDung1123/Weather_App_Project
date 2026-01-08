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

  // Danh sách chứa TẤT CẢ các ngày (Hôm nay + Dự báo)
  List<WeatherModel> _allDays = [];
  bool _isLoading = true;
  String _errorMessage = '';

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
      // 1. Lấy thời tiết hiện tại
      final current = await _weatherService.getWeather();
      // 2. Lấy dự báo 5 ngày
      final forecast = await _weatherService.getForecast();

      // 3. Gộp lại: Phần tử đầu là Hôm nay, các phần tử sau là dự báo
      // Sửa lại thuộc tính time cho 'current' để hiển thị đúng ngày
      final currentWithTime = WeatherModel(
        cityName: current.cityName,
        temperature: current.temperature,
        mainCondition: current.mainCondition,
        iconCode: current.iconCode,
        time: DateTime.now().toString(), // Gán thời gian hiện tại
      );

      setState(() {
        _allDays = [currentWithTime, ...forecast];
        _isLoading = false;
      });
    } catch (e) {
      print("Lỗi: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Không tải được dữ liệu.\nKiểm tra GPS hoặc API Key.";
      });
    }
  }

  // Hàm chọn màu nền (Giữ nguyên)
  LinearGradient _getBackgroundGradient(String? condition) {
    List<Color> colors;
    switch (condition?.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        colors = [Colors.blueGrey.shade400, Colors.blueGrey.shade900];
        break;
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        colors = [Colors.grey.shade700, Colors.black87];
        break;
      case 'thunderstorm':
        colors = [Colors.deepPurple.shade900, Colors.black];
        break;
      case 'clear':
        colors = [Colors.orange.shade400, Colors.orangeAccent.shade700];
        break;
      default:
        colors = [Colors.blue.shade400, Colors.blue.shade900];
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
      // Nếu chưa có dữ liệu thì dùng màu mặc định, có rồi thì dùng màu của ngày ĐẦU TIÊN trong list
      body: Container(
        decoration: BoxDecoration(
          gradient: _getBackgroundGradient(
              _allDays.isNotEmpty ? _allDays[0].mainCondition : 'clear'
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _errorMessage.isNotEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              ElevatedButton(onPressed: _loadData, child: const Text("Thử lại"))
            ],
          ),
        )
            : PageView.builder( // <--- CÁI NÀY LÀ CÁI BẠN CẦN: VUỐT NGANG
          itemCount: _allDays.length,
          itemBuilder: (context, index) {
            return _buildWeatherPage(_allDays[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildWeatherPage(WeatherModel weather, int index) {
    // Xử lý ngày hiển thị
    DateTime date = DateTime.parse(weather.time!);
    String dayTitle;
    if (index == 0) {
      dayTitle = "Hôm nay (Today)";
    } else if (index == 1) {
      dayTitle = "Ngày mai (Tomorrow)";
    } else {
      dayTitle = DateFormat('EEEE, d MMMM').format(date);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Tiêu đề ngày
        Text(
          dayTitle,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),

        // Tên thành phố (Chỉ hiện cho ngày hôm nay, các ngày sau ẩn đi hoặc hiện nhỏ cũng được)
        if (index == 0)
          Text(
            weather.cityName,
            style: const TextStyle(fontSize: 20, color: Colors.white70),
          ),

        const SizedBox(height: 40),

        // Icon
        Image.network(
          'https://openweathermap.org/img/wn/${weather.iconCode}@4x.png',
          scale: 0.6,
        ),

        // Nhiệt độ
        Text(
          '${weather.temperature.round()}°',
          style: const TextStyle(fontSize: 90, fontWeight: FontWeight.bold, color: Colors.white),
        ),

        // Trạng thái
        Text(
          weather.mainCondition,
          style: const TextStyle(fontSize: 30, color: Colors.white70, fontWeight: FontWeight.w300),
        ),

        const SizedBox(height: 50),

        // Chỉ dẫn vuốt
        if (index < _allDays.length - 1)
          const Column(
            children: [
              Text("Vuốt sang trái để xem ngày mai", style: TextStyle(color: Colors.white38, fontSize: 12)),
              Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
            ],
          ),
      ],
    );
  }
}