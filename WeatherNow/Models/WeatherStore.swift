import Combine
import Foundation

@MainActor
final class WeatherStore: ObservableObject {
    @Published var snapshot: WeatherSnapshot?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    @Published var recentSearches: [String]
    @Published var suggestions: [CitySuggestion] = []
    @Published var isFetchingSuggestions = false
    @Published var hasCompletedOnboarding: Bool
    @Published var lastResolvedLocation = "Current Location"
    @Published var savedCities: [String]
    @Published var temperatureUnit: TemperatureUnit
    @Published var showingSavedOnly = false

    var activeCityName: String? {
        snapshot?.cityName
    }

    private let weatherService: WeatherService
    private let locationService: LocationService
    private let defaults: UserDefaults
    private let savedCitiesKey = "savedCities"
    private let recentSearchesKey = "recentSearches"
    private let temperatureUnitKey = "temperatureUnit"
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    private let lastViewedCityKey = "lastViewedCity"
    private let cachedSnapshotsKey = "cachedSnapshots"
    private var cachedSnapshots: [String: WeatherSnapshot]
    private var suggestionTask: Task<Void, Never>?

    init(
        weatherService: WeatherService = WeatherService(),
        locationService: LocationService? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.weatherService = weatherService
        self.locationService = locationService ?? LocationService()
        self.defaults = defaults
        self.savedCities = defaults.stringArray(forKey: savedCitiesKey) ?? []
        self.recentSearches = defaults.stringArray(forKey: recentSearchesKey) ?? []
        self.hasCompletedOnboarding = defaults.object(forKey: hasCompletedOnboardingKey) as? Bool ?? false
        self.cachedSnapshots = Self.decodeSnapshots(from: defaults.data(forKey: cachedSnapshotsKey))
        if
            let storedUnit = defaults.string(forKey: temperatureUnitKey),
            let unit = TemperatureUnit(rawValue: storedUnit)
        {
            self.temperatureUnit = unit
        } else {
            self.temperatureUnit = .fahrenheit
        }
    }

    func load() async {
        guard snapshot == nil, !isLoading else { return }
        if restoreLastViewedSnapshot() {
            return
        }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil

        do {
            let coordinates = try await locationService.requestCurrentLocation()
            let weather = try await weatherService.fetchWeather(for: coordinates)
            applySnapshot(weather, showingSavedOnly: false)
        } catch {
            if snapshot == nil {
                snapshot = WeatherSamples.snapshot
            }
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func searchCity() async {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let coordinates = try await weatherService.geocode(city: trimmedQuery)
            let weather = try await weatherService.fetchWeather(for: coordinates, preferredName: trimmedQuery)
            applySnapshot(weather, showingSavedOnly: true)
            recordRecentSearch(weather.cityName)
            suggestions = []
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func selectSuggestion(_ suggestion: CitySuggestion) async {
        isLoading = true
        errorMessage = nil

        do {
            let weather = try await weatherService.fetchWeather(for: suggestion.coordinates, preferredName: suggestion.name)
            applySnapshot(weather, showingSavedOnly: true)
            recordRecentSearch(weather.cityName)
            suggestions = []
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadSavedCity(_ city: String) async {
        if let cached = cachedSnapshot(for: city) {
            applySnapshot(cached, showingSavedOnly: true)
        }
        searchQuery = city
        await searchCity()
    }

    func addCurrentCityToSaved() {
        guard let city = snapshot?.cityName else { return }
        guard !savedCities.contains(city) else { return }
        savedCities.insert(city, at: 0)
        persistSavedCities()
    }

    func removeSavedCity(_ city: String) {
        savedCities.removeAll { $0 == city }
        persistSavedCities()
    }

    func clearSavedCities() {
        savedCities.removeAll()
        cachedSnapshots = cachedSnapshots.filter { $0.key == activeCityName }
        persistCachedSnapshots()
        persistSavedCities()
    }

    func updateTemperatureUnit(_ unit: TemperatureUnit) {
        temperatureUnit = unit
        defaults.set(unit.rawValue, forKey: temperatureUnitKey)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        defaults.set(true, forKey: hasCompletedOnboardingKey)
    }

    func completeOnboarding(preferredUnit: TemperatureUnit, starterCity: String?) async {
        updateTemperatureUnit(preferredUnit)

        if let starterCity, !starterCity.isEmpty {
            searchQuery = starterCity
            await searchCity()
        }

        completeOnboarding()
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        defaults.set(false, forKey: hasCompletedOnboardingKey)
    }

    func cachedSnapshot(for city: String) -> WeatherSnapshot? {
        cachedSnapshots[city]
    }

    func cachedUpdatedText(for city: String) -> String? {
        guard let snapshot = cachedSnapshots[city] else { return nil }
        return "Updated \(snapshot.updatedAt.formatted(date: .abbreviated, time: .shortened))"
    }

    func refreshSuggestions() {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        suggestionTask?.cancel()

        guard !trimmedQuery.isEmpty else {
            suggestions = []
            isFetchingSuggestions = false
            return
        }

        let localMatches = Array((recentSearches + savedCities)
            .uniqued()
            .filter { $0.localizedCaseInsensitiveContains(trimmedQuery) }
            .prefix(5))

        if trimmedQuery.count < 2 {
            suggestions = localMatches.map {
                CitySuggestion(
                    id: "recent-\($0)",
                    name: $0,
                    subtitle: "Recent search",
                    coordinates: cachedSnapshots[$0].map { Coordinates(latitude: $0.latitude, longitude: $0.longitude) } ?? .chicago
                )
            }
            return
        }

        suggestionTask = Task { @MainActor in
            isFetchingSuggestions = true
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }

            do {
                let remote = try await weatherService.searchSuggestions(for: trimmedQuery)
                guard !Task.isCancelled else { return }
                let merged = merge(localMatches: localMatches, remote: remote)
                suggestions = merged
            } catch {
                suggestions = localMatches.map {
                    CitySuggestion(
                        id: "recent-\($0)",
                        name: $0,
                        subtitle: "Recent search",
                        coordinates: cachedSnapshots[$0].map { Coordinates(latitude: $0.latitude, longitude: $0.longitude) } ?? .chicago
                    )
                }
            }
            isFetchingSuggestions = false
        }
    }

    private func persistSavedCities() {
        defaults.set(savedCities, forKey: savedCitiesKey)
    }

    private func persistRecentSearches() {
        defaults.set(recentSearches, forKey: recentSearchesKey)
    }

    private func applySnapshot(_ weather: WeatherSnapshot, showingSavedOnly: Bool) {
        snapshot = weather
        lastResolvedLocation = weather.cityName
        searchQuery = weather.cityName
        self.showingSavedOnly = showingSavedOnly
        cachedSnapshots[weather.cityName] = weather
        defaults.set(weather.cityName, forKey: lastViewedCityKey)
        persistCachedSnapshots()
    }

    private func recordRecentSearch(_ city: String) {
        recentSearches.removeAll { $0.caseInsensitiveCompare(city) == .orderedSame }
        recentSearches.insert(city, at: 0)
        recentSearches = Array(recentSearches.prefix(8))
        persistRecentSearches()
    }

    private func merge(localMatches: [String], remote: [CitySuggestion]) -> [CitySuggestion] {
        let localSuggestions = localMatches.map {
            CitySuggestion(
                id: "recent-\($0)",
                name: $0,
                subtitle: savedCities.contains($0) ? "Saved city" : "Recent search",
                coordinates: cachedSnapshots[$0].map { Coordinates(latitude: $0.latitude, longitude: $0.longitude) } ?? .chicago
            )
        }

        var seen = Set(localSuggestions.map { $0.name.lowercased() })
        var result = localSuggestions
        for suggestion in remote where !seen.contains(suggestion.name.lowercased()) {
            result.append(suggestion)
            seen.insert(suggestion.name.lowercased())
        }
        return Array(result.prefix(6))
    }

    private func restoreLastViewedSnapshot() -> Bool {
        guard
            let city = defaults.string(forKey: lastViewedCityKey),
            let cached = cachedSnapshots[city]
        else {
            return false
        }

        snapshot = cached
        lastResolvedLocation = cached.cityName
        searchQuery = cached.cityName
        showingSavedOnly = savedCities.contains(cached.cityName)
        return true
    }

    private func persistCachedSnapshots() {
        if let data = try? JSONEncoder().encode(cachedSnapshots) {
            defaults.set(data, forKey: cachedSnapshotsKey)
        }
    }

    private static func decodeSnapshots(from data: Data?) -> [String: WeatherSnapshot] {
        guard
            let data,
            let decoded = try? JSONDecoder().decode([String: WeatherSnapshot].self, from: data)
        else {
            return [:]
        }

        return decoded
    }
}

private extension Array where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0.lowercased()).inserted }
    }
}
