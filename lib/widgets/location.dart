import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// Uses Geolocator to get current location
Future<Position> getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.',
    );
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

// Uses reverse geocoding to get the city and country name from current location
Future<String> getCityAndCountryFromPosition() async {
  try {
    final position = await getCurrentLocation();
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      final city = place.locality ?? place.subAdministrativeArea ?? "Unknown city";
      final country = place.country ?? "Unknown country";
      return "$city, $country";
    } else {
      return "Unknown location";
    }
  } catch (e) {
    return "Error retrieving location: $e";
  }
}
