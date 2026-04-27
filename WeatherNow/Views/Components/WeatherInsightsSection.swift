import SwiftUI

struct WeatherAlertsSection: View {
    let snapshot: WeatherSnapshot

    var body: some View {
        if !snapshot.alerts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Weather Alerts")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                ForEach(snapshot.alerts) { alert in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: alert.symbol)
                            .font(.headline)
                            .foregroundStyle(alert.tintColor)
                            .frame(width: 24)
                            .padding(10)
                            .weatherGlassChip(cornerRadius: 16, tint: alert.tintColor.opacity(0.18))

                        VStack(alignment: .leading, spacing: 6) {
                            Text(alert.title)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)

                            Text(alert.message)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .weatherGlassCard(cornerRadius: 22, tint: alert.backgroundColor)
                }
            }
        }
    }
}

struct WeatherInsightsSection: View {
    let snapshot: WeatherSnapshot
    let temperatureUnit: TemperatureUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Details")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                insightCard(title: "Feels Like", value: temperatureUnit.temperatureString(fromCelsius: snapshot.current.apparentTemperature), icon: "thermometer.medium")
                insightCard(title: "Wind", value: temperatureUnit.speedString(fromKilometersPerHour: snapshot.current.windSpeed), icon: "wind")
                insightCard(title: "Visibility", value: "\(snapshot.current.visibility) km", icon: "eye.fill")
                insightCard(title: "Pressure", value: "\(snapshot.current.pressure) hPa", icon: "gauge.with.dots.needle.50percent")
            }
        }
    }

    private func insightCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.88))
                .padding(10)
                .weatherGlassChip(cornerRadius: 16, tint: WeatherGlassPalette.slate.opacity(0.14))
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
        .padding(16)
        .weatherGlassCard(cornerRadius: 24, tint: WeatherGlassPalette.cool.opacity(0.14))
    }
}

private extension WeatherAlert {
    var tintColor: Color {
        switch level {
        case .elevated:
            Color(red: 0.98, green: 0.79, blue: 0.35)
        case .warning:
            Color(red: 0.99, green: 0.57, blue: 0.33)
        case .severe:
            Color(red: 0.96, green: 0.36, blue: 0.35)
        }
    }

    var backgroundColor: Color {
        switch level {
        case .elevated:
            Color(red: 0.35, green: 0.28, blue: 0.09).opacity(0.4)
        case .warning:
            Color(red: 0.39, green: 0.19, blue: 0.08).opacity(0.45)
        case .severe:
            Color(red: 0.36, green: 0.10, blue: 0.13).opacity(0.52)
        }
    }
}
