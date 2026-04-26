import SwiftUI

struct CurrentConditionsCard: View {
    let snapshot: WeatherSnapshot
    let temperatureUnit: TemperatureUnit
    let onSaveCity: () -> Void
    let onShowDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(snapshot.cityName)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text(snapshot.current.condition.title)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer()

                Image(systemName: snapshot.current.condition.sfSymbol)
                    .font(.system(size: 42))
                    .symbolRenderingMode(.multicolor)
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(displayTemperature(snapshot.current.temperature))
                    .font(.system(size: 88, weight: .semibold, design: .rounded))
            }

            HStack(spacing: 12) {
                weatherMetric(title: "Feels Like", value: temperatureUnit.temperatureString(fromCelsius: snapshot.current.apparentTemperature))
                weatherMetric(title: "Wind", value: temperatureUnit.speedString(fromKilometersPerHour: snapshot.current.windSpeed))
                weatherMetric(title: "Humidity", value: "\(snapshot.current.humidity)%")
                weatherMetric(title: "UV", value: "\(snapshot.current.uvIndex)")
            }

            HStack(spacing: 12) {
                Button {
                    onShowDetails()
                } label: {
                    Label("Details", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.14), in: Capsule())
                }

                Spacer()

                Button {
                    onSaveCity()
                } label: {
                    Label("Save", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.14), in: Capsule())
                }
                .foregroundStyle(.white)
            }
        }
        .foregroundStyle(.white)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.78))
        )
    }

    private func displayTemperature(_ celsius: Int) -> String {
        temperatureUnit.temperatureString(fromCelsius: celsius).replacingOccurrences(of: "°", with: "")
    }

    private func weatherMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
            Text(value)
                .font(.headline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
