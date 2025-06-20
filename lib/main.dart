import 'dart:math';

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/pages/weather_details.dart';
import 'package:weather_app/pages/settings_page.dart';
import 'package:weather_app/provider/city_provider.dart';
import 'package:weather_app/provider/weather_provider.dart';
import 'package:weather_app/widgets/location.dart';
import 'package:weather_app/widgets/weather_bottom_nav_bar.dart';
import 'package:weather_app/widgets/weather_card.dart';
import 'package:weather_app/utils.dart';
import 'package:weather_app/db/settings_database.dart';
import 'package:weather_app/widgets/hourly_forescast_row.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WeatherProvider()), // WeatherProvider for weather data
        ChangeNotifierProvider(create: (_) => CityProvider()..loadCities()), // CityProvider for saved cities
      ],
      child: const WeatherApp(),
    ),
  );
}

// Class to handle the weather app
class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Montserrat',
      ),
      home: const MainNavigation(),
    );
  }
}

// Class to handle the main navigation
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

// Class to handle the main navigation state
class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final _pages = [
      const WeatherHome(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: WeatherBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

// Class to handle the home page
class WeatherHome extends StatefulWidget {
  const WeatherHome({super.key});

  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

// Class to handle the home page state
class _WeatherHomeState extends State<WeatherHome> {
  TextEditingController _controller = TextEditingController(text: "Viseu,PT");
  String? _locationText;
  Map<String, dynamic>? _selectedHour; // To store the selected hour data
  final _settingsDb = SettingsDatabase();

  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? _currentConditions;
  String _temperatureUnit = 'C';
  String _speedUnit = 'km/h';
  String _lengthUnit = 'mm';
  bool _showExtraDetails = false;
  List<String> _cityNames = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadSettings();
    // Load city names from the CSV file for the autocomplete feature
    loadCityNames().then((names) {
      setState(() {
        _cityNames = names;
      });
    });
  }

  // Function to load settings from the database picked by the user
  Future<void> _loadSettings() async {
    final temp = await _settingsDb.getSetting('temperatureUnit');
    final speed = await _settingsDb.getSetting('speedUnit');
    final length = await _settingsDb.getSetting('lengthUnit');
    final extra = await _settingsDb.getSetting('showExtraDetails');
    setState(() {
      _temperatureUnit = temp ?? 'C';
      _speedUnit = speed ?? 'km/h';
      _lengthUnit = length ?? 'mm';
      _showExtraDetails = extra == 'true';
    });
  }

  // Function to get the user's location
  Future<void> _getUserLocation() async {
    try {
      final locationString = await getCityAndCountryFromPosition();
      setState(() {
        _locationText = locationString;
      });
      if (mounted) _loadWeather(locationString);
    } catch (e) {
      setState(() {
        _locationText = "Failed to get location: $e";
      });
    }
  }

  // Function to load weather data
  Future<void> _loadWeather(String location) async {
    final provider = Provider.of<WeatherProvider>(context, listen: false);
    await provider.loadWeather(location);
    setState(() {
      _weatherData = provider.currentWeather;
      _currentConditions = provider.currentWeather?['currentConditions'];
    });
  }

  // Function to load city names from a CSV file
  Future<List<String>> loadCityNames() async {
    final rawData = await rootBundle.loadString('assets/cities.csv');
    final List<List<dynamic>> csvData = const CsvToListConverter().convert(rawData, eol: '\n');

    // Skip the header row and extract the first column (city name)
    List<String> cityNames = csvData.skip(1).map((row) => row[0].toString()).toList();

    return cityNames;
  }

  @override
  Widget build(BuildContext context) {
    final cityProvider = Provider.of<CityProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Weather App",
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/weather_background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    kToolbarHeight - MediaQuery.of(context).padding.top,
              ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Current Location:",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _locationText ?? "Fetching location...",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedHour != null
                        ? "${_selectedHour!['datetime']?.substring(0, 5) ?? '--:--'}"
                        : "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
              
                  // Weather Card
                  if (_weatherData != null && _currentConditions != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: WeatherCard(
                        current:  _selectedHour ?? _currentConditions!,
                        data: _weatherData!,
                        showExtraDetails: _showExtraDetails,
                        onToggleExtraDetails: (val) {
                          setState(() => _showExtraDetails = val);
                        },
                        temperatureUnit: _temperatureUnit,
                        speedUnit: _speedUnit,
                        lengthUnit: _lengthUnit,
                      ),
                    ),
              
                  const SizedBox(height: 16),
              
                  // Hourly Forecast Row
                  if (_weatherData != null && _weatherData!['days']?[0]?['hours'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Upcoming Forecast for Today",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        HourlyForecastRow(
                          tempUnit: _temperatureUnit,
                          hours: (_weatherData!['days'][0]['hours'] as List).where((hour) {
                            final timeString = hour['datetime'];
                            if (timeString == null || timeString is! String) return false;
              
                            final parts = timeString.split(":");
                            if (parts.length < 2) return false;
              
                            final hourInt = int.tryParse(parts[0]) ?? 0;
                            final minuteInt = int.tryParse(parts[1]) ?? 0;
              
                            final now = DateTime.now();
                            final endOfToday = DateTime(now.year, now.month, now.day, 23, 59);
                            final hourDateTime = DateTime(now.year, now.month, now.day, hourInt, minuteInt);
              
                            // Include current and future hours up to 23:59
                            return !hourDateTime.isBefore(now) && hourDateTime.isBefore(endOfToday);
                          }).toList(),
                          icon: _weatherData!['days'][0]['icon'],
                          onHourTap: (hourData) {
                            setState(() {
                              _selectedHour = hourData;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Alerts",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Handling alerts
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white),
                          ),
                          child: _weatherData!['alerts'] == null || _weatherData!['alerts'].isEmpty
                              ? Text(
                            "No alerts at this time. Check later!",
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.white
                            ),
                          )
                              : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _weatherData!['alerts'].map<Widget>((alert) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alert['event'] ?? 'Unknown Event',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      alert['description'] ?? 'No description available.',
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.white
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
              
                  const SizedBox(height: 20),
                  const Divider(height: 32),
                  const SizedBox(height: 20),
              
                  const Text(
                    "Saved Cities",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            return _cityNames.where((city) =>
                                city.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                          },
                          onSelected: (String selection) {
                            print('Selected: $selection');
                          },
                          fieldViewBuilder: (context, textEditingController, focusNode, onEditingComplete) {
                            _controller = textEditingController;
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _controller,
                                focusNode: focusNode,
                                onEditingComplete: onEditingComplete,
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  labelText: 'Search City (e.g., Dubai)',
                                  labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 12),
                                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.lightBlue),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 250,
                                  constraints: const BoxConstraints(
                                    maxHeight: 150,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: min(options.length, 20),
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option, style: const TextStyle(color: Colors.black87)),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 6), // Space between input and button
                      ElevatedButton(
                        onPressed: () {
                          if (_controller.text.length > 2) {
                            cityProvider.addCity(_controller.text);

                            _controller.clear();
                            FocusScope.of(context).unfocus();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "The city named ${_controller.text} was added to the list!",
                                  style: const TextStyle(fontFamily: 'Montserrat'),
                                ),
                                backgroundColor: Colors.blueAccent.withOpacity(0.8),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 3),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "The city name must have at least 3 letters!",
                                  style: const TextStyle(fontFamily: 'Montserrat'),
                                ),
                                backgroundColor: Colors.blueAccent.withOpacity(0.8),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 3),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.lightBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 6,
                          shadowColor: Colors.black.withOpacity(0.2),
                        ),
                        child: const Text(
                          "Save City",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  cityProvider.cities.isEmpty
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No cities have been added yet.',
                        style: TextStyle(
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cityProvider.cities.length,
                    itemBuilder: (context, index) {
                      final city = cityProvider.cities[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WeatherDetailsPage(city: city),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                            child: Row(
                              children: [
                                const Icon(Icons.location_city, color: Colors.lightBlue, size: 24),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    city,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          title: const Text('Delete City', style: TextStyle(fontWeight: FontWeight.bold)),
                                          content: Text(
                                            'Are you sure you want to delete "$city" from your saved cities?',
                                            style: const TextStyle(fontSize: 15),
                                          ),
                                          actionsPadding: const EdgeInsets.only(bottom: 12, right: 12),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.redAccent,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () {
                                                cityProvider.removeCity(city);
                                                Navigator.of(context).pop();
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '"$city" was removed from your saved cities.',
                                                      style: const TextStyle(fontFamily: 'Montserrat'),
                                                    ),
                                                    backgroundColor: Colors.blueAccent.withOpacity(0.8),
                                                    behavior: SnackBarBehavior.floating,
                                                    duration: const Duration(seconds: 3),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                );
                                              },
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  tooltip: "Remove city",
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ),
          ),
          if (_selectedHour != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedHour = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "You reset to the current hour!",
                        style: const TextStyle(fontFamily: 'Montserrat'),
                      ),
                      backgroundColor: Colors.blueAccent.withOpacity(0.8),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                ),
                child: const Text(
                  "Reset to current hour",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
