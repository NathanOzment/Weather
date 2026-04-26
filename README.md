# WeatherNow

WeatherNow is a native SwiftUI weather app for iPhone with a polished forecast dashboard, saved-city workflows, onboarding, search suggestions, and a radar-inspired map screen.

![WeatherNow launch art](WeatherNow/Assets.xcassets/LaunchArtwork.imageset/LaunchArtwork.png)

## Screenshots

![WeatherNow home screen](docs/weather-home.png)

## What’s inside

- Current conditions with dynamic styling based on weather state.
- Saved cities with local caching and last-view restore.
- City search with recent searches and live suggestion results.
- A dedicated map tab for comparing tracked cities spatially.
- Onboarding that can preload a starter city and preferred units.
- A branded app icon and custom launch screen artwork.

## Tech stack

- SwiftUI for the interface and app flow.
- MapKit for the map experience.
- Core Location for local-weather lookup.
- Open-Meteo for forecast and geocoding data.
- UserDefaults-backed persistence for saved cities, units, recents, and cached snapshots.

## Getting started

1. Open `WeatherNow.xcodeproj` in Xcode.
2. Select the `WeatherNow` scheme and an iPhone simulator or device.
3. Choose your Apple Development Team if you want to run on hardware.
4. Build and run.

No API key is required for the current version.

## Project structure

- `WeatherNow/Views` contains the main screens, including `HomeView`, `WeatherMapView`, `SavedLocationsView`, `SettingsView`, and `OnboardingView`.
- `WeatherNow/Views/Components` contains reusable forecast cards and branded UI pieces.
- `WeatherNow/Models` contains weather models and the `WeatherStore`.
- `WeatherNow/Services` contains the forecast, geocoding, and location integrations.

## Current highlights

- `Today` focuses on the active forecast with richer detail cards and hourly/daily sections.
- `Map` presents a radar-inspired comparison of the active city and saved locations.
- `Saved` opens cached forecasts fast and refreshes them in the background.
- `Settings` handles units, refresh, onboarding reset, and saved-city cleanup.

## Next ideas

- Real precipitation radar tiles.
- Weather alerts and severe-condition banners.
- Widgets and App Intents shortcuts.
- Additional screenshot coverage for the map and onboarding flows.
