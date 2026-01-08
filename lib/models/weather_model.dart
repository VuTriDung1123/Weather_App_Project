class WeatherModel {
  final String cityName;
  final double temperature;
  final String mainCondition;
  final String iconCode;
  final String? time;
  final int humidity;
  final double windSpeed; // Tốc độ gió (m/s)
  final int windDeg;      // Hướng gió (độ, từ 0-360)

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.iconCode,
    this.time,
    required this.humidity,
    required this.windSpeed, // <--- MỚI
    required this.windDeg,   // <--- MỚI
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'] ?? '',
      temperature: (json['main']['temp'] as num).toDouble(),
      mainCondition: json['weather'][0]['main'] ?? '',
      iconCode: json['weather'][0]['icon'] ?? '01d',
      time: json['dt_txt'],
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']['speed'] as num).toDouble(), // <--- Lấy từ API
      windDeg: json['wind']['deg'] ?? 0,                    // <--- Lấy từ API
    );
  }
}