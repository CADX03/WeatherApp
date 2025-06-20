import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/provider/weather_provider.dart';
import 'package:weather_app/widgets/weather_info_tile.dart';
import 'package:weather_app/widgets/hourly_forescast_row.dart';
import 'package:weather_app/widgets/info_row.dart';
import 'package:weather_app/db/settings_database.dart';
import 'package:weather_app/utils.dart';
import 'package:weather_app/widgets/weather_card.dart';
import 'package:weather_app/widgets/sun_path_painter.dart';

// Class to handle the weather details page
class WeatherDetailsPage extends StatefulWidget {
  final String city;

  const WeatherDetailsPage({super.key, required this.city});

  @override
  State<WeatherDetailsPage> createState() => _WeatherDetailsPageState();
}

// Class to handle the weather details page state
class _WeatherDetailsPageState extends State<WeatherDetailsPage> {
  String _temperatureUnit = 'C';
  String _speedUnit = 'km/h';
  String _lengthUnit = 'mm';
  bool _showExtraDetails = false;
  final _settingsDb = SettingsDatabase();
  Map<String, dynamic>? _selectedHour;
  Map<String, dynamic>? _selectedHourTomorrow;
  Future? _weatherFuture;
  int _selectedDayIndex = 0;
  late TimeOfDay sunrise;
  late TimeOfDay sunset;


  @override
  void initState() {
    super.initState();
    _loadSettings();
    _weatherFuture = Provider.of<WeatherProvider>(context, listen: false).loadWeather(widget.city);
  }

  Future<void> _loadSettings() async {
    final tempUnit = await _settingsDb.getSetting('temperatureUnit');
    final speedUnit = await _settingsDb.getSetting('speedUnit');
    final lengthUnit = await _settingsDb.getSetting('lengthUnit');
    final extraDetails = await _settingsDb.getSetting('showExtraDetails');

    setState(() {
      _temperatureUnit = tempUnit ?? 'F';
      _speedUnit = speedUnit ?? 'km/h';
      _lengthUnit = lengthUnit ?? 'km/h';
      _showExtraDetails = extraDetails == 'true';
    });
  }

  int selectedDays = 7;
  String selectedMetric = 'temp';
  Map<String, String> get metricLabels {
    String formatTempUnit(String unit) {
      return unit == 'C' ? 'ºC' : 'ºF';
    }

    return {
      'temp': 'Average Temperature (${formatTempUnit(_temperatureUnit)})',
      'tempmax': 'Max Temperature (${formatTempUnit(_temperatureUnit)})',
      'tempmin': 'Min Temperature (${formatTempUnit(_temperatureUnit)})',
      'humidity': 'Humidity (%)',
      'precip': 'Precipitation ($_lengthUnit)',
      'windspeed': 'Wind Speed ($_speedUnit)',
      'pressure': 'Pressure (hPa)',
    };
  }



  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);

      return Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/weather_background.jpg',
              fit: BoxFit.cover,
            ),
          ),

          DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  iconTheme: const IconThemeData(color: Colors.white),
                  title: Text(
                    "Weather in ${widget.city}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 28,
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                          color: Colors.white24,
                        ),
                        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        tabs: [
                          Tab(text: "Today"),
                          Tab(text: "Next Days"),
                          Tab(text: "Week Stats"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            body: FutureBuilder(
              future: _weatherFuture,
              builder: (context, snapshot) {
                final weatherProvider = Provider.of<WeatherProvider>(context);
                if (weatherProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = weatherProvider.currentWeather;
                if (data == null) {
                  return const Center(
                    child: Text(
                      "Failed to load weather data.",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  );
                }

                final tomorrow = weatherProvider.tomorrowWeather;
                if (tomorrow == null) {
                  return const Center(
                    child: Text(
                      "Failed to load weather data.",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  );
                }

                final current = _selectedHour ?? data['currentConditions'];
                //print("current DATA: $current");

                //print("Tomorrow DATA: $tomorrow");
                final hours = tomorrow['days']?[0]?['hours'];
                //print("Hours DATA: $hours");
                if (hours == null || hours is! List) {
                  return const Center(
                    child: Text(
                      "Failed to load hourly weather data.",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  );
                }

                final hourAt1 = (hours as List)
                    .cast<Map<String, dynamic>>()
                    .firstWhere(
                      (hour) => hour['datetime'] == '01:00:00',
                  orElse: () => {},
                );

                final currentTomorrow = _selectedHourTomorrow ?? hourAt1;

                final weekData = weatherProvider.weekWeather;
                if (weekData == null) {
                  return const Center(
                    child: Text(
                      "Failed to load weather data.",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  );
                }
                final pointValues = List.generate(selectedDays, (i) {
                  return (weekData[i][selectedMetric] as num).toDouble();
                }).toSet();

                final selectedDay = (weekData.length > _selectedDayIndex)
                    ? weekData[_selectedDayIndex]
                    : null;


                TimeOfDay parseTimeOfDay(String time) {
                  final parts = time.split(':');
                  return TimeOfDay(
                      hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                }

                if(current['sunrise'] != null){
                  sunrise = parseTimeOfDay(current['sunrise']);
                  sunset = parseTimeOfDay(current['sunset']);
                }


                final alerts = data['alerts'];
                final alertsTomorrow = weekData[0]['alerts'];

                return TabBarView(
                  children: [
                    // TODAY TAB
                    Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Address at the top
                              Text(
                                textAlign: TextAlign.center,
                                data['resolvedAddress'],
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedHour != null
                                    ? "${_selectedHour!['datetime']?.substring(0, 5) ?? '--:--'}"
                                    : "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Weather Card
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: WeatherCard(
                                  current: current,
                                  data: data,
                                  showExtraDetails: _showExtraDetails,
                                  onToggleExtraDetails: (value) {
                                    setState(() {
                                      _showExtraDetails = value;
                                    });
                                  },
                                  temperatureUnit: _temperatureUnit,
                                  speedUnit: _speedUnit,
                                  lengthUnit: _lengthUnit,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Upcoming forecast for today",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white
                                ),
                              ),
                              const SizedBox(height: 4),
                              Builder(
                                builder: (context) {
                                  final now = DateTime.now();
                                  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59);
                                  final hours = data['days']?[0]?['hours'] ?? [];

                                  final upcomingHours = hours.where((hour) {
                                    final timeString = hour['datetime'];
                                    if (timeString == null || timeString is! String) return false;

                                    final parts = timeString.split(":");
                                    if (parts.length < 2) return false;

                                    final hourInt = int.tryParse(parts[0]) ?? 0;
                                    final minuteInt = int.tryParse(parts[1]) ?? 0;

                                    final hourDateTime = DateTime(now.year, now.month, now.day, hourInt, minuteInt);

                                    return hourDateTime.isAfter(now) && hourDateTime.isBefore(endOfToday);
                                  }).toList();

                                  if (upcomingHours.isEmpty) {
                                    return const Text("No upcoming hourly data.");
                                  }
                                  return HourlyForecastRow(
                                    tempUnit: _temperatureUnit,
                                    hours: upcomingHours,
                                    icon: data['days']?[0]?['icon'],

                                    onHourTap: (hourData) {
                                      setState(() {
                                        print("Hour DATA: $hourData");
                                        _selectedHour = hourData;
                                      });
                                    },
                                  );
                                },
                              ),
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
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: alerts == null || alerts.isEmpty
                                    ? Text(
                                  "No alerts at this time. Check later!",
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white
                                  ),
                                )
                                    : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: alerts.map<Widget>((alert) {
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
                              const SizedBox(height: 12),
                              Text(
                                "Sun Path Tracker",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: CustomPaint(
                                  size: Size(double.infinity, 150), // adjust height to match arc size
                                  painter: SunPathPainter(
                                    sunrise,
                                    sunset,
                                    TimeOfDay.now(),
                                    context
                                  ),
                                ),
                              ),
                            ],
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


                    // NEXT DAYS TAB
                    Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (selectedDay == null)
                                const Text("No data available for selected day.", style: TextStyle(color: Colors.white))
                              else ...[
                                Text(
                                  textAlign: TextAlign.center,
                                  data['resolvedAddress'] ?? 'Loading...',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedHourTomorrow != null
                                      ? "${_selectedHourTomorrow!['datetime']?.substring(0, 5) ?? '--:--'}"
                                      : "01:00",
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white24, width: 1),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _selectedDayIndex,
                                      dropdownColor: Colors.white,
                                      style: const TextStyle(color: Colors.lightBlue, fontSize: 16),
                                      iconEnabledColor: Colors.lightBlue,
                                      borderRadius: BorderRadius.circular(10),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedDayIndex = value;
                                            _selectedHourTomorrow = null;
                                          });
                                        }
                                      },
                                      items: List.generate(weekData.length - 1, (index) {
                                        final date = weekData[index + 1]['datetime'];
                                        return DropdownMenuItem(
                                          value: index,
                                          child: Row(
                                            children: [
                                              const Icon(Icons.calendar_today, color: Colors.lightBlue, size: 18),
                                              const SizedBox(width: 20),
                                              Text(
                                                "$date",
                                                style: const TextStyle(
                                                  color: Colors.lightBlue,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Weather Card
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: WeatherCard(
                                    current: currentTomorrow,
                                    data: {'days': [selectedDay]},
                                    showExtraDetails: _showExtraDetails,
                                    onToggleExtraDetails: (value) {
                                      setState(() {
                                        _showExtraDetails = value;
                                      });
                                    },
                                    temperatureUnit: _temperatureUnit,
                                    speedUnit: _speedUnit,
                                    lengthUnit: _lengthUnit,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  textAlign: TextAlign.center,
                                  "Upcoming forecast for selected day",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                                const SizedBox(height: 4),

                                Builder(
                                  builder: (context) {
                                    final dateParts = (selectedDay['datetime'] as String).split('-');
                                    final year = int.tryParse(dateParts[0]) ?? 0;
                                    final month = int.tryParse(dateParts[1]) ?? 1;
                                    final day = int.tryParse(dateParts[2]) ?? 1;

                                    final startOfDay = DateTime(year, month, day, 0, 0);
                                    final endOfDay = DateTime(year, month, day, 23, 59);

                                    final hours = selectedDay['hours'] ?? [];

                                    final upcomingHours = hours.where((hour) {
                                      final timeString = hour['datetime'];
                                      if (timeString == null || timeString is! String) return false;

                                      final parts = timeString.split(":");
                                      if (parts.length < 2) return false;

                                      final hourInt = int.tryParse(parts[0]) ?? 0;
                                      final minuteInt = int.tryParse(parts[1]) ?? 0;

                                      final hourDateTime = DateTime(year, month, day, hourInt, minuteInt);

                                      return hourDateTime.isAfter(startOfDay) && hourDateTime.isBefore(endOfDay);
                                    }).toList();

                                    if (upcomingHours.isEmpty) {
                                      return const Text("No upcoming hourly data.", style: TextStyle(color: Colors.white));
                                    }

                                    return HourlyForecastRow(
                                      tempUnit: _temperatureUnit,
                                      hours: upcomingHours,
                                      icon: selectedDay['icon'],
                                      onHourTap: (hourData) {
                                        setState(() {
                                          _selectedHourTomorrow = hourData;
                                        });
                                      },
                                    );
                                  },
                                ),
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
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white30),
                                  ),
                                  child: alertsTomorrow == null || alertsTomorrow.isEmpty
                                      ? Text(
                                    "No alerts at this time. Check later!",
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white
                                    ),
                                  )
                                      : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: alertsTomorrow.map<Widget>((alert) {
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
                              ]
                            ],
                          ),
                        ),
                        if (_selectedHourTomorrow != null)
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedHourTomorrow = null;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "You reset the time to 01:00!",
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
                                "Reset to hour 01:00",
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


                    // WEEK STATS TAB
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Address at the top
                          Text(
                            textAlign: TextAlign.center,
                            data['resolvedAddress'] ?? 'Loading...',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Days dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: selectedDays,
                                dropdownColor: Colors.white,
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.lightBlue),
                                style: const TextStyle(color: Colors.lightBlue, fontSize: 16, fontWeight: FontWeight.w500),
                                borderRadius: BorderRadius.circular(10),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => selectedDays = value);
                                  }
                                },
                                items: List.generate(7, (index) {
                                  final d = index + 1;
                                  return DropdownMenuItem(
                                    value: d,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.timelapse, color: Colors.lightBlue, size: 18),
                                        const SizedBox(width: 20),
                                        Text(
                                          '$d day${d > 1 ? "s" : ""}',
                                          style: const TextStyle(
                                            color: Colors.lightBlue,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Metric dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedMetric,
                                dropdownColor: Colors.white,
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.lightBlue),
                                style: const TextStyle(color: Colors.lightBlue, fontSize: 16, fontWeight: FontWeight.w500),
                                borderRadius: BorderRadius.circular(10),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => selectedMetric = value);
                                  }
                                },
                                items: metricLabels.entries.map((entry) {
                                  return DropdownMenuItem(
                                    value: entry.key,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.show_chart, color: Colors.lightBlue, size: 18),
                                        const SizedBox(width: 20),
                                        Text(
                                          entry.value,
                                          style: const TextStyle(
                                            color: Colors.lightBlue,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (weekData == null)
                            const Center(child: CircularProgressIndicator())
                          else if (weekData.length < selectedDays)
                            Text(
                              "Only ${weekData.length} days of data available.",
                              style: const TextStyle(color: Colors.white),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 0),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: SizedBox(
                                  height: 250,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: LineChart(
                                      LineChartData(
                                        backgroundColor: Colors.transparent,
                                        gridData: FlGridData(show: false),
                                        titlesData: FlTitlesData(
                                          rightTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 40,
                                              interval: 0.1,
                                                getTitlesWidget: (value, _) {
                                                  const epsilon = 0.05;
                                    
                                                  final isMatch = pointValues.any((point) => (point - value).abs() < epsilon);
                                    
                                                  if (!isMatch) return const SizedBox.shrink();
                                    
                                                  String formatted;
                                                  if (selectedMetric.contains("temp")) {
                                                    formatted = formatTemp(_temperatureUnit, value);
                                                  } else if (selectedMetric == "windspeed") {
                                                    formatted = formatSpeed(_speedUnit, value);
                                                  } else if (selectedMetric == "precip") {
                                                    formatted = formatLength(_lengthUnit, value);
                                                  } else if (selectedMetric == "humidity") {
                                                    formatted = "${value.toStringAsFixed(0)} %";
                                                  } else if (selectedMetric == "pressure") {
                                                    formatted = "${value.toStringAsFixed(0)} hPa";
                                                  } else {
                                                    formatted = value.toStringAsFixed(1);
                                                  }
                                    
                                                  return Text(
                                                    formatted,
                                                    style: const TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 10,
                                                      letterSpacing: 0.3,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  );
                                                }
                                    
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              interval: 1,
                                              getTitlesWidget: (value, _) {
                                                int index = value.toInt();
                                                if (index >= 0 && index < selectedDays) {
                                                  final date = weekData[index]['datetime'];
                                                  return Text(
                                                    date.substring(5),
                                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                                  );
                                                }
                                                return const Text('');
                                              },
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          topTitles: AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                        ),
                                        borderData: FlBorderData(
                                          show: true,
                                          border: const Border(
                                            bottom: BorderSide(color: Colors.white24),
                                            left: BorderSide(color: Colors.white24),
                                            right: BorderSide.none,
                                            top: BorderSide.none,
                                          ),
                                        ),
                                        lineBarsData: [
                                          LineChartBarData(
                                            isCurved: false,
                                            barWidth: 2,
                                            color: Colors.cyanAccent,
                                            dotData: FlDotData(show: true),
                                            spots: List.generate(selectedDays, (i) {
                                              final day = weekData[i];
                                              final value = (day[selectedMetric] as num?)?.toDouble() ?? 0;
                                              return FlSpot(i.toDouble(), value);
                                            }),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
