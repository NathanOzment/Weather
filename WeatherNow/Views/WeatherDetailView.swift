import SwiftUI

struct WeatherDetailView: View {
    let snapshot: WeatherSnapshot
    let temperatureUnit: TemperatureUnit

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.13, blue: 0.26),
                    Color(red: 0.17, green: 0.29, blue: 0.48),
                    Color(red: 0.42, green: 0.60, blue: 0.76)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(snapshot.cityName)
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Deep Dive")
                            .font(.headline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.75))
                    }

                    summaryCard
                    AirQualitySection(airQuality: snapshot.airQuality)
                    TemperatureTrendSection(hourly: snapshot.hourly, temperatureUnit: temperatureUnit)
                    ForecastPlannerSection(snapshot: snapshot, temperatureUnit: temperatureUnit)

                    if let today = snapshot.daily.first {
                        SunScheduleCard(schedule: today.sunSchedule)
                    }

                    DailyForecastSection(daily: snapshot.daily, temperatureUnit: temperatureUnit)
                }
                .padding(20)
            }
        }
        .navigationTitle("Forecast")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: snapshot.current.condition.sfSymbol)
                    .font(.system(size: 38))
                    .symbolRenderingMode(.multicolor)
                Spacer()
                Text(snapshot.current.condition.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.88))
            }

            Text(temperatureUnit.temperatureString(fromCelsius: snapshot.current.temperature))
                .font(.system(size: 72, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Text("H: \(temperatureUnit.temperatureString(fromCelsius: snapshot.daily.first?.high ?? snapshot.current.temperature))   L: \(temperatureUnit.temperatureString(fromCelsius: snapshot.daily.first?.low ?? snapshot.current.temperature))")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.82))
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}
