import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Text size
enum TextSizeOption {
  normal(1.0, 'Normal'),
  large(1.2, 'Large'),
  extraLarge(1.4, 'Extra large');

  const TextSizeOption(this.scale, this.label);

  final double scale;
  final String label;
}

// One shared instance, used anywhere with: settingsService.textSize
final settingsService = SettingsService();

// save on phone with shared preferences
class SettingsService {
  static const String _textSizeKey = 'text_size';

  final ValueNotifier<TextSizeOption> textSize =
      ValueNotifier(TextSizeOption.normal);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_textSizeKey);
      textSize.value = TextSizeOption.values.firstWhere(
        (o) => o.name == saved,
        orElse: () => TextSizeOption.normal, // nothing saved, or unrecognised
      );
    } catch (e) {
      print(e);
    }
  }

  // Changes the text size and saves it.
  Future<void> setTextSize(TextSizeOption option) async {
    textSize.value = option;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_textSizeKey, option.name);
    } catch (e) {
      print(e);
    }
  }
}