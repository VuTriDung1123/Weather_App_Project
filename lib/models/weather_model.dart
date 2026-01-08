class WeatherModel {
  final String cityName;
  final double temperature;
  final String mainCondition;
  final String iconCode;
  final String? time; // Mới thêm: Để lưu ngày giờ dự báo

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.iconCode,
    this.time,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'] ?? '',
      temperature: (json['main']['temp'] as num).toDouble(),
      mainCondition: json['weather'][0]['main'] ?? '',
      iconCode: json['weather'][0]['icon'] ?? '10d',
      time: json['dt_txt'], // Lấy thời gian nếu có
    );
  }
}