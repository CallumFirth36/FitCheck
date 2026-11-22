import 'package:flutter/material.dart';
import 'package:fitcheck/core/app_colours.dart';
import 'package:fitcheck/models/clothing_item.dart';
import 'package:fitcheck/models/outfit.dart';
import 'package:fitcheck/models/weather_info.dart';
import 'package:fitcheck/services/outfit_service.dart';
import 'package:fitcheck/services/wardrobe_service.dart';
import 'package:fitcheck/services/weather_service.dart';
import 'package:fitcheck/widgets/clothing_item_card.dart';
import 'package:fitcheck/widgets/gradient_background.dart';

// Shows today's suggested outfit, built from the weather and your wardrobe.
class OutfitPage extends StatefulWidget {
  const OutfitPage({super.key});

  @override
  State<OutfitPage> createState() => _OutfitPageState();
}

class _OutfitPageState extends State<OutfitPage> {
  WeatherInfo? _weather;
  List<ClothingItem> _wardrobe = [];
  Outfit? _outfit;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(); // start loading as soon as the page opens
  }

  // Fetches the weather and the wardrobe, then builds the first outfit.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Both requests run at the same time, and .wait waits for both.
      // watchItems().first takes just the first batch from the live stream.
      final (weather, wardrobe) = await (
        weatherService.getCurrentWeather(),
        wardrobeService.watchItems().first,
      ).wait;

      if (!mounted) return;
      setState(() {
        _weather = weather;
        _wardrobe = wardrobe;
        _outfit = outfitService.generate(wardrobe: wardrobe, weather: weather);
        _loading = false;
      });
    } catch (e) {
      print(e);
      if (!mounted) return;
      setState(() {
        _error = "Couldn't load the weather or your wardrobe.";
        _loading = false;
      });
    }
  }

  // "Try another": runs the logic again on the same data. The logic picks
  // randomly among equally good items, so this usually gives a new outfit.
  void _shuffle() {
    final weather = _weather;
    if (weather == null) return;
    setState(() {
      _outfit = outfitService.generate(wardrobe: _wardrobe, weather: weather);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Today's Outfit",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textOnDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textOnDark),
      ),
      body: GradientBackground(
        child: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    // 1. Loading
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Checking the weather...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    // 2. Something failed
    if (_error != null) {
      return _Message(
        icon: Icons.error_outline,
        title: _error!,
        subtitle: 'Check your connection and try again.',
        action: ElevatedButton(
          onPressed: _load,
          child: const Text('Try again'),
        ),
      );
    }

    // 3. Nothing to build an outfit from
    if (_wardrobe.isEmpty) {
      return const _Message(
        icon: Icons.checkroom,
        title: 'Your wardrobe is empty',
        subtitle: 'Add some clothes first, then come back for an outfit.',
      );
    }

    // 4. The outfit
    final outfit = _outfit!;
    final weather = _weather!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 24),
      children: [
        _WeatherSummary(weather: weather),
        const SizedBox(height: 20),

        const _Heading('Your outfit'),
        const SizedBox(height: 12),
        if (outfit.isEmpty)
          const Text(
            "No outfit could be built from your current items.",
            style: TextStyle(color: Colors.white70),
          )
        else
          for (final item in outfit.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClothingItemCard(item: item),
            ),

        const SizedBox(height: 8),
        const _Heading('Why this outfit'),
        const SizedBox(height: 8),
        for (final note in outfit.notes) _NoteRow(text: note),

        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: 250,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _shuffle,
              icon: const Icon(Icons.shuffle),
              label: const Text('Try another', style: TextStyle(fontSize: 18)),
            ),
          ),
        ),
      ],
    );
  }
}

// A section title, e.g. "Your outfit"
class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textOnDark,
      ),
    );
  }
}

// The short weather summary at the top of the page
class _WeatherSummary extends StatelessWidget {
  const _WeatherSummary({required this.weather});

  final WeatherInfo weather;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${weather.description} · ${weather.temperature.round()}°C',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Feels like ${weather.feelsLike.round()}°C · '
            '${weather.rainChance}% chance of rain · '
            '${weather.windSpeed.round()} km/h wind',
            style: const TextStyle(color: Colors.white70),
          ),
          if (weather.usedDefaultLocation)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Using a default location',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

// One explanation line with a small icon
class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}

// Centred icon + text (+ optional button), for the error and empty states
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}