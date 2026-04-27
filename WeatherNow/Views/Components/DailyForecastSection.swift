import SwiftUI

struct DailyForecastSection: View {
    let daily: [DailyForecast]
    let temperatureUnit: TemperatureUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-Day Outlook")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Group {
                if #available(iOS 26, *) {
                    GlassEffectContainer(spacing: 12) {
                        dailyRows
                    }
                } else {
                    dailyRows
                }
            }
        }
    }

    private var dailyRows: some View {
        VStack(spacing: 10) {
            ForEach(daily) { day in
                HStack(spacing: 12) {
                    Text(day.date.formatted(.dateTime.weekday(.wide)))
                        .font(.headline.weight(.medium))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: day.condition.sfSymbol)
                        .frame(width: 28)
                        .symbolRenderingMode(.multicolor)

                    Text("\(day.precipitationChance)%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .weatherGlassChip(cornerRadius: 16, tint: Color.cyan.opacity(0.10))

                    HStack(spacing: 8) {
                        temperatureChip(temperatureUnit.temperatureString(fromCelsius: day.low), subdued: true)
                        temperatureChip(temperatureUnit.temperatureString(fromCelsius: day.high), subdued: false)
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .weatherGlassCard(cornerRadius: 22, tint: day.precipitationChance > 55 ? Color.cyan.opacity(0.06) : nil)
            }
        }
    }

    private func temperatureChip(_ value: String, subdued: Bool) -> some View {
        Text(value)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(subdued ? .white.opacity(0.72) : .white)
            .frame(minWidth: 44)
    }
}
