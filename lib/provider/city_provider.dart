import 'package:flutter/foundation.dart';
import '../db/city_database.dart';

class CityProvider with ChangeNotifier {
  List<String> _cities = [];

  List<String> get cities => _cities;

  // Database instance
  final _db = CityDatabase();

  // Load cities from the database
  Future<void> loadCities() async {
    _cities = await _db.getCities();
    notifyListeners();
  }

  // Add a city to the database
  Future<void> addCity(String city) async {
    if (!_cities.contains(city)) {
      await _db.addCity(city);
      await loadCities();
    }
  }

  // Remove a city from the database
  Future<void> removeCity(String city) async {
    await _db.removeCity(city);
    await loadCities();
  }
}
