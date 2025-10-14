import 'package:geolocator/geolocator.dart';

class LocationService {

  static Future<Position?> getCurrentPosition() async {

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {

      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
