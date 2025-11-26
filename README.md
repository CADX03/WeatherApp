# Weather App

A cross-platform Flutter application that shows current and forecasted weather information for cities around the world.

This project pulls weather timelines using the VisualCrossing Weather API and stores user preferences and saved cities locally using SQLite.

---

## Features

- Current weather and hourly forecasts
- View tomorrow and upcoming days
- Saved cities (persisted via SQLite)
- Settings for temperature, speed, length units and extra details
- Hourly and weekly chart visualization (`fl_chart`)
- Autocomplete search using an included `assets/cities.csv` file
- Uses provider state management, geolocation, and a clean, modern UI

---

## Tech Stack

- Flutter (Dart SDK >= 3.6.2)
- Provider for state management
- SQLite via `sqflite` for persistence
- VisualCrossing Weather API
- Additional packages: `http`, `csv`, `geolocator`, `geocoding`, `fl_chart`, etc.

---

## Project Structure

- `lib/`
	- `main.dart` — App entry point
	- `pages/` — UI pages (settings, details)
	- `provider/` — `weather_provider.dart`, `city_provider.dart`
	- `services/` — `weather_service.dart` (API calls)
	- `db/` — `settings_database.dart`, `city_database.dart` (persistence)
	- `widgets/` — Reusable UI components
	- `assets/` — Icons, images, and `cities.csv`

---

## Prerequisites

- Install Flutter: https://docs.flutter.dev/get-started/install
- Set up Android SDK / Xcode for target platforms
- Ensure `flutter` is available in your PATH

Verify environment:

```powershell
flutter --version
flutter doctor -v
flutter devices
```

---

## Setup & Running

1. Fetch dependencies:

```powershell
flutter pub get
```

2. Run on a connected device or emulator:

```powershell
flutter run -d <deviceId>
```

3. To build a release APK for Android:

```powershell
flutter build apk --release
```

---

## Configuration & API Key

- The app uses the VisualCrossing API. A (test) API key is present in `lib/services/weather_service.dart`.

- For production, replace the API key with your own. To keep keys secure, adopt one of these approaches:
	- Use a `.env` file and `flutter_dotenv` (and make sure `.env` is in `.gitignore`)
	- Load keys from platform-specific secure storage or CI secrets

## Assets

- `assets/cities.csv` — used for the Autocomplete list when searching for a city
- Font family: Montserrat
- Background images and icons located in `assets/images/` and `assets/icons/`

---

## Tests

Run unit and widget tests with:

```powershell
flutter test
```

---

## Contributing

Feel free to open issues or submit pull requests. Suggested workflow:

1. Fork the repo
2. Create a branch (`git checkout -b feat/my-feature`)
3. Commit changes and run tests
4. Create a PR with a clear description and any testing notes

---

## Security & Considerations

- API key is hard-coded in `lib/services/weather_service.dart` — consider moving to secure env/config
- Add more error handling for offline scenarios and API failures
- Add CI checks and more tests

---

## License

The repo currently does not contain a license file. Add an appropriate `LICENSE` file (e.g., MIT, Apache 2.0) if you plan to release this project publicly.
