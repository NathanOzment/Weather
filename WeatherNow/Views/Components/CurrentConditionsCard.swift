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
        .weatherGlassCard(cornerRadius: 30, tint: WeatherGlassPalette.cool.opacity(0.16))
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

            HStack(spacing: 8) {
                weatherMetric(title: "Feels", value: temperatureUnit.temperatureString(fromCelsius: snapshot.current.apparentTemperature), symbol: "thermometer.medium")
                weatherMetric(title: "Wind", value: temperatureUnit.speedString(fromKilometersPerHour: snapshot.current.windSpeed), symbol: "wind")
                weatherMetric(title: "Humidity", value: "\(snapshot.current.humidity)%", symbol: "humidity.fill")
                weatherMetric(title: "UV", value: "\(snapshot.current.uvIndex)", symbol: "sun.max.fill")
            }

            HStack(spacing: 12) {
                Button {
                    onShowDetails()
                } label: {
                    actionPill(
                        title: "Details",
                        symbol: "chart.line.uptrend.xyaxis",
                        tint: WeatherGlassPalette.warm.opacity(0.18)
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    onSaveCity()
                } label: {
                    actionPill(
                        title: "Save",
                        symbol: "plus.circle.fill",
                        tint: WeatherGlassPalette.slate.opacity(0.18)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func displayTemperature(_ celsius: Int) -> String {
        temperatureUnit.temperatureString(fromCelsius: celsius).replacingOccurrences(of: "°", with: "")
    }

    private func weatherMetric(title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .center, spacing: 6) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.86))

            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .weatherGlassChip(cornerRadius: 18, tint: WeatherGlassPalette.slate.opacity(0.14))
        .contentTransition(.interpolate)
    }

    private func actionPill(title: String, symbol: String, tint: Color) -> some View {
        Label(title, systemImage: symbol)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .weatherGlassChip(cornerRadius: 18, tint: tint, interactive: true)
    }
}
