import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../utils/asset_helper.dart';
import '../utils/home_widget_utils.dart';
import 'location_list_screen.dart'; // Màn hình list mới
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _weatherService = WeatherService();

  List<WeatherModel> _dailyRepresentatives = [];
  Map<String, List<WeatherModel>> _hourlyData = {};

  bool _isLoading = true;
  String _errorMessage = '';
  bool _showForecastView = false;
  int _currentIndex = 0;
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
    final String formattedTime = DateFormat('HH:mm').format(now);
    setState(() => _currentTimeStr = formattedTime);
  }

  Future<void> _loadData({double? lat, double? lon}) async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final current = await _weatherService.getWeather(lat: lat, lon: lon);
      final rawForecast = await _weatherService.getForecast(lat: lat, lon: lon);
      _processData(current, rawForecast);
      setState(() { _isLoading = false; _showForecastView = false; _currentIndex = 0; });
      HomeWidgetUtils.updateWidget(current);
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = "Lỗi kết nối hoặc API Key."; });
    }
  }

  void _processData(WeatherModel current, List<WeatherModel> rawForecast) {
    _hourlyData.clear();
    _dailyRepresentatives.clear();
    String todayKey = DateTime.now().toString().substring(0, 10);
    Map<String, List<WeatherModel>> rawGrouped = {};

    // Thêm current (bao gồm cả gió)
    final currentModel = WeatherModel(
      cityName: current.cityName,
      temperature: current.temperature,
      mainCondition: current.mainCondition,
      iconCode: current.iconCode,
      time: DateTime.now().toString(),
      humidity: current.humidity,
      windSpeed: current.windSpeed, // <--- Gió
      windDeg: current.windDeg,     // <--- Hướng gió
    );
    rawGrouped[todayKey] = [currentModel];

    for (var item in rawForecast) {
      String dateKey = item.time!.substring(0, 10);
      if (!rawGrouped.containsKey(dateKey)) rawGrouped[dateKey] = [];
      rawGrouped[dateKey]!.add(item);
    }

    var sortedKeys = rawGrouped.keys.toList()..sort();
    for (var key in sortedKeys) {
      List<WeatherModel> rawList = rawGrouped[key]!;
      if (key != todayKey && rawList.length < 4) continue;
      _hourlyData[key] = _interpolateData(rawList);
      if (key == todayKey) {
        _dailyRepresentatives.add(currentModel);
      } else {
        var rep = _hourlyData[key]!.firstWhere((e) => e.time!.contains("12:00"), orElse: () => _hourlyData[key]![_hourlyData[key]!.length ~/ 2]);
        _dailyRepresentatives.add(rep);
      }
    }
  }

  List<WeatherModel> _interpolateData(List<WeatherModel> input) {
    if (input.isEmpty) return [];
    input.sort((a, b) => a.time!.compareTo(b.time!));
    List<WeatherModel> result = [];
    for (int i = 0; i < input.length - 1; i++) {
      WeatherModel start = input[i];
      WeatherModel end = input[i + 1];
      DateTime t1 = DateTime.parse(start.time!);
      DateTime t2 = DateTime.parse(end.time!);
      result.add(start);
      int hoursDiff = t2.difference(t1).inHours;
      for (int h = 1; h < hoursDiff; h++) {
        double fraction = h / hoursDiff;
        double newTemp = start.temperature + (end.temperature - start.temperature) * fraction;
        int newHumid = (start.humidity + (end.humidity - start.humidity) * fraction).round();
        double newWind = start.windSpeed + (end.windSpeed - start.windSpeed) * fraction; // Nội suy gió
        DateTime newTime = t1.add(Duration(hours: h));
        result.add(WeatherModel(
            cityName: start.cityName, temperature: newTemp, mainCondition: start.mainCondition, iconCode: start.iconCode,
            time: newTime.toString(), humidity: newHumid, windSpeed: newWind, windDeg: start.windDeg // Hướng gió giữ nguyên
        ));
      }
    }
    result.add(input.last);
    return result;
  }

  // Hàm chuyển đổi độ sang hướng chữ (Bắc, Đông, Nam, Tây)
  String _getWindDirection(int deg) {
    const directions = ['Bắc (N)', 'Đông Bắc (NE)', 'Đông (E)', 'Đông Nam (SE)', 'Nam (S)', 'Tây Nam (SW)', 'Tây (W)', 'Tây Bắc (NW)'];
    int index = ((deg + 22.5) % 360) ~/ 45; // Chia 45 độ 1 góc
    return directions[index];
  }

  LinearGradient _getBackgroundGradient(String iconCode) {
    bool isNight = iconCode.contains('n');
    if (isNight) return const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]);
    if (iconCode.contains('09') || iconCode.contains('10') || iconCode.contains('11')) return const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4B79A1), Color(0xFF283E51)]);
    return const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2980B9), Color(0xFF6DD5FA)]);
  }

  @override
  Widget build(BuildContext context) {
    String currentIconCode = _dailyRepresentatives.isNotEmpty ? _dailyRepresentatives[_currentIndex].iconCode : '01d';
    String cityName = _dailyRepresentatives.isNotEmpty ? _dailyRepresentatives[0].cityName : 'Loading...';

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
                Expanded(child: _showForecastView ? _buildForecastListView() : _buildSwipeView()),
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.location_on, color: Colors.white, size: 16), SizedBox(width: 4), Text("Location", style: TextStyle(color: Colors.white70, fontSize: 14))]),
            Text(cityName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ]),
        ),
        Row(
          children: [
            // Nút Menu mở danh sách địa điểm
            IconButton(
                tooltip: "Danh sách địa điểm",
                onPressed: () async {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationListScreen()));
                  if (result != null && result is LatLng) {
                    _loadData(lat: result.latitude, lon: result.longitude); // Load lại theo điểm chọn trong list
                  }
                },
                icon: const Icon(Icons.list, color: Colors.white, size: 30)
            ),
            IconButton(tooltip: "Vị trí của tôi", onPressed: () => _loadData(), icon: const Icon(Icons.my_location, color: Colors.white, size: 28)),
          ],
        )
      ],
    );
  }

  Widget _buildSwipeView() {
    final PageController controller = PageController(initialPage: _currentIndex);
    return PageView.builder(
      controller: controller,
      itemCount: _dailyRepresentatives.length,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      itemBuilder: (context, index) => _buildSingleDayCard(_dailyRepresentatives[index]),
    );
  }

  Widget _buildSingleDayCard(WeatherModel weather) {
    DateTime date = DateTime.parse(weather.time!);
    String formattedDate = DateFormat('EEEE, d MMMM').format(date);
    String localIconPath = AssetHelper.getLocalIconPath(weather.iconCode);
    String? thermometerPath = AssetHelper.getThermometerIcon(weather.temperature);
    List<WeatherModel> hours = _hourlyData[weather.time!.substring(0, 10)] ?? [];

    // Hướng gió
    String windDir = _getWindDirection(weather.windDeg);

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(_currentTimeStr, style: const TextStyle(fontSize: 45, fontWeight: FontWeight.w300, color: Colors.white)),
          Text(formattedDate, style: const TextStyle(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 20),
          Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]), child: Image.asset(localIconPath, height: 160)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (thermometerPath != null) Padding(padding: const EdgeInsets.only(right: 15), child: Image.asset(thermometerPath, height: 70)),
            Text('${weather.temperature.round()}°', style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold, color: Colors.white)),
          ]),
          Text(weather.mainCondition, style: const TextStyle(fontSize: 28, color: Colors.white70)),

          // --- HÀNG THÔNG TIN MỚI: ĐỘ ẨM & GIÓ ---
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Độ ẩm
              Row(children: [const Icon(Icons.water_drop, color: Colors.lightBlueAccent, size: 20), const SizedBox(width: 5), Text("${weather.humidity}%", style: const TextStyle(color: Colors.white70, fontSize: 16))]),
              const SizedBox(width: 25), // Khoảng cách
              // Gió
              Row(children: [const Icon(Icons.air, color: Colors.white70, size: 20), const SizedBox(width: 5), Text("${weather.windSpeed.toStringAsFixed(1)} m/s ($windDir)", style: const TextStyle(color: Colors.white70, fontSize: 16))]),
            ],
          ),

          const SizedBox(height: 40),
          Align(alignment: Alignment.centerLeft, child: Text("Hourly Forecast (24h)", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 10),
          SizedBox(height: 150, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: hours.length, itemBuilder: (context, index) {
            final h = hours[index];
            final timeDisplay = DateFormat('HH:mm').format(DateTime.parse(h.time!));
            return Container(width: 90, margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.1))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(timeDisplay, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 5),
              Image.asset(AssetHelper.getLocalIconPath(h.iconCode), width: 35),
              Text('${h.temperature.round()}°', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${h.windSpeed.round()} m/s', style: const TextStyle(color: Colors.grey, fontSize: 10)), // Gió trong list giờ
            ]));
          })),
          const SizedBox(height: 30),
          GestureDetector(onTap: () { setState(() { _showForecastView = true; }); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]), child: const Row(mainAxisSize: MainAxisSize.min, children: [Text("Forecast report", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)), SizedBox(width: 10), Icon(Icons.arrow_upward, color: Colors.blue)]))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildForecastListView() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(onTap: () { setState(() { _showForecastView = false; }); }, child: const Row(children: [Icon(Icons.arrow_back_ios, color: Colors.white, size: 18), SizedBox(width: 5), Text("Back", style: TextStyle(color: Colors.white70))])),
      const SizedBox(height: 20), const Text("Next 5 Days", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 20),
      Expanded(child: ListView.builder(itemCount: _dailyRepresentatives.length, itemBuilder: (context, index) {
        final day = _dailyRepresentatives[index];
        DateTime date = DateTime.parse(day.time!);
        String dayName = index == 0 ? "Today" : DateFormat('EEEE').format(date);
        String shortDate = DateFormat('dd/MM').format(date);
        bool isSelected = index == _currentIndex;
        return GestureDetector(onTap: () { setState(() { _currentIndex = index; _showForecastView = false; }); }, child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20), decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(15)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          SizedBox(width: 100, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(dayName, style: TextStyle(color: isSelected ? Colors.blue : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text(shortDate, style: TextStyle(color: isSelected ? Colors.blue.withOpacity(0.7) : Colors.white54, fontSize: 12))])),
          // Đầy đủ Gió + Độ ẩm trong List
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(children: [Icon(Icons.water_drop, size: 12, color: isSelected ? Colors.blue : Colors.white70), Text('${day.humidity}%', style: TextStyle(color: isSelected ? Colors.blue : Colors.white70, fontSize: 12))]),
            Row(children: [Icon(Icons.air, size: 12, color: isSelected ? Colors.blue : Colors.white70), Text('${day.windSpeed.round()}m/s', style: TextStyle(color: isSelected ? Colors.blue : Colors.white70, fontSize: 12))]),
          ]),
          Image.asset(AssetHelper.getLocalIconPath(day.iconCode), width: 40),
          Text('${day.temperature.round()}°', style: TextStyle(color: isSelected ? Colors.blue : Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        ])));
      })),
    ]);
  }
}