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
        .padding(14)
        .weatherGlassCard(cornerRadius: 32, tint: accentTint.opacity(0.14))
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerShelf
            temperatureShelf
            metricsShelf
            actionShelf
        }
    }

    private var headerShelf: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(snapshot.cityName)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .contentTransition(.interpolate)

                Text(snapshot.vibeTitle)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.74))
                    .lineLimit(1)
                    .contentTransition(.interpolate)

                HStack(spacing: 8) {
                    Text(snapshot.current.condition.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.94))
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .weatherGlassLens(cornerRadius: 18, tint: accentTint.opacity(0.12))
                        .contentTransition(.interpolate)

                    freshnessChip
                }
            }

            Spacer()

            Image(systemName: snapshot.current.condition.sfSymbol)
                .font(.system(size: 42))
                .symbolRenderingMode(.multicolor)
                .padding(16)
                .weatherGlassLens(cornerRadius: 24, tint: accentTint.opacity(0.14))
                .background(alignment: .center) {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    accentTint.opacity(0.28),
                                    accentTint.opacity(0.10),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 8,
                                endRadius: 58
                            )
                        )
                        .frame(width: 118, height: 118)
                        .blur(radius: 14)
                }
        }
        .padding(12)
        .weatherGlassCard(cornerRadius: 28, tint: accentTint.opacity(0.12))
    }

    private var temperatureShelf: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(displayTemperature(snapshot.current.temperature))
                    .font(.system(size: 68, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
                Text("°")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.bottom, 10)

                Spacer()

                Text(snapshot.freshnessText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(snapshot.isStale ? Color(red: 0.99, green: 0.84, blue: 0.42) : .white.opacity(0.88))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .weatherGlassLens(
                        cornerRadius: 18,
                        tint: snapshot.isStale ? Color(red: 0.99, green: 0.84, blue: 0.42).opacity(0.16) : accentTint.opacity(0.12)
                    )
            }

            HStack(spacing: 0) {
                compactReadingColumn(title: "Feels Like", value: temperatureUnit.temperatureString(fromCelsius: snapshot.current.apparentTemperature))
                compactReadingColumn(title: "High", value: temperatureUnit.temperatureString(fromCelsius: snapshot.daily.first?.high ?? snapshot.current.temperature))
                compactReadingColumn(title: "Low", value: temperatureUnit.temperatureString(fromCelsius: snapshot.daily.first?.low ?? snapshot.current.temperature))
            }
            .padding(4)
            .weatherGlassCard(cornerRadius: 22, tint: accentTint.opacity(0.08))
        }
        .padding(12)
        .weatherGlassLens(cornerRadius: 30, tint: accentTint.opacity(0.10))
    }

    private var metricsShelf: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                weatherMetric(title: "Feels", value: temperatureUnit.temperatureString(fromCelsius: snapshot.current.apparentTemperature), symbol: "thermometer.medium")
                weatherMetric(title: "Wind", value: temperatureUnit.speedString(fromKilometersPerHour: snapshot.current.windSpeed), symbol: "wind")
                weatherMetric(title: "Humidity", value: "\(snapshot.current.humidity)%", symbol: "humidity.fill")
                weatherMetric(title: "UV", value: "\(snapshot.current.uvIndex)", symbol: "sun.max.fill")
            }
        }
        .padding(8)
        .weatherGlassCard(cornerRadius: 26, tint: WeatherGlassPalette.slate.opacity(0.16))
    }

    private var actionShelf: some View {
        HStack(spacing: 12) {
            Button {
                onShowDetails()
            } label: {
                Label("Details", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
            }
            .weatherGlassButton(prominent: true)

            Spacer(minLength: 8)

            Button {
                onSaveCity()
            } label: {
                Label("Save", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .foregroundStyle(.white.opacity(0.92))
            }
            .weatherGlassButton()
        }
    }

    private var freshnessChip: some View {
        HStack(spacing: 8) {
            if isRefreshing {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
            } else {
                Image(systemName: snapshot.isStale ? "clock.badge.exclamationmark.fill" : "clock.fill")
                    .font(.caption.weight(.semibold))
            }

            Text(isRefreshing ? "Syncing" : "Live")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .weatherGlassChip(
            cornerRadius: 16,
            tint: isRefreshing ? accentTint.opacity(0.14) : Color.white.opacity(0.08)
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func displayTemperature(_ celsius: Int) -> String {
        temperatureUnit.temperatureString(fromCelsius: celsius).replacingOccurrences(of: "°", with: "")
    }

    private var accentTint: Color {
        switch snapshot.current.condition {
        case .clear:
            WeatherGlassPalette.warm
        case .rain, .storm:
            WeatherGlassPalette.slate
        default:
            WeatherGlassPalette.cool
        }
    }

    private func compactReadingColumn(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentTransition(.interpolate)
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
        .frame(maxWidth: .infinity, minHeight: 52)
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .weatherGlassLens(cornerRadius: 20, tint: WeatherGlassPalette.cool.opacity(0.12))
        .contentTransition(.interpolate)
    }
}
