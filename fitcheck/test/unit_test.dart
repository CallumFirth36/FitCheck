import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitcheck/core/clothing_colours.dart';
import 'package:fitcheck/models/clothing_item.dart';
import 'package:fitcheck/models/outfit.dart';
import 'package:fitcheck/models/weather_info.dart';
import 'package:fitcheck/services/outfit_service.dart';
import 'package:fitcheck/services/settings_service.dart';

ClothingItem item(
  String name,
  ClothingCategory category, {
  String colour = 'black',
  int warmth = 3,
  bool waterproof = false,
}) {
  return ClothingItem(
    name: name,
    category: category,
    colour: colour,
    warmth: warmth,
    waterproof: waterproof,
    createdAt: DateTime(2026, 1, 1),
  );
}

WeatherInfo weather({
  double feelsLike = 15,
  double wind = 5,
  int rainChance = 0,
  double precipitation = 0,
  int code = 3,
}) {
  return WeatherInfo(
    temperature: feelsLike,
    feelsLike: feelsLike,
    windSpeed: wind,
    precipitation: precipitation,
    rainChance: rainChance,
    weatherCode: code,
    usedDefaultLocation: false,
  );
}

List<ClothingItem> fullWardrobe() {
  return [
    item('Coat', ClothingCategory.outerwear, warmth: 5),
    item('Hoodie', ClothingCategory.midLayer, warmth: 3),
    item('T-shirt', ClothingCategory.top, warmth: 2),
    item('Jeans', ClothingCategory.bottom, warmth: 3),
    item('Trainers', ClothingCategory.shoes, warmth: 2),
    item('Scarf', ClothingCategory.accessory, warmth: 4),
  ];
}

void main () {

// ------ WARMTH LEVEL TESTING ------
  group ('warmth level testing', (){
      test('Freezing Temp gives warmth level 5', (){
        final service = OutfitService();

        final level = service.targetWarmthFor(-2);

        expect(level, 5);
      });

      test('Boundary at 4 degrees switches between level 5 and 4', (){
        final service = OutfitService();

        expect(service.targetWarmthFor(3.9), 5);
        expect(service.targetWarmthFor(4), 4);
      });

      test('Boundary at 10 degrees switches between level 4 and 3', (){
        final service = OutfitService();

        expect(service.targetWarmthFor(9.9), 4);
        expect(service.targetWarmthFor(10), 3);
      });

      test('Boundary at 16 degrees switches between level 3 and 2', (){
        final service = OutfitService();

        expect(service.targetWarmthFor(15.9), 3);
        expect(service.targetWarmthFor(16), 2);
      });

      test('Boundary at 22 degrees switches between level 2 and 1', (){
        final service = OutfitService();

        expect(service.targetWarmthFor(21.9), 2);
        expect(service.targetWarmthFor(22), 1);
      });

      test('Very hot temp gives warmth level 1', (){
        final service = OutfitService();

        final level = service.targetWarmthFor(40);

        expect(level, 1);
      });
  });


// ------ OUTFIT TESTING ------
  group ('outfit testing', (){
      test('Hot day gives no outer layer or mid layer', (){
        final outfit = OutfitService().generate(
          wardrobe: fullWardrobe(),
          weather: weather(feelsLike: 25),
        );

        expect(outfit.outerwear, isNull);
        expect(outfit.midLayer, isNull);
        expect(outfit.accessory, isNull);
        expect(outfit.top?.name, 'T-shirt');
      });

      test('Mild dry day gives top, bottom and shoes only', (){
        final outfit = OutfitService().generate(
          wardrobe: fullWardrobe(),
          weather: weather(feelsLike: 18),
        );

        expect(outfit.outerwear, isNull);
        expect(outfit.midLayer, isNull);
        expect(outfit.accessory, isNull);
        expect(outfit.top, isNotNull);
        expect(outfit.bottom, isNotNull);
        expect(outfit.shoes, isNotNull);
      });

      test('Cool day gives an outer layer but no mid layer', (){
        final outfit = OutfitService().generate(
          wardrobe: fullWardrobe(),
          weather: weather(feelsLike: 12),
        );

        expect(outfit.outerwear?.name, 'Coat');
        expect(outfit.midLayer, isNull);
      });

      test('Cool day without a coat uses a mid layer instead', (){
        final wardrobe = fullWardrobe()
            .where((i) => i.category != ClothingCategory.outerwear)
            .toList();

        final outfit = OutfitService().generate(
          wardrobe: wardrobe,
          weather: weather(feelsLike: 12),
        );

        expect(outfit.outerwear, isNull);
        expect(outfit.midLayer?.name, 'Hoodie');
      });

      test('Cold day layers a coat, a mid layer and a lighter top', (){
        final wardrobe = [
          ...fullWardrobe(),
          item('Thick top', ClothingCategory.top, warmth: 5),
        ];

        final outfit = OutfitService().generate(
          wardrobe: wardrobe,
          weather: weather(feelsLike: 6),
        );

        expect(outfit.outerwear?.name, 'Coat');
        expect(outfit.midLayer?.name, 'Hoodie');
        expect(outfit.top?.name, 'T-shirt');
      });

      test('Freezing day adds an accessory', (){
        final outfit = OutfitService().generate(
          wardrobe: fullWardrobe(),
          weather: weather(feelsLike: -2),
        );

        expect(outfit.accessory?.name, 'Scarf');
        expect(outfit.notes, contains('It is cold, so an accessory was added.'));
      });

      test('Rain picks the waterproof coat over a better warmth match', (){
        final wardrobe = [
          item('Wool coat', ClothingCategory.outerwear, warmth: 3),
          item('Rain jacket', ClothingCategory.outerwear, warmth: 2, waterproof: true),
          item('T-shirt', ClothingCategory.top, warmth: 2),
          item('Jeans', ClothingCategory.bottom),
          item('Trainers', ClothingCategory.shoes),
        ];

        final outfit = OutfitService().generate(
          wardrobe: wardrobe,
          weather: weather(feelsLike: 12, rainChance: 80),
        );

        expect(outfit.outerwear?.name, 'Rain jacket');
        expect(outfit.notes, contains('Rain is likely, so a waterproof outer layer was chosen.'));
      });

      test('Rain with no waterproof coat gives an umbrella note', (){
        final outfit = OutfitService().generate(
          wardrobe: fullWardrobe(),
          weather: weather(feelsLike: 12, rainChance: 80),
        );

        expect(outfit.notes, contains('Rain is likely and you have no waterproof outer layer. Take an umbrella.'));
      });

      test('Rain with shoes that are not waterproof gives a puddle note', (){
        final outfit = OutfitService().generate(
          wardrobe: fullWardrobe(),
          weather: weather(feelsLike: 12, rainChance: 80),
        );

        expect(outfit.notes, contains('Your shoes are not waterproof, so watch out for puddles.'));
      });

      test('Windy day recommends an outer layer even when mild', (){
        final outfit = OutfitService().generate(
          wardrobe: fullWardrobe(),
          weather: weather(feelsLike: 18, wind: 35),
        );

        expect(outfit.outerwear?.name, 'Coat');
        expect(outfit.notes, contains('An outer layer is recommended because it is windy.'));
      });

      test('Missing mid layer still gives an outfit and a note', (){
        final wardrobe = fullWardrobe()
            .where((i) => i.category != ClothingCategory.midLayer)
            .toList();

        final outfit = OutfitService().generate(
          wardrobe: wardrobe,
          weather: weather(feelsLike: 6),
        );

        expect(outfit.midLayer, isNull);
        expect(outfit.outerwear, isNotNull);
        expect(outfit.top, isNotNull);
        expect(outfit.notes, contains('You have no hoodies or jumpers to layer. Add one for colder days.'));
      });

      test('Missing coat on a cold day still gives an outfit and a note', (){
        final wardrobe = fullWardrobe()
            .where((i) => i.category != ClothingCategory.outerwear)
            .toList();

        final outfit = OutfitService().generate(
          wardrobe: wardrobe,
          weather: weather(feelsLike: 6),
        );

        expect(outfit.outerwear, isNull);
        expect(outfit.midLayer, isNotNull);
        expect(outfit.notes, contains('You have no outerwear. Add a jacket or coat for days like this.'));
      });

      test('Missing shoes gives a note', (){
        final wardrobe = fullWardrobe()
            .where((i) => i.category != ClothingCategory.shoes)
            .toList();

        final outfit = OutfitService().generate(
          wardrobe: wardrobe,
          weather: weather(feelsLike: 15),
        );

        expect(outfit.shoes, isNull);
        expect(outfit.notes, contains('You have no shoes yet. Add some to complete the outfit.'));
      });

      test('Empty wardrobe gives an empty outfit', (){
        final outfit = OutfitService().generate(
          wardrobe: [],
          weather: weather(),
        );

        expect(outfit.isEmpty, isTrue);
      });

      test('Same random seed gives the same outfit', (){
        final wardrobe = [
          ...fullWardrobe(),
          item('Polo', ClothingCategory.top, warmth: 2),
        ];

        final first = OutfitService().generate(
          wardrobe: wardrobe,
          weather: weather(feelsLike: 25),
          random: Random(1),
        );
        final second = OutfitService().generate(
          wardrobe: wardrobe,
          weather: weather(feelsLike: 25),
          random: Random(1),
        );

        expect(first.top?.name, second.top?.name);
      });
  });


// ------ COLOUR TESTING ------
  group ('colour testing', (){
      test('Clashing colour is avoided when there is an alternative', (){
        final wardrobe = [
          item('Red coat', ClothingCategory.outerwear, colour: 'red'),
          item('Green top', ClothingCategory.top, colour: 'green'),
          item('White top', ClothingCategory.top, colour: 'white'),
          item('Jeans', ClothingCategory.bottom),
          item('Trainers', ClothingCategory.shoes),
        ];

        final outfit = OutfitService().generate(
          wardrobe: wardrobe,
          weather: weather(feelsLike: 12),
        );

        expect(outfit.top?.name, 'White top');
        expect(outfit.notes, contains('The colours were chosen to go together.'));
      });

      test('Clash is reported when there is no alternative', (){
        final wardrobe = [
          item('Red coat', ClothingCategory.outerwear, colour: 'red'),
          item('Green top', ClothingCategory.top, colour: 'green'),
          item('Jeans', ClothingCategory.bottom),
          item('Trainers', ClothingCategory.shoes),
        ];

        final outfit = OutfitService().generate(
          wardrobe: wardrobe,
          weather: weather(feelsLike: 12),
        );

        expect(outfit.top?.name, 'Green top');
        expect(outfit.notes, contains('Red coat and Green top may clash, but they were the best fit for the weather.'));
      });

      test('Neutral colours never clash', (){
        final wardrobe = [
          item('Red coat', ClothingCategory.outerwear, colour: 'red'),
          item('Grey top', ClothingCategory.top, colour: 'grey'),
          item('Jeans', ClothingCategory.bottom),
          item('Trainers', ClothingCategory.shoes),
        ];

        final outfit = OutfitService().generate(
          wardrobe: wardrobe,
          weather: weather(feelsLike: 12),
        );

        expect(outfit.notes.any((n) => n.contains('may clash')), isFalse);
      });

      test('Known colour name is found whatever the case', (){
        final lower = ClothingColours.colorFor('navy');
        final upper = ClothingColours.colorFor('NAVY');

        expect(upper, lower);
        expect(ClothingColours.all.map((c) => c.name), contains('navy'));
      });

      test('Unknown colour name falls back to grey', (){
        final unknown = ClothingColours.colorFor('banana');
        final empty = ClothingColours.colorFor('');

        expect(unknown, empty);
        expect(unknown, isNot(ClothingColours.colorFor('navy')));
      });
  });


// ------ WEATHER TESTING ------
  group ('weather testing', (){
      test('fromJson reads the weather response', (){
        final json = <String, dynamic>{
          'current': {
            'temperature_2m': 8.4,
            'apparent_temperature': 6.1,
            'precipitation': 0.0,
            'weather_code': 61,
            'wind_speed_10m': 12.5,
          },
          'daily': {
            'precipitation_probability_max': [35],
          },
        };

        final info = WeatherInfo.fromJson(json, usedDefaultLocation: false);

        expect(info.temperature, 8.4);
        expect(info.feelsLike, 6.1);
        expect(info.windSpeed, 12.5);
        expect(info.weatherCode, 61);
        expect(info.rainChance, 35);
      });

      test('fromJson with no rain chance data gives 0', (){
        final json = <String, dynamic>{
          'current': {
            'temperature_2m': 8.4,
            'apparent_temperature': 6.1,
            'precipitation': 0.0,
            'weather_code': 61,
            'wind_speed_10m': 12.5,
          },
          'daily': {
            'precipitation_probability_max': [],
          },
        };

        final info = WeatherInfo.fromJson(json, usedDefaultLocation: true);

        expect(info.rainChance, 0);
        expect(info.usedDefaultLocation, isTrue);
      });

      test('Rain is likely at 40 percent but not at 39', (){
        expect(weather(rainChance: 40).rainLikely, isTrue);
        expect(weather(rainChance: 39).rainLikely, isFalse);
      });

      test('Rain is likely when it is raining now', (){
        final raining = weather(precipitation: 0.2);

        expect(raining.rainLikely, isTrue);
      });

      test('Weather codes give the right description', (){
        expect(weather(code: 0).description, 'Clear sky');
        expect(weather(code: 3).description, 'Overcast');
        expect(weather(code: 61).description, 'Rain');
        expect(weather(code: 95).description, 'Thunderstorm');
        expect(weather(code: 999).description, 'Unknown');
      });
  });


// ------ CLOTHING ITEM TESTING ------
  group ('clothing item testing', (){
      test('toMap then fromMap keeps every field', (){
        final original = item(
          'Navy hoodie',
          ClothingCategory.midLayer,
          colour: 'navy',
          warmth: 4,
          waterproof: true,
        );

        final restored = ClothingItem.fromMap('abc', original.toMap());

        expect(restored.id, 'abc');
        expect(restored.name, 'Navy hoodie');
        expect(restored.category, ClothingCategory.midLayer);
        expect(restored.colour, 'navy');
        expect(restored.warmth, 4);
        expect(restored.waterproof, isTrue);
        expect(restored.createdAt, original.createdAt);
      });

      test('Unknown category falls back to top', (){
        final restored = ClothingItem.fromMap('x', <String, dynamic>{
          'name': 'Hat',
          'category': 'hat',
        });

        expect(restored.category, ClothingCategory.top);
      });

      test('Warmth is kept between 1 and 5', (){
        final tooHigh = ClothingItem.fromMap('x', <String, dynamic>{'warmth': 9});
        final tooLow = ClothingItem.fromMap('x', <String, dynamic>{'warmth': 0});

        expect(tooHigh.warmth, 5);
        expect(tooLow.warmth, 1);
      });

      test('Missing fields get safe defaults', (){
        final restored = ClothingItem.fromMap('x', <String, dynamic>{});

        expect(restored.name, 'Unnamed item');
        expect(restored.category, ClothingCategory.top);
        expect(restored.colour, '');
        expect(restored.warmth, 3);
        expect(restored.waterproof, isFalse);
      });

      test('Category name lookup ignores case and handles null', (){
        expect(ClothingCategory.fromName('MIDLAYER'), ClothingCategory.midLayer);
        expect(ClothingCategory.fromName('midLayer'), ClothingCategory.midLayer);
        expect(ClothingCategory.fromName(null), ClothingCategory.top);
      });

      test('Mid layer label reads Mid layer', (){
        expect(ClothingCategory.midLayer.label, 'Mid layer');
      });
  });


// ------ OUTFIT MODEL TESTING ------
  group ('outfit model testing', (){
      test('Items are in order and empty slots are skipped', (){
        final outfit = Outfit(
          top: item('Top', ClothingCategory.top),
          midLayer: item('Mid', ClothingCategory.midLayer),
          bottom: item('Bottom', ClothingCategory.bottom),
          shoes: item('Shoes', ClothingCategory.shoes),
          outerwear: item('Outer', ClothingCategory.outerwear),
        );

        final names = outfit.items.map((i) => i.name).toList();

        expect(names, ['Outer', 'Mid', 'Top', 'Bottom', 'Shoes']);
      });

      test('Outfit with nothing picked is empty', (){
        const outfit = Outfit();

        expect(outfit.isEmpty, isTrue);
      });
  });


// ------ TEXT SIZE TESTING ------
  group ('text size testing', (){
      test('Text size options have the right scales and labels', (){
        expect(TextSizeOption.normal.scale, 1.0);
        expect(TextSizeOption.large.scale, 1.2);
        expect(TextSizeOption.extraLarge.scale, 1.4);
        expect(TextSizeOption.extraLarge.label, 'Extra large');
      });
  });

}