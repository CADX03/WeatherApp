import 'package:flutter/material.dart';
import 'weather_info_tile.dart';
import 'info_row.dart';
import 'package:weather_app/utils.dart';

// Class to handle the weather card
class WeatherCard extends StatelessWidget {
  final Map<String, dynamic> current;
  final Map<String, dynamic> data;
  final bool showExtraDetails;
  final void Function(bool) onToggleExtraDetails;
  final String temperatureUnit;
  final String speedUnit;
  final String lengthUnit;

  const WeatherCard({
    super.key,
    required this.current,
    required this.data,
    required this.showExtraDetails,
    required this.onToggleExtraDetails,
    required this.temperatureUnit,
    required this.speedUnit,
    required this.lengthUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/icons/${data['days']?[0]?['icon']}.png',
                        width: 84,
                        height: 84,
                      ),
                      Text(
                        current['conditions'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 24, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            formatTemp(temperatureUnit, data['days']?[0]?['tempmax'] ?? 0.0),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.arrow_downward, size: 24, color: Colors.blueAccent),
                          const SizedBox(width: 4),
                          Text(
                            formatTemp(temperatureUnit, data['days']?[0]?['tempmin'] ?? 0.0),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      formatTemp(temperatureUnit, current['temp']),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Card(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: WeatherInfoTile(
                        icon: Icons.air,
                        label: "Wind",
                        value: formatSpeed(speedUnit, current['windspeed'] ?? 0.0),
                      ),
                    ),
                    Expanded(
                      child: WeatherInfoTile(
                        icon: Icons.water_drop_outlined,
                        label: "Humidity",
                        value: "${current['humidity']}%",
                      ),
                    ),
                    Expanded(
                      child: WeatherInfoTile(
                        icon: Icons.umbrella_outlined,
                        label: "Rain",
                        value: "${current['precipprob']?.toStringAsFixed(0) ?? 'N/A'}%",
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Show more info",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: showExtraDetails,
                  onChanged: onToggleExtraDetails,
                  activeColor: Colors.blueAccent,
                  activeTrackColor: Colors.blue.shade100,
                ),
              ],
            ),
            if (showExtraDetails)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (current['tempmax'] != null)
                      InfoRow(icon: Icons.thermostat, label: "Feels Like", value: formatTemp(temperatureUnit, current['tempmax'])),
                    if (current['dew'] != null)
                      InfoRow(icon: Icons.grain, label: "Dew Point", value: formatTemp(temperatureUnit, current['dew'])),
                    if (current['precip'] != null)
                      InfoRow(icon: Icons.water_drop, label: "Precipitation", value: formatLength(lengthUnit, current['precip'])),
                    if (current['windgust'] != null)
                      InfoRow(icon: Icons.air, label: "Wind Gust", value: formatSpeed(speedUnit, current['windgust'])),
                    if (current['winddir'] != null)
                      InfoRow(icon: Icons.explore, label: "Wind Dir", value: "${current['winddir']}°"),
                    if (current['cloudcover'] != null)
                      InfoRow(icon: Icons.cloud, label: "Cloud Cover", value: "${current['cloudcover']}%"),
                    if (current['visibility'] != null)
                      InfoRow(icon: Icons.visibility, label: "Visibility", value: "${current['visibility']} mi"),
                    if (current['solarradiation'] != null)
                      InfoRow(icon: Icons.brightness_5, label: "Solar Radiation", value: "${current['solarradiation']} W/m²"),
                    if (current['uvindex'] != null)
                      InfoRow(icon: Icons.wb_sunny, label: "UV Index", value: "${current['uvindex']}"),
                    if (current['sunrise'] != null)
                      InfoRow(icon: Icons.wb_twilight, label: "Sunrise", value: "${current['sunrise']}"),
                    if (current['sunset'] != null)
                      InfoRow(icon: Icons.nights_stay, label: "Sunset", value: "${current['sunset']}"),
                    if (current['moonphase'] != null)
                      InfoRow(icon: Icons.dark_mode, label: "Moon Phase", value: "${current['moonphase']}"),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
