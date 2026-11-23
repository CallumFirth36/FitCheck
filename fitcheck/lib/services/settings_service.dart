import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The text sizes the user can pick. scale is multiplied with the text size
// of the whole app (1.0 = normal).
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

// Holds the user's settings and saves them on the phone (shared_preferences),
// so they survive closing the app.
class SettingsService {
  static const String _textSizeKey = 'text_size';

  // The current text size. A ValueNotifier tells anything listening
  // (MyApp in main.dart, the Preferences chips) whenever it changes.
  final ValueNotifier<TextSizeOption> textSize =
      ValueNotifier(TextSizeOption.normal);

  // Reads the saved settings. Called once in main() before the app starts.
  // If anything goes wrong it keeps the defaults, so it can't crash the app.
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
    // update first, so the screen changes straight away
    textSize.value = option;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_textSizeKey, option.name);
    } catch (e) {
      // the size still applies this session, it just won't be remembered
      print(e);
    }
  }
}