import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/weather_model.dart';
import '../services/storage_service.dart';
import '../services/weather_service.dart';
import '../utils/asset_helper.dart';
import 'map_screen.dart';

class LocationListScreen extends StatefulWidget {
  const LocationListScreen({super.key});

  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  final _storageService = StorageService();
  final _weatherService = WeatherService();
  List<SavedLocation> _locations = [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final list = await _storageService.getSavedLocations();
    setState(() {
      _locations = list;
    });
  }

  // Hàm thêm địa điểm từ bản đồ
  Future<void> _addLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );

    if (result != null && result is LatLng) {
      // Gọi API một lần để lấy tên thành phố chuẩn
      try {
        final weather = await _weatherService.getWeather(lat: result.latitude, lon: result.longitude);
        final newLoc = SavedLocation(name: weather.cityName, lat: result.latitude, lon: result.longitude);
        await _storageService.addLocation(newLoc);
        _loadLocations(); // Reload list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không thể lấy thông tin địa điểm này")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF263238),
      appBar: AppBar(
        title: const Text("Saved Locations"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _locations.isEmpty
          ? const Center(child: Text("Chưa có địa điểm nào.\nBấm + để thêm.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _locations.length,
        itemBuilder: (context, index) {
          final location = _locations[index];
          return Dismissible( // Cho phép vuốt để xóa
            key: Key(location.name),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) async {
              await _storageService.removeLocation(location.name);
              // Không cần setState vì Dismissible tự xóa UI, chỉ cần xóa data nền
            },
            child: _buildLocationItem(location),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLocation,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Widget hiển thị từng dòng (Sẽ gọi API lấy thời tiết)
  Widget _buildLocationItem(SavedLocation location) {
    return FutureBuilder<WeatherModel>(
      future: _weatherService.getWeather(lat: location.lat, lon: location.lon),
      builder: (context, snapshot) {
        // Dữ liệu mặc định khi đang load hoặc lỗi
        String temp = "--";
        String status = "Loading...";
        String iconPath = "assets/icons/sun.png"; // Mặc định
        String wind = "-";
        String humid = "-";

        if (snapshot.hasData) {
          final w = snapshot.data!;
          temp = "${w.temperature.round()}°";
          status = w.mainCondition;
          iconPath = AssetHelper.getLocalIconPath(w.iconCode);
          wind = "${w.windSpeed} m/s";
          humid = "${w.humidity}%";
        }

        return GestureDetector(
          onTap: () {
            // Khi bấm vào -> Trả về LatLng cho màn hình Home để hiển thị
            Navigator.pop(context, LatLng(location.lat, location.lon));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Cột 1: Tên và Trạng thái
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(location.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(status, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      // Chi tiết nhỏ: Gió & Độ ẩm
                      Row(
                        children: [
                          Icon(Icons.air, color: Colors.white54, size: 14),
                          const SizedBox(width: 4),
                          Text(wind, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(width: 10),
                          Icon(Icons.water_drop, color: Colors.white54, size: 14),
                          const SizedBox(width: 4),
                          Text(humid, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                ),
                // Cột 2: Nhiệt độ và Icon
                Column(
                  children: [
                    Image.asset(iconPath, width: 50, height: 50),
                    Text(temp, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}