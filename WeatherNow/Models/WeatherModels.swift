import CoreLocation
import Foundation

struct WeatherSnapshot: Equatable, Codable {
    let cityName: String
    let latitude: Double
    let longitude: Double
    let updatedAt: Date
    let current: CurrentConditions
    let hourly: [HourlyForecast]
    let daily: [DailyForecast]
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
}

enum WeatherSamples {
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
}
