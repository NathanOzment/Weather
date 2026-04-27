import SwiftUI

struct TemperatureTrendSection: View {
    let hourly: [HourlyForecast]
    let temperatureUnit: TemperatureUnit

    private var minimumTemperature: Int {
        hourly.map(\.temperature).min() ?? 0
    }

    private var maximumTemperature: Int {
        hourly.map(\.temperature).max() ?? 1
    }

    private var firstEightHours: ArraySlice<HourlyForecast> {
        hourly.prefix(8)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Temperature Trend")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Group {
                if #available(iOS 26, *) {
                    GlassEffectContainer(spacing: 16) {
                        trendCard
                    }
                } else {
                    trendCard
                }
            }
        }
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                trendChip(
                    title: "Low",
                    value: temperatureUnit.temperatureString(fromCelsius: minimumTemperature)
                )
                trendChip(
                    title: "High",
                    value: temperatureUnit.temperatureString(fromCelsius: maximumTemperature)
                )
            }

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(firstEightHours) { hour in
                    VStack(spacing: 10) {
                        Spacer(minLength: 0)

                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(LinearGradient(colors: [Color.white.opacity(0.95), Color.cyan.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                            .frame(height: barHeight(for: hour.temperature))

                        Text(temperatureUnit.temperatureString(fromCelsius: hour.temperature))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)

                        Text(hour.time.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated))))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 180)
        }
        .padding(18)
        .weatherGlassCard(cornerRadius: 28)
    }

    private func barHeight(for temperature: Int) -> CGFloat {
        let range = max(maximumTemperature - minimumTemperature, 1)
        let normalized = Double(temperature - minimumTemperature) / Double(range)
        return CGFloat(52 + normalized * 78)
    }

    private func trendChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.68))
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .weatherGlassChip(cornerRadius: 18)
    }
}
