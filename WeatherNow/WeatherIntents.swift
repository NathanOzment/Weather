import AppIntents
import Foundation

struct SavedCityEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Saved City")
    static var defaultQuery = SavedCityQuery()

    let id: String

    var name: String { id }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(id)")
    }
}

struct SavedCityQuery: EntityStringQuery {
    func entities(for identifiers: [SavedCityEntity.ID]) async throws -> [SavedCityEntity] {
        loadSavedCities()
            .filter { identifiers.contains($0) }
            .map { SavedCityEntity(id: $0) }
    }

    func entities(matching string: String) async throws -> [SavedCityEntity] {
        loadSavedCities()
            .filter { $0.localizedCaseInsensitiveContains(string) }
            .map { SavedCityEntity(id: $0) }
    }

    func suggestedEntities() async throws -> [SavedCityEntity] {
        loadSavedCities().map { SavedCityEntity(id: $0) }
    }

    private func loadSavedCities() -> [String] {
        UserDefaults.standard.stringArray(forKey: "savedCities") ?? []
    }
}

struct OpenSavedCityIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Saved City Forecast"
    static var description = IntentDescription("Open one of your saved cities in WeatherNow.")

    @Parameter(title: "City")
    var city: SavedCityEntity

    init() {}

    init(city: SavedCityEntity) {
        self.city = city
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        WeatherIntentCoordinator.queue(.openSavedCity(cityName: city.name))
        return .result(dialog: "Opening \(city.name) in WeatherNow.")
    }
}

struct RefreshCurrentForecastIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Current Forecast"
    static var description = IntentDescription("Refresh the current location forecast in WeatherNow.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        WeatherIntentCoordinator.queue(.refreshCurrentForecast)
        return .result(dialog: "Refreshing your current forecast in WeatherNow.")
    }
}

struct RefreshSavedCitiesIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Saved Cities"
    static var description = IntentDescription("Refresh cached weather for your saved cities in WeatherNow.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        WeatherIntentCoordinator.queue(.refreshSavedCities)
        let savedCities = UserDefaults.standard.stringArray(forKey: "savedCities") ?? []
        let message = savedCities.isEmpty
            ? "WeatherNow will open, but you do not have any saved cities yet."
            : "Refreshing \(savedCities.count) saved \(savedCities.count == 1 ? "city" : "cities") in WeatherNow."
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

struct WeatherNowShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .blue

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenSavedCityIntent(),
            phrases: [
                "Open \(\.$city) in \(.applicationName)",
                "Show \(\.$city) weather in \(.applicationName)"
            ],
            shortTitle: "Open Saved City",
            systemImageName: "star.circle.fill"
        )

        AppShortcut(
            intent: RefreshCurrentForecastIntent(),
            phrases: [
                "Refresh my weather in \(.applicationName)",
                "Update current forecast in \(.applicationName)"
            ],
            shortTitle: "Refresh Current",
            systemImageName: "location.circle.fill"
        )

        AppShortcut(
            intent: RefreshSavedCitiesIntent(),
            phrases: [
                "Refresh saved cities in \(.applicationName)",
                "Update saved forecasts in \(.applicationName)"
            ],
            shortTitle: "Refresh Saved",
            systemImageName: "arrow.clockwise.circle.fill"
        )
    }
}

enum WeatherIntentActionKind: String, Codable {
    case openSavedCity
    case refreshCurrentForecast
    case refreshSavedCities
}

struct WeatherIntentAction: Codable {
    let kind: WeatherIntentActionKind
    let cityName: String?

    static let refreshCurrentForecast = WeatherIntentAction(kind: .refreshCurrentForecast, cityName: nil)
    static let refreshSavedCities = WeatherIntentAction(kind: .refreshSavedCities, cityName: nil)

    static func openSavedCity(cityName: String) -> WeatherIntentAction {
        WeatherIntentAction(kind: .openSavedCity, cityName: cityName)
    }
}

enum WeatherIntentCoordinator {
    private static let pendingActionKey = "pendingWeatherIntentAction"

    static func queue(_ action: WeatherIntentAction) {
        guard let data = try? JSONEncoder().encode(action) else { return }
        UserDefaults.standard.set(data, forKey: pendingActionKey)
    }

    static func consumePendingAction() -> WeatherIntentAction? {
        guard
            let data = UserDefaults.standard.data(forKey: pendingActionKey),
            let action = try? JSONDecoder().decode(WeatherIntentAction.self, from: data)
        else {
            return nil
        }

        UserDefaults.standard.removeObject(forKey: pendingActionKey)
        return action
    }
}

@available(*, deprecated)
extension OpenSavedCityIntent {
    static var openAppWhenRun: Bool { true }
}

@available(*, deprecated)
extension RefreshCurrentForecastIntent {
    static var openAppWhenRun: Bool { true }
}

@available(*, deprecated)
extension RefreshSavedCitiesIntent {
    static var openAppWhenRun: Bool { true }
}
