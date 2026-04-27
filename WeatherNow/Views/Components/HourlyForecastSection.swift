import SwiftUI

struct HourlyForecastSection: View {
    let hourly: [HourlyForecast]
    let temperatureUnit: TemperatureUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hourly Forecast")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                Group {
                    if #available(iOS 26, *) {
                        GlassEffectContainer(spacing: 14) {
                            hourlyRow
                        }
                    } else {
                        hourlyRow
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var hourlyRow: some View {
        HStack(spacing: 12) {
            ForEach(hourly) { hour in
                VStack(spacing: 10) {
                    Text(hour.time.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated))))
                        .font(.subheadline.weight(.medium))
                    Image(systemName: hour.condition.sfSymbol)
                        .font(.title2)
                        .symbolRenderingMode(.multicolor)
                    Text(temperatureUnit.temperatureString(fromCelsius: hour.temperature))
                        .font(.headline.weight(.bold))
                    Text("\(hour.precipitationChance)%")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .weatherGlassChip(cornerRadius: 16, tint: Color.cyan.opacity(0.12))
                }
                .foregroundStyle(.white)
                .frame(width: 84)
                .padding(.vertical, 16)
                .weatherGlassCard(cornerRadius: 24, tint: hour.precipitationChance > 55 ? Color.cyan.opacity(0.08) : nil)
            }
        }
    }
}
