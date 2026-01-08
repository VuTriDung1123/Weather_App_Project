import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Thư viện bản đồ
import 'package:latlong2/latlong.dart'; // Thư viện xử lý toạ độ

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Mặc định hiển thị Việt Nam (Lat: 16, Long: 106)
  LatLng _selectedLocation = const LatLng(16.0, 106.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chọn vị trí"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Khi bấm tick V, trả toạ độ về màn hình trước
              Navigator.pop(context, _selectedLocation);
            },
          )
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _selectedLocation, // Tâm bản đồ ban đầu
          initialZoom: 5.0, // Độ phóng to
          onTap: (tapPosition, point) {
            // Khi chạm vào bản đồ -> Cập nhật vị trí ghim
            setState(() {
              _selectedLocation = point;
            });
          },
        ),
        children: [
          // Lớp hiển thị hình ảnh bản đồ (Dùng OpenStreetMap miễn phí)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.weather_app',
          ),
          // Lớp hiển thị cái đinh ghim đỏ
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedLocation,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}