import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:fitcheck/models/weather_info.dart';
import 'package:fitcheck/services/location_service.dart';

// One shared instance, used anywhere with: weatherService.getCurrentWeather()
final weatherService = WeatherService();

// Gets the user's location, then asks Open-Meteo (a free weather API that
// needs no key) for today's weather there.
//
// Errors (no internet, bad response, timeout) are NOT caught here. They pass
// up to the page, which shows a message, the same approach as your other
// services.
class WeatherService {
  final LocationService _locationService = LocationService();

  // CHANGE: the last result is kept for 10 minutes, so the home card and the
  // outfit page share one GPS lookup and one web request instead of each
  // making their own.
  static const Duration cacheLifetime = Duration(minutes: 10);
  WeatherInfo? _cached;
  DateTime? _cachedAt;

  // forceRefresh: true skips the saved result and fetches fresh weather
  Future<WeatherInfo> getCurrentWeather({bool forceRefresh = false}) async {
    final cached = _cached;
    final cachedAt = _cachedAt;
    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < cacheLifetime) {
      return cached;
    }

    // 1. Where are we? (real GPS position, or the fallback city)
    final location = await _locationService.getLocation();

    // 2. Build the web address for the request. This produces something like:
    //    https://api.open-meteo.com/v1/forecast?latitude=51.5&longitude=-0.1
    //      &current=temperature_2m,...&daily=precipitation_probability_max...
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': location.latitude.toString(),
      'longitude': location.longitude.toString(),
      // "right now" values
      'current':
          'temperature_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m',
      // today's highest chance of rain
      'daily': 'precipitation_probability_max',
      'timezone': 'auto',
      'forecast_days': '1',
    });

    // 3. Send the request (give up after 10 seconds)
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Weather request failed (${response.statusCode})');
    }

    // 4. Turn the JSON text into a WeatherInfo, and remember it
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final info =
        WeatherInfo.fromJson(json, usedDefaultLocation: location.isDefault);

    _cached = info;
    _cachedAt = DateTime.now();
    return info;
  }
}