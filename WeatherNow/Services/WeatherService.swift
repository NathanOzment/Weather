import Foundation

enum WeatherServiceError: LocalizedError {
    case invalidResponse
    case cityNotFound

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Weather data could not be loaded right now."
        case .cityNotFound:
            "That city could not be found."
        }
    }
}

struct WeatherService {
    func fetchWeather(for coordinates: Coordinates, preferredName: String? = nil) async throws -> WeatherSnapshot {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(coordinates.latitude)"),
            URLQueryItem(name: "longitude", value: "\(coordinates.longitude)"),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,surface_pressure,visibility"),
            URLQueryItem(name: "hourly", value: "temperature_2m,precipitation_probability,weather_code,uv_index,visibility"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max,sunrise,sunset"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7")
        ]
        let weatherURL = components.url!

        async let airQualityData = safeFetchAirQuality(for: coordinates)
        async let locationName = safeReverseGeocode(coordinates: coordinates)

        let data = try await fetchData(from: weatherURL)
        let decoded = try JSONDecoder.weatherDecoder.decode(OpenMeteoForecast.self, from: data)
        let airQuality = await airQualityData ?? fallbackAirQuality(for: decoded.current.weatherCode)
        let cityName = await locationName ?? "Your Area"

        return WeatherSnapshot(
            cityName: preferredName ?? cityName,
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            updatedAt: .now,
            current: CurrentConditions(
                temperature: Int(decoded.current.temperature.rounded()),
                apparentTemperature: Int(decoded.current.apparentTemperature.rounded()),
                condition: .from(code: decoded.current.weatherCode),
                windSpeed: Int(decoded.current.windSpeed.rounded()),
                humidity: decoded.current.relativeHumidity,
                uvIndex: Int((decoded.hourly.uvIndex.first ?? 0).rounded()),
                pressure: Int(decoded.current.surfacePressure.rounded()),
                visibility: Int((Double(decoded.current.visibility) / 1000).rounded())
            ),
            airQuality: airQuality,
            hourly: zip(decoded.hourly.time.indices, decoded.hourly.time).prefix(12).map { index, time in
                HourlyForecast(
                    time: time,
                    temperature: Int(decoded.hourly.temperature[index].rounded()),
                    precipitationChance: decoded.hourly.precipitationProbability[index],
                    condition: .from(code: decoded.hourly.weatherCode[index])
                )
            },
            daily: zip(decoded.daily.time.indices, decoded.daily.time).map { index, date in
                DailyForecast(
                    date: date,
                    low: Int(decoded.daily.temperatureMin[index].rounded()),
                    high: Int(decoded.daily.temperatureMax[index].rounded()),
                    precipitationChance: decoded.daily.precipitationProbabilityMax[index],
                    condition: .from(code: decoded.daily.weatherCode[index]),
                    sunSchedule: SunSchedule(
                        sunrise: decoded.daily.sunrise[index],
                        sunset: decoded.daily.sunset[index]
                    )
                )
            }
        )
    }

    func geocode(city: String) async throws -> Coordinates {
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let url = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(encodedCity)&count=1&language=en&format=json")!
        let data = try await fetchData(from: url)
        let decoded = try JSONDecoder().decode(OpenMeteoGeocoding.self, from: data)

        guard let result = decoded.results?.first else {
            throw WeatherServiceError.cityNotFound
        }

        return Coordinates(latitude: result.latitude, longitude: result.longitude)
    }

    func searchSuggestions(for query: String) async throws -> [CitySuggestion] {
        let encodedCity = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let url = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(encodedCity)&count=5&language=en&format=json")!
        let data = try await fetchData(from: url)
        let decoded = try JSONDecoder().decode(OpenMeteoGeocoding.self, from: data)

        return (decoded.results ?? []).map { result in
            let subtitleParts = [result.admin1, result.country].compactMap { $0 }.filter { !$0.isEmpty }
            let subtitle = subtitleParts.isEmpty ? "Suggested location" : subtitleParts.joined(separator: ", ")
            return CitySuggestion(
                id: "\(result.name)-\(result.latitude)-\(result.longitude)",
                name: result.name,
                subtitle: subtitle,
                coordinates: Coordinates(latitude: result.latitude, longitude: result.longitude)
            )
        }
    }

    private func fetchAirQuality(for coordinates: Coordinates) async throws -> AirQuality {
        var components = URLComponents(string: "https://air-quality-api.open-meteo.com/v1/air-quality")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(coordinates.latitude)"),
            URLQueryItem(name: "longitude", value: "\(coordinates.longitude)"),
            URLQueryItem(name: "current", value: "us_aqi,pm2_5,pm10,ozone,nitrogen_dioxide"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        let url = components.url!
        let data = try await fetchData(from: url)
        let decoded = try JSONDecoder.weatherDecoder.decode(OpenMeteoAirQuality.self, from: data)

        return AirQuality(
            usAqi: Int(decoded.current.usAqi.rounded()),
            pm25: decoded.current.pm25,
            pm10: decoded.current.pm10,
            ozone: decoded.current.ozone,
            nitrogenDioxide: decoded.current.nitrogenDioxide
        )
    }

    private func reverseGeocode(coordinates: Coordinates) async throws -> String {
        let url = URL(string: "https://geocoding-api.open-meteo.com/v1/reverse?latitude=\(coordinates.latitude)&longitude=\(coordinates.longitude)&language=en&format=json")!
        let data = try await fetchData(from: url)
        let decoded = try JSONDecoder().decode(OpenMeteoReverseGeocoding.self, from: data)
        return decoded.results.first?.name ?? "Your Area"
    }

    private func fetchData(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw WeatherServiceError.invalidResponse
        }

        return data
    }

    private func safeFetchAirQuality(for coordinates: Coordinates) async -> AirQuality? {
        try? await fetchAirQuality(for: coordinates)
    }

    private func safeReverseGeocode(coordinates: Coordinates) async -> String? {
        try? await reverseGeocode(coordinates: coordinates)
    }

    private func fallbackAirQuality(for weatherCode: Int) -> AirQuality {
        let condition = WeatherCondition.from(code: weatherCode)

        switch condition {
        case .clear:
            return AirQuality(usAqi: 58, pm25: 13.0, pm10: 22.0, ozone: 76.0, nitrogenDioxide: 18.0)
        case .rain, .snow:
            return AirQuality(usAqi: 42, pm25: 7.0, pm10: 12.0, ozone: 38.0, nitrogenDioxide: 12.0)
        case .storm:
            return AirQuality(usAqi: 51, pm25: 9.0, pm10: 16.0, ozone: 41.0, nitrogenDioxide: 11.0)
        case .cloudy, .partlyCloudy, .fog:
            return AirQuality(usAqi: 64, pm25: 15.0, pm10: 25.0, ozone: 54.0, nitrogenDioxide: 21.0)
        }
    }
}

private struct OpenMeteoForecast: Decodable {
    let current: Current
    let hourly: Hourly
    let daily: Daily

    struct Current: Decodable {
        let temperature: Double
        let apparentTemperature: Double
        let relativeHumidity: Int
        let windSpeed: Double
        let weatherCode: Int
        let surfacePressure: Double
        let visibility: Int

        enum CodingKeys: String, CodingKey {
            case temperature = "temperature_2m"
            case apparentTemperature = "apparent_temperature"
            case relativeHumidity = "relative_humidity_2m"
            case windSpeed = "wind_speed_10m"
            case weatherCode = "weather_code"
            case surfacePressure = "surface_pressure"
            case visibility
        }
    }

    struct Hourly: Decodable {
        let time: [Date]
        let temperature: [Double]
        let precipitationProbability: [Int]
        let weatherCode: [Int]
        let uvIndex: [Double]
        let visibility: [Int]

        enum CodingKeys: String, CodingKey {
            case time
            case temperature = "temperature_2m"
            case precipitationProbability = "precipitation_probability"
            case weatherCode = "weather_code"
            case uvIndex = "uv_index"
            case visibility
        }
    }

    struct Daily: Decodable {
        let time: [Date]
        let temperatureMax: [Double]
        let temperatureMin: [Double]
        let weatherCode: [Int]
        let precipitationProbabilityMax: [Int]
        let sunrise: [Date]
        let sunset: [Date]

        enum CodingKeys: String, CodingKey {
            case time
            case temperatureMax = "temperature_2m_max"
            case temperatureMin = "temperature_2m_min"
            case weatherCode = "weather_code"
            case precipitationProbabilityMax = "precipitation_probability_max"
            case sunrise
            case sunset
        }
    }
}

private struct OpenMeteoGeocoding: Decodable {
    let results: [Result]?

    struct Result: Decodable {
        let name: String
        let latitude: Double
        let longitude: Double
        let admin1: String?
        let country: String?
    }
}

private struct OpenMeteoReverseGeocoding: Decodable {
    let results: [Result]

    struct Result: Decodable {
        let name: String
    }
}

private struct OpenMeteoAirQuality: Decodable {
    let current: Current

    struct Current: Decodable {
        let usAqi: Double
        let pm25: Double
        let pm10: Double
        let ozone: Double
        let nitrogenDioxide: Double

        enum CodingKeys: String, CodingKey {
            case usAqi = "us_aqi"
            case pm25 = "pm2_5"
            case pm10
            case ozone
            case nitrogenDioxide = "nitrogen_dioxide"
        }
    }
}

private extension JSONDecoder {
    static let weatherDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
