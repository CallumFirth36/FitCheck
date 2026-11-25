import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:fitcheck/models/weather_info.dart';
import 'package:fitcheck/services/location_service.dart';


final weatherService = WeatherService();

// gets users location then asks open-meteo
class WeatherService {
  final LocationService _locationService = LocationService();

 
  static const Duration cacheLifetime = Duration(minutes: 10);
  WeatherInfo? _cached;
  DateTime? _cachedAt;

  Future<WeatherInfo> getCurrentWeather({bool forceRefresh = false}) async {
    final cached = _cached;
    final cachedAt = _cachedAt;
    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < cacheLifetime) {
      return cached;
    }

    // get gps location
    final location = await _locationService.getLocation();

    // build request
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

    // send request
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Weather request failed (${response.statusCode})');
    }

    // convert json to usable info
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final info =
        WeatherInfo.fromJson(json, usedDefaultLocation: location.isDefault);

    _cached = info;
    _cachedAt = DateTime.now();
    return info;
  }
}