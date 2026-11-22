// A snapshot of today's weather at the user's location.
// Like ClothingItem, this is a "model": one class that describes the data,
// so the home page and the outfit logic both use the same fields.
class WeatherInfo {
  // A rain chance at or above this (in %) counts as "rain likely".
  // The outfit logic will use it to decide whether to pick waterproof items.
  static const int rainLikelyThreshold = 40;

  final double temperature;   // °C right now
  final double feelsLike;     // °C "feels like" (includes wind chill)
  final double windSpeed;     // km/h
  final double precipitation; // mm of rain falling right now
  final int rainChance;       // 0 to 100 %, highest chance today
  final int weatherCode;      // WMO weather code (see description below)
  final bool usedDefaultLocation; // true if GPS wasn't available

  const WeatherInfo({
    required this.temperature,
    required this.feelsLike,
    required this.windSpeed,
    required this.precipitation,
    required this.rainChance,
    required this.weatherCode,
    required this.usedDefaultLocation,
  });

  // Builds a WeatherInfo from the JSON Open-Meteo sends back.
  // The JSON looks like:
  //   { "current": { "temperature_2m": 8.4, "wind_speed_10m": 12.1, ... },
  //     "daily":   { "precipitation_probability_max": [35], ... } }
  factory WeatherInfo.fromJson(
    Map<String, dynamic> json, {
    required bool usedDefaultLocation,
  }) {
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;

    // "daily" values come as lists with one entry per day. We asked for
    // one day, so we want the first entry (if there is one).
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

  // True if it's raining now, or rain is reasonably likely today
  bool get rainLikely =>
      precipitation > 0 || rainChance >= rainLikelyThreshold;

  // Plain-English text for the WMO weather code Open-Meteo sends
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