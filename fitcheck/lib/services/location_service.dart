import 'package:geolocator/geolocator.dart';

// A latitude/longitude pair, plus whether it's the fallback location.
class AppLocation {
  final double latitude;
  final double longitude;
  final bool isDefault; // true if this is the fallback, not the real position

  const AppLocation({
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
  });
}

// Finds out where the user is, using the phone's location hardware (GPS).
// If anything goes wrong, it returns a default city instead of failing, so
// the weather (and your demo) still works.
class LocationService {
  // Fallback used when the real location can't be found (permission denied,
  // location switched off, no GPS fix...). CHANGE this to your own city.
  static const double defaultLatitude = 51.5072;   // London
  static const double defaultLongitude = -0.1276;

  AppLocation _fallback() => const AppLocation(
        latitude: defaultLatitude,
        longitude: defaultLongitude,
        isDefault: true,
      );

  Future<AppLocation> getLocation() async {
    try {
      // 1. Is location switched on for the whole phone?
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) return _fallback();

      // 2. Has the user allowed this app to use it? If we haven't asked yet,
      //    this shows the system permission popup.
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _fallback();
      }

      // 3. Ask the phone for its position. "high" accuracy asks for the
      //    GPS chip. If there's no fix within 10 seconds it gives up and
      //    throws, which the catch below turns into the fallback.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return AppLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      print(e);
      return _fallback();
    }
  }
}