class WeatherModel {
  final String cityName;
  final double temperature;
  final String mainCondition;
  final String iconCode;
  final String? time;
  final int humidity; // <--- THÊM CÁI NÀY

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.iconCode,
    this.time,
    required this.humidity, // <--- THÊM CÁI NÀY
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'] ?? '',
      temperature: (json['main']['temp'] as num).toDouble(),
      mainCondition: json['weather'][0]['main'] ?? '',
      iconCode: json['weather'][0]['icon'] ?? '01d',
      time: json['dt_txt'],
      humidity: json['main']['humidity'] ?? 0, // <--- LẤY TỪ JSON
    );
  }
}