import SwiftUI

struct CurrentConditionsCard: View {
    let snapshot: WeatherSnapshot
    let temperatureUnit: TemperatureUnit
    let isRefreshing: Bool
    let onSaveCity: () -> Void
    let onShowDetails: () -> Void

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                GlassEffectContainer(spacing: 18) {
                    cardContent
                }
            } else {
                cardContent
            }
        }
        .foregroundStyle(.white)
        .padding(24)
        .weatherGlassCard(cornerRadius: 30, tint: Color.white.opacity(0.08))
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(snapshot.cityName)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .contentTransition(.interpolate)
                    Text(snapshot.current.condition.title)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                        .contentTransition(.interpolate)

                    if isRefreshing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(.white)
                            Text("Refreshing")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .weatherGlassChip(cornerRadius: 16, tint: Color.white.opacity(0.10))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                Spacer()

                Image(systemName: snapshot.current.condition.sfSymbol)
                    .font(.system(size: 42))
                    .symbolRenderingMode(.multicolor)
                    .padding(14)
                    .weatherGlassChip(cornerRadius: 22, tint: Color.white.opacity(0.10))
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(displayTemperature(snapshot.current.temperature))
                    .font(.system(size: 88, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
                Text("°")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.bottom, 18)
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
                }
                .weatherGlassButton(prominent: true)

                Spacer()

                Button {
                    onSaveCity()
                } label: {
                    Label("Save", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                }
                .weatherGlassButton()
                .foregroundStyle(.white)
            }
        }
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
        .padding(12)
        .weatherGlassChip(cornerRadius: 18, tint: Color.white.opacity(0.08))
        .contentTransition(.interpolate)
    }
}
