// current weather info
class WeatherInfo {
  static const int rainLikelyThreshold = 40;

  final double temperature; // °C
  final double feelsLike; // °C "feels like"
  final double windSpeed; // km/h
  final double precipitation; // mm of rain falling right now
  final int rainChance;
  final int weatherCode;
  final bool usedDefaultLocation; // if cant get GPS location

  const WeatherInfo({
    required this.temperature,
    required this.feelsLike,
    required this.windSpeed,
    required this.precipitation,
    required this.rainChance,
    required this.weatherCode,
    required this.usedDefaultLocation,
  });

  // Build weatehr info form Open-Meteo
  factory WeatherInfo.fromJson(
    Map<String, dynamic> json, {
    required bool usedDefaultLocation,
  }) {
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;

    final chances = daily['precipitation_probability_max'] as List?;
    final firstChance =
        (chances != null && chances.isNotEmpty) ? chances.first as num? : null;

    return WeatherInfo(
      temperature: (current['temperature_2m'] as num).toDouble(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      precipitation: (current['precipitation'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
      rainChance: firstChance?.toInt() ?? 0,
      usedDefaultLocation: usedDefaultLocation,
    );
  }

  bool get rainLikely =>
      precipitation > 0 || rainChance >= rainLikelyThreshold;


  String get description => switch (weatherCode) {
        0 => 'Clear sky',
        1 => 'Mostly clear',
        2 => 'Partly cloudy',
        3 => 'Overcast',
        45 || 48 => 'Fog',
        51 || 53 || 55 => 'Drizzle',
        56 || 57 => 'Freezing drizzle',
        61 || 63 || 65 => 'Rain',
        66 || 67 => 'Freezing rain',
        71 || 73 || 75 || 77 => 'Snow',
        80 || 81 || 82 => 'Rain showers',
        85 || 86 => 'Snow showers',
        95 || 96 || 99 => 'Thunderstorm',
        _ => 'Unknown',
      };
}