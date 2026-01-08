import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Model đơn giản để lưu địa điểm
class SavedLocation {
  final String name;
  final double lat;
  final double lon;

  SavedLocation({required this.name, required this.lat, required this.lon});

  // Chuyển sang dạng Map để lưu thành JSON string
  Map<String, dynamic> toJson() => {'name': name, 'lat': lat, 'lon': lon};

  // Tạo từ JSON map
  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(name: json['name'], lat: json['lat'], lon: json['lon']);
  }
}

class StorageService {
  static const String _keyLocations = 'saved_locations';

  // Lấy danh sách địa điểm đã lưu
  Future<List<SavedLocation>> getSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyLocations);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => SavedLocation.fromJson(e)).toList();
  }

  // Thêm một địa điểm mới
  Future<void> addLocation(SavedLocation location) async {
    final List<SavedLocation> currentList = await getSavedLocations();

    // Kiểm tra trùng lặp (nếu trùng tên thì không thêm)
    if (currentList.any((e) => e.name == location.name)) return;

    currentList.add(location);
    await _saveList(currentList);
  }

  // Xóa địa điểm
  Future<void> removeLocation(String name) async {
    final List<SavedLocation> currentList = await getSavedLocations();
    currentList.removeWhere((e) => e.name == name);
    await _saveList(currentList);
  }

  // Hàm phụ để lưu xuống đĩa
  Future<void> _saveList(List<SavedLocation> list) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_keyLocations, jsonString);
  }
}