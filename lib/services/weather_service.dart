import 'dart:convert';
import 'package:http/http.dart' as http;

// Class to handle the weather service
class WeatherService {
  static const String _baseUrl = 'https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline';
  static const String _apiKey = '5YW94J4PQ9RZRBJUE9SS97WNE';

  // Function to fetch weather data from the API
  Future<Map<String, dynamic>?> fetchWeather(String location, {String? date}) async {
    final now = DateTime.now();
    final formattedDate = date ?? "${now.year}-${_pad(now.month)}-${_pad(now.day)}";
    final url = '$_baseUrl/$location/$formattedDate?include=days,hours,current&key=$_apiKey&iconSet=icons2';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print("API: ${json.decode(response.body)}");
        return json.decode(response.body);
      } else {
        print('Failed to load weather: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  // Function to fetch tomorrow's weather data
  Future<Map<String, dynamic>?> fetchTomorrowWeather(String location) {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    final formattedDate = "${tomorrow.year}-${_pad(tomorrow.month)}-${_pad(tomorrow.day)}";
    return fetchWeather(location, date: formattedDate);
  }

  // Function to fetch weather data for the next 7 days
  Future<List<dynamic>?> fetchWeekWeather(String location, int days) async {
    final now = DateTime.now();
    List<dynamic> weekDays = [];

    for (int i = 0; i < days; i++) {
      final date = now.add(Duration(days: i));
      final formattedDate = "${date.year}-${_pad(date.month)}-${_pad(date.day)}";
      final weatherData = await fetchWeather(location, date: formattedDate);

      if (weatherData != null && weatherData['days'] != null && weatherData['days'] is List) {
        final day = weatherData['days'][0];
        weekDays.add(day);
      }
    }

    return weekDays;
  }


  String _pad(int number) => number.toString().padLeft(2, '0');
}
