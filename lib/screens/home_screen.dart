import 'dart:async'; // Để chạy đồng hồ
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../utils/asset_helper.dart'; // File asset helper mới
import 'map_screen.dart';

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

  bool _showForecastView = false;
  int _currentIndex = 0;

  // Biến cho đồng hồ
  String _currentTimeStr = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startClock();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    // Định dạng giờ:phút:giây (VD: 19:30:45)
    final String formattedTime = DateFormat('HH:mm').format(now);
    setState(() {
      _currentTimeStr = formattedTime;
    });
  }

  Future<void> _loadData({double? lat, double? lon}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final current = await _weatherService.getWeather(lat: lat, lon: lon);
      final forecast = await _weatherService.getForecast(lat: lat, lon: lon);

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
        _showForecastView = false;
        _currentIndex = 0;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Lỗi kết nối hoặc API Key.";
      });
    }
  }

  // --- LOGIC MÀU NỀN TỰ ĐỘNG SÁNG/TỐI ---
  LinearGradient _getBackgroundGradient(String iconCode) {
    bool isNight = iconCode.contains('n'); // Kiểm tra xem có phải ban đêm không

    if (isNight) {
      // Màu nền cho BAN ĐÊM (Tối mịt)
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      );
    } else {
      // Màu nền cho BAN NGÀY (Sáng sủa)
      // Kiểm tra thêm mưa/nắng để đổi màu cho chuẩn
      if (iconCode.contains('09') || iconCode.contains('10') || iconCode.contains('11')) {
        return const LinearGradient( // Ngày mưa
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4B79A1), Color(0xFF283E51)],
        );
      } else {
        return const LinearGradient( // Ngày nắng đẹp
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2980B9), Color(0xFF6DD5FA)],
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy iconCode của ngày đang chọn để quyết định màu nền
    String currentIconCode = _allDays.isNotEmpty ? _allDays[_currentIndex].iconCode : '01d';
    String cityName = _allDays.isNotEmpty ? _allDays[0].cityName : 'Loading...';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: _getBackgroundGradient(currentIconCode)),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.white)))
              : Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildHeader(cityName),
                const SizedBox(height: 10),

                Expanded(
                  child: _showForecastView
                      ? _buildForecastListView()
                      : _buildSwipeView(),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text("Location", style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
              Text(
                cityName,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              tooltip: "Vị trí của tôi",
              onPressed: () => _loadData(),
              icon: const Icon(Icons.my_location, color: Colors.white, size: 28),
            ),
            IconButton(
              tooltip: "Mở bản đồ",
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                );
                if (result != null && result is LatLng) {
                  _loadData(lat: result.latitude, lon: result.longitude);
                }
              },
              icon: const Icon(Icons.map, color: Colors.white, size: 28),
            ),
          ],
        )
      ],
    );
  }

  // --- VIEW 1 NGÀY ---
  Widget _buildSwipeView() {
    final PageController controller = PageController(initialPage: _currentIndex);
    return PageView.builder(
      controller: controller,
      itemCount: _allDays.length,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
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

    // Lấy ảnh từ Helper
    String localIconPath = AssetHelper.getLocalIconPath(weather.iconCode);
    String? thermometerPath = AssetHelper.getThermometerIcon(weather.temperature);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. ĐỒNG HỒ
        Text(
          _currentTimeStr,
          style: const TextStyle(fontSize: 45, fontWeight: FontWeight.w300, color: Colors.white),
        ),
        Text(formattedDate, style: const TextStyle(color: Colors.white70, fontSize: 18)),

        const SizedBox(height: 20),

        // 2. ICON THỜI TIẾT (Ảnh của bạn)
        // Thêm bóng đổ cho ảnh nổi lên nền
        Container(
          decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
          ),
          child: Image.asset(localIconPath, height: 160),
        ),

        const SizedBox(height: 10),

        // 3. NHIỆT ĐỘ & NHIỆT KẾ
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (thermometerPath != null)
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Image.asset(thermometerPath, height: 70),
              ),
            Text(
              '${weather.temperature.round()}°',
              style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),

        Text(
          weather.mainCondition,
          style: const TextStyle(fontSize: 28, color: Colors.white70),
        ),

        const Spacer(),

        GestureDetector(
          onTap: () {
            setState(() { _showForecastView = true; });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Forecast report", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
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

  // --- VIEW LIST 7 NGÀY ---
  Widget _buildForecastListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () { setState(() { _showForecastView = false; }); },
          child: const Row(
            children: [
              Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
              SizedBox(width: 5),
              Text("Back", style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text("Select a day", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),

        Expanded(
          child: ListView.builder(
            itemCount: _allDays.length,
            itemBuilder: (context, index) {
              final day = _allDays[index];
              DateTime date = DateTime.parse(day.time!);
              String dayName = index == 0 ? "Today" : DateFormat('EEEE').format(date);
              String shortDate = DateFormat('dd/MM').format(date);
              bool isSelected = index == _currentIndex;

              // Lấy icon nhỏ cho list
              String iconPath = AssetHelper.getLocalIconPath(day.iconCode);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                    _showForecastView = false;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
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
                            Text(dayName, style: TextStyle(color: isSelected ? Colors.blue : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(shortDate, style: TextStyle(color: isSelected ? Colors.blue.withOpacity(0.7) : Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      // Dùng ảnh asset thay vì network
                      Image.asset(iconPath, width: 40),
                      Text('${day.temperature.round()}°', style: TextStyle(color: isSelected ? Colors.blue : Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
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