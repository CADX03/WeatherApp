import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();

  Map<String, dynamic>? currentWeather;
  Map<String, dynamic>? tomorrowWeather;
  List<dynamic>? weekWeather;
  bool isLoading = false;

  // Function to load weather data
  Future<void> loadWeather(String city) async {
    isLoading = true;
    notifyListeners();

    currentWeather = await _weatherService.fetchWeather(city); // Fetch current weather data from the API

    tomorrowWeather = await _weatherService.fetchTomorrowWeather(city); // Fetch tomorrow's weather data from the API

    weekWeather = await _weatherService.fetchWeekWeather(city, 7); // Fetch weather data for the next 7 days from the API

    isLoading = false;
    notifyListeners();
  }
}