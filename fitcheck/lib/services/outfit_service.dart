import 'dart:math';

import 'package:fitcheck/models/clothing_item.dart';
import 'package:fitcheck/models/outfit.dart';
import 'package:fitcheck/models/weather_info.dart';

final outfitService = OutfitService();

// Builds an outfit from the user's wardrobe and the current weather.
class OutfitService {
  /// Wind speed
  static const double windyThreshold = 30;

  // colours that go with everything.
  static const Set<String> _neutralColours = {
    'black', 'white', 'grey', 'navy', 'beige', 'brown',
  };

  // colours that pair well
  static const List<(String, String)> _goodPairs = [
    ('blue', 'orange'),
    ('blue', 'yellow'),
    ('blue', 'pink'),
    ('blue', 'green'),
    ('green', 'yellow'),
    ('purple', 'pink'),
    ('purple', 'yellow'),
  ];

  // maps temps to warmth level
  int targetWarmthFor(double feelsLike) {
    if (feelsLike >= 22) return 1;
    if (feelsLike >= 16) return 2;
    if (feelsLike >= 10) return 3;
    if (feelsLike >= 4) return 4;
    return 5;
  }

  // Returns an outfit 
  Outfit generate({
    required List<ClothingItem> wardrobe,
    required WeatherInfo weather,
    Random? random, // random for repeatable results
  }) {
    final rng = random ?? Random();
    final notes = <String>[];
    final rain = weather.rainLikely;

    // colour checks against previous item
    final picked = <ClothingItem>[];

    // chooses an item and stores it in picked
    ClothingItem? choose(
      ClothingCategory category,
      int target, {
      bool waterproof = false,
    }) {
      final item = _pick(wardrobe, category, target, waterproof, picked, rng);
      if (item != null) picked.add(item);
      return item;
    }

    // warmth
    final target = targetWarmthFor(weather.feelsLike);
    notes.add(
      'It feels like ${weather.feelsLike.round()}°C, so the outfit should be '
      'around warmth level $target out of ${ClothingItem.maxWarmth}.',
    );

    // outerlayer
    final windy = weather.windSpeed >= windyThreshold;
    final reasons = <String>[
      if (target >= 3) 'it is cool',
      if (rain) 'rain is likely',
      if (windy) 'it is windy',
    ];
    final needsOuterwear = reasons.isNotEmpty;
    final outerwear = needsOuterwear
        ? choose(ClothingCategory.outerwear, target, waterproof: rain)
        : null;

    if (needsOuterwear) {
      notes.add('An outer layer is recommended because ${reasons.join(' and ')}.');
      if (outerwear == null) {
        notes.add('You have no outerwear. Add a jacket or coat for days like this.');
      }
    }

    // midlayer
    final needsMidLayer = target >= 4 || (target >= 3 && outerwear == null);
    final midLayer = needsMidLayer
        ? choose(ClothingCategory.midLayer, outerwear != null ? target - 1 : target)
        : null;

    if (needsMidLayer) {
      if (midLayer != null) {
        notes.add('A mid layer was added for warmth.');
      } else {
        notes.add('You have no hoodies or jumpers to layer. Add one for colder days.');
      }
    }

    // top and bottom
    final layersOverTop =
        (outerwear != null ? 1 : 0) + (midLayer != null ? 1 : 0);
    final topTarget = max(ClothingItem.minWarmth, target - layersOverTop);
    final bottomTarget =
        max(ClothingItem.minWarmth, target - (outerwear != null ? 1 : 0));

    if (layersOverTop > 0) {
      notes.add('Layers are worn over the top, so it aims for warmth level $topTarget.');
    }

    final top = choose(ClothingCategory.top, topTarget);
    final bottom = choose(ClothingCategory.bottom, bottomTarget);
    final shoes = choose(ClothingCategory.shoes, target, waterproof: rain);

    // accessory
    final accessory =
        target >= 4 ? choose(ClothingCategory.accessory, target) : null;
    if (accessory != null) notes.add('It is cold, so an accessory was added.');

    // Rain advice.
    if (rain) {
      if (outerwear != null && outerwear.waterproof) {
        notes.add('Rain is likely, so a waterproof outer layer was chosen.');
      } else {
        notes.add('Rain is likely and you have no waterproof outer layer. Take an umbrella.');
      }
      if (shoes != null && !shoes.waterproof) {
        notes.add('Your shoes are not waterproof, so watch out for puddles.');
      }
    }

    // Slots the wardrobe could not fill.
    if (top == null) notes.add('You have no tops yet. Add some to complete the outfit.');
    if (bottom == null) notes.add('You have no bottoms yet. Add some to complete the outfit.');
    if (shoes == null) notes.add('You have no shoes yet. Add some to complete the outfit.');

    //  avoids colour clash
    String? clash;
    for (var i = 0; i < picked.length; i++) {
      for (var j = i + 1; j < picked.length; j++) {
        if (!_coloursMatch(picked[i].colour, picked[j].colour)) {
          clash = '${picked[i].name} and ${picked[j].name}';
        }
      }
    }
    if (clash != null) {
      notes.add('$clash may clash, but they were the best fit for the weather.');
    } else if (picked.length >= 2) {
      notes.add('The colours were chosen to go together.');
    }

    return Outfit(
      top: top,
      midLayer: midLayer,
      bottom: bottom,
      shoes: shoes,
      outerwear: outerwear,
      accessory: accessory,
      notes: notes,
    );
  }

  // picks the best-scoring item in a category
  ClothingItem? _pick(
    List<ClothingItem> wardrobe,
    ClothingCategory category,
    int targetWarmth,
    bool wantWaterproof,
    List<ClothingItem> picked,
    Random rng,
  ) {
    final candidates = wardrobe.where((i) => i.category == category).toList();
    if (candidates.isEmpty) return null;

    double score(ClothingItem item) {
      var s = -(item.warmth - targetWarmth).abs().toDouble();
      if (wantWaterproof && item.waterproof) s += 3;

      for (final other in picked) {
        if (!_coloursMatch(item.colour, other.colour)) s -= 2;
      }
      return s;
    }

    final best = candidates.map(score).reduce((a, b) => a > b ? a : b);
    // picks randomly among items within 1 point of the best
    final goodEnough = candidates.where((i) => score(i) >= best - 1).toList();
    return goodEnough[rng.nextInt(goodEnough.length)];
  }

  // true if two colours go together
  bool _coloursMatch(String a, String b) {
    final x = a.toLowerCase().trim();
    final y = b.toLowerCase().trim();

    if (x.isEmpty || y.isEmpty || x == y) return true;
    if (_neutralColours.contains(x) || _neutralColours.contains(y)) return true;

    return _goodPairs.any(
      (p) => (p.$1 == x && p.$2 == y) || (p.$1 == y && p.$2 == x),
    );
  }
}