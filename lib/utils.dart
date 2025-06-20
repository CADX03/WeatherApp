// Function to format temperature based on the selected unit
String formatTemp(String unit, double temp) {
  if (unit == 'C') {
    final celsius = (temp - 32) * 5 / 9;
    return "${celsius.toStringAsFixed(1)} °C";
  } else {
    return "${temp.toStringAsFixed(1)} ºF";
  }
}

// Function to format speed based on the selected unit
String formatSpeed(String unit, double speed) {
  if (unit == 'mph') {
    final mph = speed / 1.60934;
    return "${mph.toStringAsFixed(1)} mph";
  } else {
    return "${speed.toStringAsFixed(1)} km/h";
  }
}

// Function to format length based on the selected unit
String formatLength(String unit, double length) {
  if (unit == 'in') {
    final inches = length / 25.4;
    return "${inches.toStringAsFixed(1)} in";
  } else {
    return "${length.toStringAsFixed(1)} mm";
  }
}