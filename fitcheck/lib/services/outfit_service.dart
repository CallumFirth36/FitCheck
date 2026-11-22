import 'dart:math';

import 'package:fitcheck/models/clothing_item.dart';
import 'package:fitcheck/models/outfit.dart';
import 'package:fitcheck/models/weather_info.dart';

/// Shared instance: `outfitService.generate(...)`.
final outfitService = OutfitService();

/// Builds an outfit from the user's wardrobe and the current weather.
///
/// Rule-based and pure (no Firebase, network or UI), so it is easy to test.
class OutfitService {
  /// Wind speed (km/h) at or above which it counts as windy.
  static const double windyThreshold = 30;

  // NEW: colours that go with everything.
  static const Set<String> _neutralColours = {
    'black', 'white', 'grey', 'navy', 'beige', 'brown',
  };

  // NEW: pairs of non-neutral colours that work together. Any other pair of
  // different non-neutral colours counts as a clash. This is taste, not
  // science, so edit it freely.
  static const List<(String, String)> _goodPairs = [
    ('blue', 'orange'),
    ('blue', 'yellow'),
    ('blue', 'pink'),
    ('blue', 'green'),
    ('green', 'yellow'),
    ('purple', 'pink'),
    ('purple', 'yellow'),
  ];

  /// Maps how cold it feels (°C) to a warmth level, 1 (hot) to 5 (freezing).
  int targetWarmthFor(double feelsLike) {
    if (feelsLike >= 22) return 1;
    if (feelsLike >= 16) return 2;
    if (feelsLike >= 10) return 3;
    if (feelsLike >= 4) return 4;
    return 5;
  }

  /// Returns an outfit plus plain-English notes explaining each choice.
  Outfit generate({
    required List<ClothingItem> wardrobe,
    required WeatherInfo weather,
    Random? random, // pass a seeded Random in tests for repeatable results
  }) {
    final rng = random ?? Random();
    final notes = <String>[];
    final rain = weather.rainLikely;

    // NEW: everything chosen so far. Each new pick is colour-checked against
    // this list, which is why the order of the picks below matters.
    final picked = <ClothingItem>[];

    // NEW: picks one item and records it in `picked`.
    // HOW: a function declared inside another function can use the outer
    // function's variables (wardrobe, picked, rng), so each call below stays short.
    ClothingItem? choose(
      ClothingCategory category,
      int target, {
      bool waterproof = false,
    }) {
      final item = _pick(wardrobe, category, target, waterproof, picked, rng);
      if (item != null) picked.add(item);
      return item;
    }

    // 1. Target warmth for the whole outfit.
    final target = targetWarmthFor(weather.feelsLike);
    notes.add(
      'It feels like ${weather.feelsLike.round()}°C, so the outfit should be '
      'around warmth level $target out of ${ClothingItem.maxWarmth}.',
    );

    // 2. Outer layer: needed if it is cool, rainy or windy. Picked first
    // because it matters most (warmth, waterproofing) and so gets first
    // choice of colour.
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

    // 3. NEW: mid layer (hoodie, jumper). Added when it is cold, or when it is
    // cool and there is no outer layer to wear.
    // HOW: with a coat on, the mid layer only needs to be one level below the
    // target. Without a coat it has to do the coat's job as well.
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

    // 4. Top and bottom.
    // CHANGED: each layer worn over the top shares the warming, so the top can
    // be lighter. HOW: target 5 with a coat and a hoodie gives the top a
    // target of 3. Bottoms are only lightened for a coat, since a hoodie
    // does not keep legs warm.
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

    // 5. Accessory (scarf, hat) when it is cold.
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

    // NEW: final colour check. The picking avoids clashes where it can, but
    // warmth and waterproofing come first, so a clash can still slip through.
    // HOW: compare every pair of picked items once (i with each later j).
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

  /// Best item in [category] for [targetWarmth], or null if there is none.
  ///
  /// Score for each item:
  ///   warmth fit      0 if exact, minus 1 per level away from the target
  ///   waterproof      +3 if [wantWaterproof] and the item is waterproof
  ///   colour clash    NEW: -2 for each already [picked] item it clashes with
  ///
  /// Items within 1 point of the best are "good enough" and one is chosen at
  /// random, which is what lets "Try another" give a different outfit.
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

      // NEW: HOW: -2 is bigger than the 1-point "good enough" window, so a
      // clashing item only wins if every alternative is a much worse
      // fit for the weather.
      for (final other in picked) {
        if (!_coloursMatch(item.colour, other.colour)) s -= 2;
      }
      return s;
    }

    final best = candidates.map(score).reduce((a, b) => a > b ? a : b);
    final goodEnough = candidates.where((i) => score(i) >= best - 1).toList();
    return goodEnough[rng.nextInt(goodEnough.length)];
  }

  /// NEW: true if two colours go together.
  /// Matches: same colour, either one neutral, or a pair in [_goodPairs].
  /// An unknown (empty) colour never counts as a clash.
  bool _coloursMatch(String a, String b) {
    final x = a.toLowerCase().trim();
    final y = b.toLowerCase().trim();

    if (x.isEmpty || y.isEmpty || x == y) return true;
    if (_neutralColours.contains(x) || _neutralColours.contains(y)) return true;

    // p.$1 and p.$2 are the two parts of each pair, checked in either order
    return _goodPairs.any(
      (p) => (p.$1 == x && p.$2 == y) || (p.$1 == y && p.$2 == x),
    );
  }
}