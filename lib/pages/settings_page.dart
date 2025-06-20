import 'package:flutter/material.dart';
import 'package:weather_app/db/settings_database.dart';

// Class to handle the settings page
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

// Class to handle the settings page state
class _SettingsPageState extends State<SettingsPage> {
  String _temperatureUnit = 'C';
  String _lengthUnit = 'mm';
  String _speedUnit = 'km/h';
  bool _showExtraDetails = true;

  final _settingsDb = SettingsDatabase();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final temperatureUnit = await _settingsDb.getSetting('temperatureUnit');
    final speedUnit = await _settingsDb.getSetting('speedUnit');
    final lengthUnit = await _settingsDb.getSetting('lengthUnit');
    final details = await _settingsDb.getSetting('showExtraDetails');

    setState(() {
      _temperatureUnit = temperatureUnit ?? 'C';
      _speedUnit = speedUnit ?? 'km/h';
      _lengthUnit = lengthUnit ?? 'mm';
      _showExtraDetails = details == 'true';
    });
  }

  Future<void> _saveSettings() async {
    await _settingsDb.setSetting('temperatureUnit', _temperatureUnit);
    await _settingsDb.setSetting('speedUnit', _speedUnit);
    await _settingsDb.setSetting('lengthUnit', _lengthUnit);
    await _settingsDb.setSetting('showExtraDetails', _showExtraDetails.toString());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Settings saved")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Preferences",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildSettingCard(
            title: "Temperature Unit",
            subtitle: "Choose between Celsius or Fahrenheit",
            dropdownValue: _temperatureUnit,
            options: const {
              'C': 'Celsius (°C)',
              'F': 'Fahrenheit (°F)',
            },
            onChanged: (val) => setState(() => _temperatureUnit = val),
          ),

          _buildSettingCard(
            title: "Length Unit",
            subtitle: "Choose between Millimeters or Inches",
            dropdownValue: _lengthUnit,
            options: const {
              'mm': 'Millimeters (mm)',
              'in': 'Inches (in)',
            },
            onChanged: (val) => setState(() => _lengthUnit = val),
          ),

          _buildSettingCard(
            title: "Speed Unit",
            subtitle: "Choose between Km/H or MpH",
            dropdownValue: _speedUnit,
            options: const {
              'km/h': 'Km/H',
              'mph': 'MpH',
            },
            onChanged: (val) => setState(() => _speedUnit = val),
          ),

          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: SwitchListTile(
              title: const Text("Show Extra Weather Details"),
              value: _showExtraDetails,
              onChanged: (value) {
                setState(() => _showExtraDetails = value);
              },
              activeColor: Colors.blueGrey,
              activeTrackColor: Colors.blue.shade100,
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save, color: Colors.blueGrey),
              label: const Text("Save Settings"),
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
                foregroundColor: Colors.blueGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required String dropdownValue,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: DropdownButton<String>(
          value: dropdownValue,
          items: options.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}
