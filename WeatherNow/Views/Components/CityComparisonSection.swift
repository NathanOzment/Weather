import SwiftUI

struct CityComparisonSection: View {
    let snapshots: [WeatherSnapshot]
    let temperatureUnit: TemperatureUnit

    private var comparison: CityComparisonSummary? {
        CityComparisonSummary(snapshots: snapshots, temperatureUnit: temperatureUnit)
    }

    var body: some View {
        if let comparison {
            VStack(alignment: .leading, spacing: 14) {
                Text("Best City Today")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(comparison.bestOverall.cityName)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                            Text(comparison.bestOverallReason)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.76))
                        }

                        Spacer()

                        Text(comparison.bestOverallScore)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .weatherGlassChip(cornerRadius: 22, tint: Color.white.opacity(0.10))
                    }

                    HStack(spacing: 12) {
                        comparisonCard(
                            title: "Warmest",
                            city: comparison.warmest.cityName,
                            detail: temperatureUnit.temperatureString(fromCelsius: comparison.warmest.current.temperature),
                            icon: "thermometer.sun.fill",
                            tint: Color(red: 0.98, green: 0.64, blue: 0.28)
                        )

                        comparisonCard(
                            title: "Driest",
                            city: comparison.driest.cityName,
                            detail: "\(comparison.driest.daily.first?.precipitationChance ?? 0)% rain chance",
                            icon: "sun.max.fill",
                            tint: Color(red: 0.98, green: 0.81, blue: 0.35)
                        )
                    }

                    HStack(spacing: 12) {
                        comparisonCard(
                            title: "Cleanest Air",
                            city: comparison.cleanestAir.cityName,
                            detail: "AQI \(comparison.cleanestAir.airQuality.usAqi)",
                            icon: "leaf.fill",
                            tint: Color(red: 0.40, green: 0.86, blue: 0.58)
                        )

                        comparisonCard(
                            title: "Lowest Risk",
                            city: comparison.lowestRisk.cityName,
                            detail: comparison.lowestRisk.alerts.isEmpty ? "No active alerts" : "\(comparison.lowestRisk.alerts.count) alert\(comparison.lowestRisk.alerts.count == 1 ? "" : "s")",
                            icon: "checkmark.shield.fill",
                            tint: Color(red: 0.47, green: 0.81, blue: 0.94)
                        )
                    }
                }
            }
            .padding(18)
            .weatherGlassCard(cornerRadius: 28, tint: Color.white.opacity(0.08))
        }
    }

    private func comparisonCard(title: String, city: String, detail: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(tint)
                .padding(10)
                .weatherGlassChip(cornerRadius: 16, tint: tint.opacity(0.18))

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            Text(city)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))

            Text(detail)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
        .padding(18)
        .weatherGlassCard(cornerRadius: 24, tint: tint.opacity(0.12))
    }
}

private struct CityComparisonSummary {
    let snapshots: [WeatherSnapshot]
    let temperatureUnit: TemperatureUnit

    init?(snapshots: [WeatherSnapshot], temperatureUnit: TemperatureUnit) {
        guard !snapshots.isEmpty else { return nil }
        self.snapshots = snapshots
        self.temperatureUnit = temperatureUnit
    }

    var bestOverall: WeatherSnapshot {
        snapshots.max(by: { overallScore(for: $0) < overallScore(for: $1) }) ?? snapshots[0]
    }

    var bestOverallScore: String {
        let rounded = Int(overallScore(for: bestOverall).rounded())
        return "\(rounded)"
    }

    var bestOverallReason: String {
        let rainChance = bestOverall.daily.first?.precipitationChance ?? 0
        if bestOverall.alerts.isEmpty && bestOverall.airQuality.usAqi < 80 && rainChance < 35 {
            return "Best blend of comfort, lower rain chances, cleaner air, and fewer forecast risks."
        }
        if !bestOverall.alerts.isEmpty {
            return "Still leads overall, but keep an eye on \(bestOverall.alerts.first?.title.lowercased() ?? "forecast alerts")."
        }
        return "Looks strongest overall based on forecast comfort, air quality, and lower disruption risk."
    }

    var warmest: WeatherSnapshot {
        snapshots.max(by: { $0.current.temperature < $1.current.temperature }) ?? snapshots[0]
    }

    var driest: WeatherSnapshot {
        snapshots.min(by: { ($0.daily.first?.precipitationChance ?? 100) < ($1.daily.first?.precipitationChance ?? 100) }) ?? snapshots[0]
    }

    var cleanestAir: WeatherSnapshot {
        snapshots.min(by: { $0.airQuality.usAqi < $1.airQuality.usAqi }) ?? snapshots[0]
    }

    var lowestRisk: WeatherSnapshot {
        snapshots.min(by: { riskScore(for: $0) < riskScore(for: $1) }) ?? snapshots[0]
    }

    private func overallScore(for snapshot: WeatherSnapshot) -> Double {
        let comfort = comfortScore(for: snapshot)
        let rainPenalty = Double(snapshot.daily.first?.precipitationChance ?? 0) * 0.35
        let airPenalty = Double(max(snapshot.airQuality.usAqi - 40, 0)) * 0.3
        let alertPenalty = Double(snapshot.alerts.count) * 10
        return comfort - rainPenalty - airPenalty - alertPenalty
    }

    private func comfortScore(for snapshot: WeatherSnapshot) -> Double {
        let idealCelsius = temperatureUnit == .fahrenheit ? 22 : 22
        let distance = abs(snapshot.current.apparentTemperature - idealCelsius)
        let base = max(0, 100 - Double(distance * 4))
        let windPenalty = Double(max(snapshot.current.windSpeed - 22, 0)) * 0.8
        return base - windPenalty
    }

    private func riskScore(for snapshot: WeatherSnapshot) -> Double {
        let rainRisk = Double(snapshot.daily.first?.precipitationChance ?? 0)
        let airRisk = Double(max(snapshot.airQuality.usAqi - 40, 0)) * 0.4
        let alertRisk = Double(snapshot.alerts.count) * 20
        return rainRisk + airRisk + alertRisk
    }
}
