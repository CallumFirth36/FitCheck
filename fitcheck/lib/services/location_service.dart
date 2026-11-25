import 'package:geolocator/geolocator.dart';

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

// Gets location form GPS
class LocationService {
  
  // default location if cant get location (london)
  static const double defaultLatitude = 51.5072;
  static const double defaultLongitude = -0.1276;

  AppLocation _fallback() => const AppLocation(
        latitude: defaultLatitude,
        longitude: defaultLongitude,
        isDefault: true,
      );

  Future<AppLocation> getLocation() async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) return _fallback();

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _fallback();
      }

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