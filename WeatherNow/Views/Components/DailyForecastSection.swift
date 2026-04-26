import SwiftUI

struct DailyForecastSection: View {
    let daily: [DailyForecast]
    let temperatureUnit: TemperatureUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-Day Outlook")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

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
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.cyan)
                            .frame(width: 44)

                        Text(temperatureUnit.temperatureString(fromCelsius: day.low))
                            .foregroundStyle(.white.opacity(0.72))
                            .frame(width: 44)

                        Text(temperatureUnit.temperatureString(fromCelsius: day.high))
                            .fontWeight(.semibold)
                            .frame(width: 44)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .weatherGlassCard(cornerRadius: 22, tint: Color.white.opacity(0.08))
                }
            }
        }
    }
}
