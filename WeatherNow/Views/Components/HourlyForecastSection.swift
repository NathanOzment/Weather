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
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.cyan)
                        }
                        .foregroundStyle(.white)
                        .frame(width: 78)
                        .padding(.vertical, 16)
                        .weatherGlassCard(cornerRadius: 24, tint: Color.white.opacity(0.08))
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
