import 'package:flutter/material.dart';
import 'package:fitcheck/core/app_colours.dart';
import 'package:fitcheck/models/weather_info.dart';
import 'package:fitcheck/services/weather_service.dart';

// A self-contained card showing today's weather. Drop it anywhere with
// const WeatherCard(). It loads its own data and shows a spinner, the
// weather, or an error with a retry button.
class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  // Started once here, so rebuilding the card doesn't re-request the weather
  late Future<WeatherInfo> _future = weatherService.getCurrentWeather();

  // The retry button: fetch fresh weather, ignoring the saved result
  void _retry() {
    setState(() {
      _future = weatherService.getCurrentWeather(forceRefresh: true);
    });
  }

  // Picks an icon for the WMO weather code
  IconData _iconFor(int code) => switch (code) {
        0 || 1 => Icons.wb_sunny,
        2 || 3 => Icons.cloud,
        45 || 48 => Icons.cloud,
        51 || 53 || 55 || 56 || 57 => Icons.umbrella,
        61 || 63 || 65 || 66 || 67 => Icons.umbrella,
        80 || 81 || 82 => Icons.umbrella,
        71 || 73 || 75 || 77 || 85 || 86 => Icons.ac_unit,
        95 || 96 || 99 => Icons.thunderstorm,
        _ => Icons.help_outline,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // white at about 15% opacity, same as the wardrobe cards
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: FutureBuilder<WeatherInfo>(
        future: _future,
        builder: (context, snapshot) {
          // 1. Failed (no internet, timeout...)
          if (snapshot.hasError) {
            print(snapshot.error);
            return Row(
              children: [
                const Icon(Icons.cloud_off, color: Colors.white70),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Couldn't load the weather",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _retry,
                ),
              ],
            );
          }

          // 2. Still loading
          if (!snapshot.hasData) {
            return const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Checking the weather...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            );
          }

          // 3. Loaded
          final w = snapshot.data!;
          return Column(
            children: [
              Row(
                children: [
                  Icon(_iconFor(w.weatherCode),
                      size: 44, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${w.temperature.round()}°C · ${w.description}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textOnDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Feels like ${w.feelsLike.round()}°C',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(icon: Icons.water_drop, text: '${w.rainChance}% rain'),
                  _Stat(
                    icon: Icons.air,
                    text: '${w.windSpeed.round()} km/h wind',
                  ),
                ],
              ),
              // Shown only when GPS wasn't available
              if (w.usedDefaultLocation)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Using a default location',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// A small icon + text pair, e.g. "30% rain"
class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}