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

  List<WeatherModel> _allDays = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // State quản lý hiển thị
  bool _showForecastView = false; // false = View Swipe, true = View List
  int _currentIndex = 0; // Lưu vị trí ngày đang xem (0 là hôm nay, 1 là mai...)

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
        _errorMessage = "Lỗi kết nối hoặc API Key.\nHãy thử lại.";
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
    // Lấy thông tin của ngày ĐANG ĐƯỢC CHỌN (theo _currentIndex) để đổi màu nền
    String condition = 'clear';
    String cityName = 'Loading...';

    if (_allDays.isNotEmpty && _currentIndex < _allDays.length) {
      condition = _allDays[_currentIndex].mainCondition;
      cityName = _allDays[0].cityName; // Tên phố luôn lấy từ thằng đầu tiên
    }

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
              children: [
                // 1. Header (Luôn hiển thị)
                _buildHeader(cityName),
                const SizedBox(height: 20),

                // 2. Nội dung chính (Chuyển đổi giữa Swipe và List)
                Expanded(
                  child: _showForecastView
                      ? _buildForecastListView() // View List
                      : _buildSwipeView(),       // View Swipe (1 ngày)
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

  // --- VIEW 1: SWIPE (VUỐT NGANG XEM TỪNG NGÀY) ---
  Widget _buildSwipeView() {
    // PageController với initialPage là _currentIndex
    // Giúp khi bấm từ List nhảy về đây sẽ mở đúng trang đó
    final PageController controller = PageController(initialPage: _currentIndex);

    return PageView.builder(
      controller: controller,
      itemCount: _allDays.length,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index; // Cập nhật chỉ số khi vuốt
        });
      },
      itemBuilder: (context, index) {
        return _buildSingleDayCard(_allDays[index]);
      },
    );
  }

  Widget _buildSingleDayCard(WeatherModel weather) {
    DateTime date = DateTime.parse(weather.time!);
    String formattedDate = DateFormat('EEEE, d MMMM').format(date);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Ảnh to
        Image.network(
          'https://openweathermap.org/img/wn/${weather.iconCode}@4x.png',
          scale: 0.5,
        ),
        // Nhiệt độ
        Text(
          '${weather.temperature.round()}°',
          style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        // Trạng thái
        Text(
          weather.mainCondition,
          style: const TextStyle(fontSize: 24, color: Colors.white70),
        ),
        const SizedBox(height: 10),
        // Ngày tháng
        Text(
          formattedDate,
          style: const TextStyle(color: Colors.white60, fontSize: 16),
        ),

        const Spacer(),

        // Nút chuyển sang View List
        GestureDetector(
          onTap: () {
            setState(() {
              _showForecastView = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))]
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

  // --- VIEW 2: LIST (DANH SÁCH 7 NGÀY) ---
  Widget _buildForecastListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nút Back
        GestureDetector(
          onTap: () {
            setState(() {
              _showForecastView = false; // Quay về View Swipe
              // Không reset _currentIndex để giữ nguyên ngày đang chọn
            });
          },
          child: const Row(
            children: [
              Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
              SizedBox(width: 5),
              Text("Back", style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          "Select a day",
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: ListView.builder(
            itemCount: _allDays.length,
            itemBuilder: (context, index) {
              final day = _allDays[index];
              DateTime date = DateTime.parse(day.time!);
              String dayName = index == 0 ? "Today" : DateFormat('EEEE').format(date);
              String shortDate = DateFormat('dd/MM').format(date);

              // Kiểm tra xem dòng này có đang được chọn không
              bool isSelected = index == _currentIndex;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = index; // 1. Lưu ngày được chọn
                    _showForecastView = false; // 2. Quay về View Swipe
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                    // Nếu đang chọn thì màu trắng sáng, không thì mờ
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
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
                            Text(
                                dayName,
                                style: TextStyle(
                                    color: isSelected ? Colors.blue : Colors.white, // Đổi màu chữ nếu chọn
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                )
                            ),
                            Text(
                                shortDate,
                                style: TextStyle(
                                    color: isSelected ? Colors.blue.withValues(alpha: 0.7) : Colors.white54,
                                    fontSize: 12
                                )
                            ),
                          ],
                        ),
                      ),
                      Image.network(
                        'https://openweathermap.org/img/wn/${day.iconCode}.png',
                        width: 40,
                        // Nếu đang chọn thì giữ màu gốc, không thì có thể làm mờ tí (ở đây giữ nguyên cho đẹp)
                      ),
                      Text(
                        '${day.temperature.round()}°',
                        style: TextStyle(
                            color: isSelected ? Colors.blue : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}