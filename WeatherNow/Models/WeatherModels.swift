import CoreLocation
import Foundation

struct WeatherSnapshot: Equatable, Codable {
    let cityName: String
    let latitude: Double
    let longitude: Double
    let updatedAt: Date
    let current: CurrentConditions
    let airQuality: AirQuality
    let hourly: [HourlyForecast]
    let daily: [DailyForecast]
}

extension WeatherSnapshot {
    var freshnessText: String {
        let elapsedMinutes = max(Int(Date().timeIntervalSince(updatedAt) / 60), 0)

        switch elapsedMinutes {
        case ..<2:
            return "Updated just now"
        case ..<60:
            return "Updated \(elapsedMinutes)m ago"
        case ..<180:
            return "Updated \(elapsedMinutes / 60)h ago"
        default:
            return "Updated \(updatedAt.formatted(date: .abbreviated, time: .shortened))"
        }
    }

    var isStale: Bool {
        Date().timeIntervalSince(updatedAt) > 60 * 90
    }

    var vibeTitle: String {
        switch (current.condition, vibeTimeWindow) {
        case (.clear, .dawn), (.clear, .morning):
            "Golden-hour energy"
        case (.clear, .afternoon):
            "Sunlit momentum"
        case (.clear, .evening), (.clear, .night):
            "Clear-sky reset"
        case (.partlyCloudy, _):
            "Soft-light mood"
        case (.cloudy, _):
            "Low-key sky"
        case (.rain, _):
            "Rain soundtrack"
        case (.storm, _):
            "Big-weather energy"
        case (.snow, _):
            "Snow-globe mood"
        case (.fog, _):
            "Dream-sequence air"
        }
    }

    var vibeSubtitle: String {
        switch current.condition {
        case .clear:
            "Bright, open air with the kind of clarity that makes the whole day feel lighter."
        case .partlyCloudy:
            "A little sky texture keeps things cinematic without losing the easygoing feel."
        case .cloudy:
            "Muted light, softer contrast, and a slower outside rhythm."
        case .rain:
            "Cooler air, quieter streets, and clear umbrella-core energy."
        case .storm:
            "The dramatic version of weather. Best enjoyed with a roof above you."
        case .snow:
            "Bundled-up brightness with that extra hush snow brings to everything."
        case .fog:
            "Close horizons, soft edges, and real moody-depth weather."
        }
    }

    var vibeTags: [String] {
        var tags: [String] = []

        switch current.condition {
        case .clear:
            tags.append(vibeTimeWindow == .evening ? "blue-hour glow" : "clear view")
        case .partlyCloudy:
            tags.append("soft contrast")
        case .cloudy:
            tags.append("muted light")
        case .rain:
            tags.append("umbrella ready")
        case .storm:
            tags.append("indoor plans")
        case .snow:
            tags.append("bundle up")
        case .fog:
            tags.append("moody depth")
        }

        if current.apparentTemperature <= 9 {
            tags.append("hoodie weather")
        } else if current.apparentTemperature >= 28 {
            tags.append("warm air")
        } else {
            tags.append("easy layers")
        }

        if current.windSpeed >= 28 {
            tags.append("windy edge")
        } else if current.windSpeed <= 12 {
            tags.append("easy walk")
        }

        if current.uvIndex >= 6 {
            tags.append("bright light")
        }

        return deduplicated(tags)
    }

    var primaryVibeTag: String? {
        vibeTags.first
    }

    var alerts: [WeatherAlert] {
        var results: [WeatherAlert] = []

        let highestPrecipitationChance = hourly.map(\.precipitationChance).max() ?? daily.first?.precipitationChance ?? 0
        let hasStormRisk = current.condition == .storm || hourly.contains(where: { $0.condition == .storm })
        let apparentTemperature = current.apparentTemperature

        if hasStormRisk || highestPrecipitationChance >= 80 {
            results.append(
                WeatherAlert(
                    id: "storm",
                    title: hasStormRisk ? "Storm Alert" : "Heavy Rain Alert",
                    message: hasStormRisk
                        ? "Storm conditions are active or approaching, so outdoor plans may need to pause."
                        : "Rain chances are high enough that a backup indoor plan is a smart call today.",
                    symbol: hasStormRisk ? "cloud.bolt.rain.fill" : "cloud.heavyrain.fill",
                    level: hasStormRisk ? .severe : .warning
                )
            )
        }

        if apparentTemperature >= 38 || current.temperature >= 34 {
            results.append(
                WeatherAlert(
                    id: "heat",
                    title: "Heat Advisory",
                    message: "Hot conditions can wear you down quickly. Water, shade, and lighter activity will help.",
                    symbol: "thermometer.sun.fill",
                    level: apparentTemperature >= 42 ? .severe : .warning
                )
            )
        } else if apparentTemperature <= -5 || current.temperature <= -2 {
            results.append(
                WeatherAlert(
                    id: "cold",
                    title: "Cold Advisory",
                    message: "Cold air and wind can bite fast, so heavier layers will make a real difference.",
                    symbol: "thermometer.snowflake",
                    level: apparentTemperature <= -10 ? .severe : .warning
                )
            )
        }

        if current.windSpeed >= 38 {
            results.append(
                WeatherAlert(
                    id: "wind",
                    title: "Wind Advisory",
                    message: "Gusty conditions can make it feel sharper outside and may affect travel or outdoor setups.",
                    symbol: "wind",
                    level: current.windSpeed >= 55 ? .severe : .warning
                )
            )
        }

        if current.visibility <= 3 || current.condition == .fog {
            results.append(
                WeatherAlert(
                    id: "visibility",
                    title: "Low Visibility",
                    message: "Visibility is reduced enough that slower driving and extra awareness are worth it.",
                    symbol: "eye.trianglebadge.exclamationmark",
                    level: current.visibility <= 1 ? .severe : .elevated
                )
            )
        }

        if current.uvIndex >= 8 {
            results.append(
                WeatherAlert(
                    id: "uv",
                    title: "High UV",
                    message: "Sun exposure adds up fast today, so sunscreen and a little shade time are worth planning for.",
                    symbol: "sun.max.trianglebadge.exclamationmark.fill",
                    level: current.uvIndex >= 10 ? .warning : .elevated
                )
            )
        }

        if airQuality.category == .unhealthyForSensitive || airQuality.category == .unhealthy || airQuality.category == .veryUnhealthy || airQuality.category == .hazardous {
            results.append(
                WeatherAlert(
                    id: "air",
                    title: "Air Quality Alert",
                    message: airQuality.healthSummary,
                    symbol: "aqi.medium",
                    level: airQuality.category == .veryUnhealthy || airQuality.category == .hazardous ? .severe : .warning
                )
            )
        }

        return results
            .sorted { lhs, rhs in
                if lhs.level.rawValue != rhs.level.rawValue {
                    return lhs.level.rawValue > rhs.level.rawValue
                }
                return lhs.title < rhs.title
            }
            .prefix(3)
            .map { $0 }
    }

    private var vibeTimeWindow: VibeTimeWindow {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<9:
            return VibeTimeWindow.dawn
        case 9..<12:
            return VibeTimeWindow.morning
        case 12..<17:
            return VibeTimeWindow.afternoon
        case 17..<21:
            return VibeTimeWindow.evening
        default:
            return VibeTimeWindow.night
        }
    }

    private func deduplicated(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
}

private enum VibeTimeWindow {
    case dawn
    case morning
    case afternoon
    case evening
    case night
}

struct SunSchedule: Equatable, Codable {
    let sunrise: Date
    let sunset: Date
}

struct CurrentConditions: Equatable, Codable {
    let temperature: Int
    let apparentTemperature: Int
    let condition: WeatherCondition
    let windSpeed: Int
    let humidity: Int
    let uvIndex: Int
    let pressure: Int
    let visibility: Int
}

struct AirQuality: Equatable, Codable {
    let usAqi: Int
    let pm25: Double
    let pm10: Double
    let ozone: Double
    let nitrogenDioxide: Double

    var category: AirQualityCategory {
        AirQualityCategory.from(aqi: usAqi)
    }

    var dominantPollutant: String {
        let pollutantLevels = [
            ("PM2.5", pm25),
            ("PM10", pm10),
            ("Ozone", ozone),
            ("NO2", nitrogenDioxide)
        ]

        return pollutantLevels.max(by: { $0.1 < $1.1 })?.0 ?? "PM2.5"
    }

    var healthSummary: String {
        switch category {
        case .good:
            "Air looks clean right now, so outdoor plans should feel comfortable for most people."
        case .moderate:
            "Air quality is workable, though extra-sensitive groups may want shorter outdoor stretches."
        case .unhealthyForSensitive:
            "Sensitive groups should take it easier outside, especially during longer walks or workouts."
        case .unhealthy:
            "Air quality is rough enough that outdoor time is worth limiting when you can."
        case .veryUnhealthy:
            "The air is poor today, so indoor plans are the safer call."
        case .hazardous:
            "Air conditions are severe. Staying inside is the best move right now."
        }
    }
}

enum AirQualityCategory: String, Codable {
    case good
    case moderate
    case unhealthyForSensitive
    case unhealthy
    case veryUnhealthy
    case hazardous

    var title: String {
        switch self {
        case .good: "Good"
        case .moderate: "Moderate"
        case .unhealthyForSensitive: "Sensitive Groups"
        case .unhealthy: "Unhealthy"
        case .veryUnhealthy: "Very Unhealthy"
        case .hazardous: "Hazardous"
        }
    }

    static func from(aqi: Int) -> AirQualityCategory {
        switch aqi {
        case ..<51: .good
        case ..<101: .moderate
        case ..<151: .unhealthyForSensitive
        case ..<201: .unhealthy
        case ..<301: .veryUnhealthy
        default: .hazardous
        }
    }
}

struct HourlyForecast: Equatable, Identifiable, Codable {
    let id = UUID()
    let time: Date
    let temperature: Int
    let precipitationChance: Int
    let condition: WeatherCondition

    enum CodingKeys: String, CodingKey {
        case time
        case temperature
        case precipitationChance
        case condition
    }
}

struct DailyForecast: Equatable, Identifiable, Codable {
    let id = UUID()
    let date: Date
    let low: Int
    let high: Int
    let precipitationChance: Int
    let condition: WeatherCondition
    let sunSchedule: SunSchedule

    enum CodingKeys: String, CodingKey {
        case date
        case low
        case high
        case precipitationChance
        case condition
        case sunSchedule
    }
}

struct Coordinates: Equatable, Codable {
    let latitude: Double
    let longitude: Double
}

struct CitySuggestion: Equatable, Identifiable, Codable {
    let id: String
    let name: String
    let subtitle: String
    let coordinates: Coordinates
}

struct WeatherAlert: Equatable, Identifiable {
    let id: String
    let title: String
    let message: String
    let symbol: String
    let level: WeatherAlertLevel
}

enum WeatherAlertLevel: Int, Equatable {
    case elevated
    case warning
    case severe
}

enum TemperatureUnit: String, CaseIterable, Codable, Identifiable {
    case fahrenheit
    case celsius

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fahrenheit: "F"
        case .celsius: "C"
        }
    }

    func temperatureString(fromCelsius value: Int) -> String {
        switch self {
        case .fahrenheit:
            "\(Int((Double(value) * 9 / 5 + 32).rounded()))°"
        case .celsius:
            "\(value)°"
        }
    }

    func speedString(fromKilometersPerHour value: Int) -> String {
        switch self {
        case .fahrenheit:
            "\(Int((Double(value) * 0.621371).rounded())) mph"
        case .celsius:
            "\(value) km/h"
        }
    }
}

enum WeatherCondition: String, Equatable, Codable {
    case clear
    case partlyCloudy
    case cloudy
    case rain
    case storm
    case snow
    case fog

    var title: String {
        switch self {
        case .clear: "Clear"
        case .partlyCloudy: "Partly Cloudy"
        case .cloudy: "Cloudy"
        case .rain: "Rain"
        case .storm: "Storm"
        case .snow: "Snow"
        case .fog: "Fog"
        }
    }

    var sfSymbol: String {
        switch self {
        case .clear: "sun.max.fill"
        case .partlyCloudy: "cloud.sun.fill"
        case .cloudy: "cloud.fill"
        case .rain: "cloud.rain.fill"
        case .storm: "cloud.bolt.rain.fill"
        case .snow: "snowflake"
        case .fog: "cloud.fog.fill"
        }
    }

    static func from(code: Int) -> WeatherCondition {
        switch code {
        case 0: .clear
        case 1, 2: .partlyCloudy
        case 3: .cloudy
        case 45, 48: .fog
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82: .rain
        case 71, 73, 75, 77, 85, 86: .snow
        case 95, 96, 99: .storm
        default: .cloudy
        }
    }
}

extension Coordinates {
    static let chicago = Coordinates(latitude: 41.8781, longitude: -87.6298)
    static let austin = Coordinates(latitude: 30.2672, longitude: -97.7431)
    static let seattle = Coordinates(latitude: 47.6062, longitude: -122.3321)
}

enum WeatherSamples {
    static func makeSnapshot(
        cityName: String,
        coordinates: Coordinates,
        temperature: Int,
        condition: WeatherCondition,
        low: Int,
        high: Int,
        precipitationBase: Int
    ) -> WeatherSnapshot {
        WeatherSnapshot(
            cityName: cityName,
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            updatedAt: .now,
            current: CurrentConditions(
                temperature: temperature,
                apparentTemperature: temperature + (condition == .clear ? 1 : 0),
                condition: condition,
                windSpeed: max(8, precipitationBase / 2),
                humidity: min(92, 48 + precipitationBase),
                uvIndex: condition == .clear ? 7 : 4,
                pressure: 1012 + (condition == .clear ? 4 : -2),
                visibility: condition == .fog ? 4 : 10
            ),
            airQuality: AirQuality(
                usAqi: condition == .rain ? 46 : (condition == .clear ? 58 : 72),
                pm25: condition == .rain ? 7.2 : 13.4,
                pm10: condition == .rain ? 12.5 : 22.0,
                ozone: condition == .clear ? 81.0 : 52.0,
                nitrogenDioxide: condition == .rain ? 14.0 : 19.0
            ),
            hourly: (0..<5).map { offset in
                HourlyForecast(
                    time: .now.addingTimeInterval(Double(offset) * 3600),
                    temperature: temperature + (offset == 1 ? 1 : (offset >= 3 ? -1 : 0)),
                    precipitationChance: min(95, precipitationBase + offset * 6),
                    condition: offset >= 3 && condition == .clear ? .partlyCloudy : condition
                )
            },
            daily: (0..<5).map { offset in
                DailyForecast(
                    date: .now.addingTimeInterval(Double(offset) * 86400),
                    low: low + (offset == 2 ? -1 : 0),
                    high: high + (offset == 1 ? 1 : 0),
                    precipitationChance: min(95, precipitationBase + offset * 5),
                    condition: offset == 1 && condition == .clear ? .partlyCloudy : condition,
                    sunSchedule: SunSchedule(
                        sunrise: Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.date(bySettingHour: 6, minute: 12 - min(offset, 4), second: 0, of: .now) ?? .now) ?? .now,
                        sunset: Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.date(bySettingHour: 19, minute: 44 + min(offset, 4), second: 0, of: .now) ?? .now) ?? .now
                    )
                )
            }
        )
    }

    static let snapshot = WeatherSnapshot(
        cityName: "Chicago",
        latitude: Coordinates.chicago.latitude,
        longitude: Coordinates.chicago.longitude,
        updatedAt: .now,
        current: CurrentConditions(
            temperature: 20,
            apparentTemperature: 21,
            condition: .partlyCloudy,
            windSpeed: 14,
            humidity: 62,
            uvIndex: 5,
            pressure: 1015,
            visibility: 10
        ),
        airQuality: AirQuality(
            usAqi: 62,
            pm25: 12.1,
            pm10: 20.7,
            ozone: 58.4,
            nitrogenDioxide: 17.3
        ),
        hourly: [
            HourlyForecast(time: .now, temperature: 20, precipitationChance: 12, condition: .partlyCloudy),
            HourlyForecast(time: .now.addingTimeInterval(3600), temperature: 21, precipitationChance: 10, condition: .clear),
            HourlyForecast(time: .now.addingTimeInterval(7200), temperature: 22, precipitationChance: 8, condition: .clear),
            HourlyForecast(time: .now.addingTimeInterval(10800), temperature: 21, precipitationChance: 18, condition: .cloudy),
            HourlyForecast(time: .now.addingTimeInterval(14400), temperature: 19, precipitationChance: 35, condition: .rain)
        ],
        daily: [
            DailyForecast(date: .now, low: 13, high: 22, precipitationChance: 28, condition: .partlyCloudy, sunSchedule: SunSchedule(sunrise: Calendar.current.date(bySettingHour: 6, minute: 12, second: 0, of: .now) ?? .now, sunset: Calendar.current.date(bySettingHour: 19, minute: 44, second: 0, of: .now) ?? .now)),
            DailyForecast(date: .now.addingTimeInterval(86400), low: 15, high: 24, precipitationChance: 12, condition: .clear, sunSchedule: SunSchedule(sunrise: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.date(bySettingHour: 6, minute: 11, second: 0, of: .now) ?? .now) ?? .now, sunset: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.date(bySettingHour: 19, minute: 45, second: 0, of: .now) ?? .now) ?? .now)),
            DailyForecast(date: .now.addingTimeInterval(172800), low: 16, high: 22, precipitationChance: 44, condition: .rain, sunSchedule: SunSchedule(sunrise: Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.date(bySettingHour: 6, minute: 9, second: 0, of: .now) ?? .now) ?? .now, sunset: Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.date(bySettingHour: 19, minute: 46, second: 0, of: .now) ?? .now) ?? .now)),
            DailyForecast(date: .now.addingTimeInterval(259200), low: 12, high: 19, precipitationChance: 20, condition: .cloudy, sunSchedule: SunSchedule(sunrise: Calendar.current.date(byAdding: .day, value: 3, to: Calendar.current.date(bySettingHour: 6, minute: 8, second: 0, of: .now) ?? .now) ?? .now, sunset: Calendar.current.date(byAdding: .day, value: 3, to: Calendar.current.date(bySettingHour: 19, minute: 47, second: 0, of: .now) ?? .now) ?? .now)),
            DailyForecast(date: .now.addingTimeInterval(345600), low: 11, high: 18, precipitationChance: 16, condition: .clear, sunSchedule: SunSchedule(sunrise: Calendar.current.date(byAdding: .day, value: 4, to: Calendar.current.date(bySettingHour: 6, minute: 6, second: 0, of: .now) ?? .now) ?? .now, sunset: Calendar.current.date(byAdding: .day, value: 4, to: Calendar.current.date(bySettingHour: 19, minute: 48, second: 0, of: .now) ?? .now) ?? .now))
        ]
    )

    static let demoSnapshots = [
        makeSnapshot(
            cityName: "Chicago",
            coordinates: .chicago,
            temperature: 20,
            condition: .partlyCloudy,
            low: 13,
            high: 22,
            precipitationBase: 20
        ),
        makeSnapshot(
            cityName: "Austin",
            coordinates: .austin,
            temperature: 28,
            condition: .clear,
            low: 21,
            high: 33,
            precipitationBase: 8
        ),
        makeSnapshot(
            cityName: "Seattle",
            coordinates: .seattle,
            temperature: 15,
            condition: .rain,
            low: 11,
            high: 17,
            precipitationBase: 58
        )
    ]
}
