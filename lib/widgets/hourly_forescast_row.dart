import 'package:flutter/material.dart';
import 'package:weather_app/utils.dart';

// Class to handle the hourly forecast row
class HourlyForecastRow extends StatelessWidget {
  final List<dynamic> hours;
  final String tempUnit;
  final String? icon;
  final Function(Map<String, dynamic>)? onHourTap;

  const HourlyForecastRow({
    super.key,
    required this.tempUnit,
    required this.hours,
    required this.icon,
    this.onHourTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: hours.map((hourData) {
          final temp = formatTemp(tempUnit, hourData['temp'] ?? 0.0);
          final time = hourData['datetime'].toString().substring(0, 5);

          return GestureDetector(
            onTap: () {
              if (onHourTap != null) {
                onHourTap!(hourData);
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/icons/$icon.png', width: 28, height: 28),
                      const SizedBox(height: 4),
                      Text(temp, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
